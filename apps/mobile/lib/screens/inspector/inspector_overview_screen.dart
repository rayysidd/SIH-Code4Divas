import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../services/api_service.dart';

/// Inspector's personal Overview screen.
/// Scoped to the logged-in inspector (mine=true).
class InspectorOverviewScreen extends StatefulWidget {
  const InspectorOverviewScreen({super.key});

  @override
  State<InspectorOverviewScreen> createState() => _InspectorOverviewScreenState();
}

class _InspectorOverviewScreenState extends State<InspectorOverviewScreen> {
  bool _isLoading = true;
  String? _error;

  int _totalScans = 0;
  double _passRate = 0.0;
  int _openViolations = 0;
  double _avgScanTime = 0.0;

  List<dynamic> _topViolations = [];
  List<dynamic> _trendData = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final overview = await ApiService.getAnalyticsOverview(mine: true);
      _totalScans = overview['total_scans'] ?? 0;
      _passRate = (overview['pass_rate'] as num?)?.toDouble() ?? 0.0;
      _openViolations = overview['open_violations'] ?? 0;
      _avgScanTime = (overview['avg_scan_time_seconds'] as num?)?.toDouble() ?? 0.0;

      try {
        _topViolations = await ApiService.getTopViolations(mine: true);
      } catch (_) {
        _topViolations = [];
      }

      try {
        final trendResp = await ApiService.getComplianceTrend(mine: true);
        _trendData = trendResp['data'] ?? [];
      } catch (_) {
        _trendData = [];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LabelLensColors.surface1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Inspection Overview', 
          style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: LabelLensColors.textPrimary),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: LabelLensColors.brandPrimary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: LabelLensColors.statusFail),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: LabelLensColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView(
                    padding: const EdgeInsets.all(LabelLensSpacing.s4),
                    children: [
                      // Subtitle badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: LabelLensColors.brandPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, size: 16, color: LabelLensColors.brandPrimary),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text('Scoped to your inspection activity', 
                                style: TextStyle(color: LabelLensColors.brandPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // KPI Grid
                      Row(
                        children: [
                          Expanded(
                            child: _KpiCard(
                              title: 'Total Scans',
                              value: '$_totalScans',
                              icon: Icons.qr_code_scanner,
                              color: LabelLensColors.brandPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _KpiCard(
                              title: 'Pass Rate',
                              value: '${_passRate.toStringAsFixed(1)}%',
                              icon: Icons.check_circle_outline,
                              color: LabelLensColors.statusPass,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _KpiCard(
                              title: 'Violations Found',
                              value: '$_openViolations',
                              icon: Icons.warning_amber,
                              color: LabelLensColors.statusFail,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _KpiCard(
                              title: 'Avg Speed',
                              value: '${_avgScanTime.toStringAsFixed(1)}s',
                              icon: Icons.timer_outlined,
                              color: LabelLensColors.brandSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Top Violations
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.report_problem_outlined, color: LabelLensColors.statusFail, size: 20),
                                  SizedBox(width: 8),
                                  Text('Top Violations Detected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_topViolations.isEmpty)
                                const Text('No violations recorded yet.', style: TextStyle(color: LabelLensColors.textSecondary))
                              else
                                ..._topViolations.map((v) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          v['rule'] ?? v['rule_cited'] ?? 'Unknown Rule',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: LabelLensColors.statusFail.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${v['count']} cases',
                                          style: const TextStyle(color: LabelLensColors.statusFail, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recent 30-Day Trend
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.timeline, color: LabelLensColors.brandSecondary, size: 20),
                                  SizedBox(width: 8),
                                  Text('Compliance Trend (30 Days)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_trendData.isEmpty)
                                const Text('No trend points available.', style: TextStyle(color: LabelLensColors.textSecondary))
                              else
                                ..._trendData.take(5).map((pt) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(pt['date'] ?? '', style: const TextStyle(color: LabelLensColors.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${pt['rate']}% Pass', 
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: (pt['rate'] as num) >= 80 ? LabelLensColors.statusPass : LabelLensColors.statusWarn,
                                        )),
                                    ],
                                  ),
                                )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LabelLensColors.surface3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title, 
                  style: const TextStyle(fontSize: 12, color: LabelLensColors.textSecondary, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: LabelLensColors.textPrimary), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
