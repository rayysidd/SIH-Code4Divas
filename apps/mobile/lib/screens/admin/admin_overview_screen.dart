import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../services/api_service.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getAdminOverview();
      setState(() {
        _data = res;
        _isLoading = false;
      });
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
        title: const Text('Admin Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOverview,
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
                        ElevatedButton(onPressed: _loadOverview, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOverview,
                  child: ListView(
                    padding: const EdgeInsets.all(LabelLensSpacing.s4),
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(LabelLensSpacing.s4),
                        decoration: BoxDecoration(
                          color: LabelLensColors.brandPrimary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('System Administration', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            const Text('Cross-District Operations', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _StatPill(
                                  label: 'Districts Monitored',
                                  value: '${(_data?['pass_rate_trend'] as List?)?.length ?? 0}',
                                ),
                                const SizedBox(width: 8),
                                _StatPill(
                                  label: 'Active Officers',
                                  value: '${(_data?['inspector_workload'] as List?)?.length ?? 0}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: LabelLensSpacing.s4),

                      // Pass Rate by District
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.trending_up, color: LabelLensColors.statusPass, size: 20),
                                  SizedBox(width: 8),
                                  Text('Pass Rate by District', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if ((_data?['pass_rate_trend'] as List?)?.isEmpty ?? true)
                                const Text('No district compliance data available yet.', style: TextStyle(color: LabelLensColors.textSecondary))
                              else
                                ...((_data!['pass_rate_trend'] as List).map((item) {
                                  final history = (item['data'] as List?) ?? [];
                                  final latest = history.isNotEmpty ? history.last['rate'] : 0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(item['district'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('$latest%', style: const TextStyle(color: LabelLensColors.statusPass, fontWeight: FontWeight.bold, fontSize: 15)),
                                      ],
                                    ),
                                  );
                                })),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: LabelLensSpacing.s4),

                      // Inspector Workload
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.badge, color: LabelLensColors.brandPrimary, size: 20),
                                  SizedBox(width: 8),
                                  Text('Inspector Workload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if ((_data?['inspector_workload'] as List?)?.isEmpty ?? true)
                                const Text('No inspector scan data logged yet.', style: TextStyle(color: LabelLensColors.textSecondary))
                              else
                                ...((_data!['inspector_workload'] as List).map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item['inspector'] ?? 'Officer', style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                              Text(item['district'] ?? 'District', style: const TextStyle(color: LabelLensColors.textTertiary, fontSize: 12), overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('${item['scans']} scans', style: const TextStyle(color: LabelLensColors.brandPrimary, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                })),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
