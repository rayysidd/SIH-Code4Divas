import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import 'package:design_system/components/verdict_badge.dart';
import '../../services/api_service.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _scans = [];

  @override
  void initState() {
    super.initState();
    _fetchScans();
  }

  Future<void> _fetchScans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getScans();
      setState(() {
        _scans = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  VerdictType _parseVerdict(String v) {
    switch(v.toUpperCase()) {
      case 'PASS': return VerdictType.pass;
      case 'FAIL': return VerdictType.fail;
      case 'NEEDS_VERIFICATION':
      case 'INCONCLUSIVE':
        return VerdictType.warn;
      default: return VerdictType.pass;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LabelLensColors.surface1,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.7),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text('Scan History', style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50, right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 300, height: 300, decoration: BoxDecoration(color: LabelLensColors.brandSecondary.withOpacity(0.3), shape: BoxShape.circle)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Filter bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4, vertical: LabelLensSpacing.s2),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterTab(label: 'All', active: true),
                        _FilterTab(label: 'FAIL', active: false),
                        _FilterTab(label: 'PASS', active: false),
                        _FilterTab(label: 'Today', active: false),
                        _FilterTab(label: 'Flagged', active: false),
                      ],
                    ),
                  ),
                ),
                
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: LabelLensColors.statusFail),
                                  const SizedBox(height: 12),
                                  Text(_error!, style: const TextStyle(color: LabelLensColors.statusFail)),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _fetchScans,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _scans.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.inbox_outlined, size: 48, color: LabelLensColors.textTertiary),
                                      SizedBox(height: 12),
                                      Text('No scans yet', style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 16, fontWeight: FontWeight.w600)),
                                      SizedBox(height: 4),
                                      Text('Your completed label audits will appear here.', style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 13)),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchScans,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4, vertical: 8),
                                    itemCount: _scans.length,
                                    itemBuilder: (context, index) {
                                      final s = _scans[index];
                                      final scanId = s['scan_id']?.toString() ?? 'Unknown';
                                      final verdictStr = s['overall_verdict']?.toString() ?? 'PROCESSING';
                                      final confidence = (s['overall_confidence'] as num?)?.toDouble() ?? 0.0;
                                      final createdAt = s['created_at']?.toString() ?? '';
                                      final ruleVersion = s['rule_version']?.toString() ?? '2024.01';

                                      return _ScanHistoryCard(
                                        name: scanId.length > 8 ? '${scanId.substring(0, 8)}...' : scanId,
                                        verdict: _parseVerdict(verdictStr),
                                        time: createdAt.isNotEmpty ? DateTime.tryParse(createdAt)?.toLocal().toString().split('.')[0] ?? '—' : '—',
                                        location: 'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                                        checks: 'Rules v$ruleVersion',
                                        scanId: scanId,
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool active;
  const _FilterTab({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? LabelLensColors.brandPrimary : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? Colors.transparent : Colors.white.withOpacity(0.5)),
      ),
      child: Text(
        label, 
        style: TextStyle(
          fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.w600,
          color: active ? Colors.white : LabelLensColors.textSecondary
        ),
      ),
    );
  }
}

class _ScanHistoryCard extends StatelessWidget {
  final String name;
  final VerdictType verdict;
  final String time;
  final String location;
  final String checks;
  final String scanId;
  const _ScanHistoryCard({required this.name, required this.verdict, required this.time, required this.location, required this.checks, required this.scanId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/scan/$scanId'),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56, 
                  decoration: BoxDecoration(
                    color: LabelLensColors.brandPrimary.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: LabelLensColors.brandPrimary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace'))),
                          VerdictBadge(verdict: verdict, size: BadgeSize.sm),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 14, color: LabelLensColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(time, style: const TextStyle(fontSize: 12, color: LabelLensColors.textSecondary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: LabelLensColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(location, style: const TextStyle(fontSize: 12, color: LabelLensColors.textSecondary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(checks, style: const TextStyle(fontSize: 12, color: LabelLensColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
