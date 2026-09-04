import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../services/api_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getAdminOverview();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('District Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: LabelLensColors.statusFail),
                      const SizedBox(height: 16),
                      Text('Failed to load analytics', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(onPressed: _fetchAnalytics, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAnalytics,
                  child: ListView(
                    padding: const EdgeInsets.all(LabelLensSpacing.s4),
                    children: [
                      // Pass Rate Trend (simplified list view for mobile since charts might need an extra dependency)
                      Card(
                        margin: const EdgeInsets.only(bottom: LabelLensSpacing.s4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pass Rate by District', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              if ((_data!['pass_rate_trend'] as List).isEmpty)
                                const Text('No data available.')
                              else
                                ...(_data!['pass_rate_trend'] as List).map((districtData) {
                                  final latestData = (districtData['data'] as List).isNotEmpty ? districtData['data'].last : null;
                                  final rate = latestData != null ? latestData['rate'] : 0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(districtData['district'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text('$rate%', style: const TextStyle(color: LabelLensColors.statusPass, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ),
                      
                      // Inspector Workload
                      Card(
                        margin: const EdgeInsets.only(bottom: LabelLensSpacing.s4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Inspector Workload', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              if ((_data!['inspector_workload'] as List).isEmpty)
                                const Text('No data available.')
                              else
                                ...(_data!['inspector_workload'] as List).map((workload) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${workload['inspector']} (${workload['district']})', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text('${workload['scans']} scans', style: const TextStyle(color: LabelLensColors.brandPrimary, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ),
                      
                      // Top Violations by District
                      Card(
                        margin: const EdgeInsets.only(bottom: LabelLensSpacing.s4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Top Violations by District', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              if ((_data!['top_violations_by_district'] as List).isEmpty)
                                const Text('No data available.')
                              else
                                ...(_data!['top_violations_by_district'] as List).map((districtData) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(districtData['district'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LabelLensColors.brandPrimary)),
                                        const SizedBox(height: 8),
                                        if ((districtData['violations'] as List).isEmpty)
                                          const Text('  No violations')
                                        else
                                          ...(districtData['violations'] as List).map((v) {
                                            return Padding(
                                              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(v['rule']),
                                                  Text('${v['count']} times'),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                      ],
                                    ),
                                  );
                                }).toList(),
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
