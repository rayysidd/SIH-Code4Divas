import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../services/api_service.dart';

/// E-Commerce Lead's Overview screen.
/// Aggregates metrics from BatchListingResult scoped to the logged-in user.
class EcomOverviewScreen extends StatefulWidget {
  const EcomOverviewScreen({super.key});

  @override
  State<EcomOverviewScreen> createState() => _EcomOverviewScreenState();
}

class _EcomOverviewScreenState extends State<EcomOverviewScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _overview;

  @override
  void initState() {
    super.initState();
    _fetchOverview();
  }

  Future<void> _fetchOverview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getEcomOverview();
      setState(() {
        _overview = res;
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
    final totalChecked = _overview?['total_listings_checked'] ?? 0;
    final passRate = (_overview?['pass_rate'] as num?)?.toDouble() ?? 0.0;
    final recentFailures = (_overview?['recent_failures'] as List?) ?? [];

    return Scaffold(
      backgroundColor: LabelLensColors.surface1,
      appBar: AppBar(
        title: const Text('E-Commerce Compliance Hub', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOverview,
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
                        ElevatedButton(onPressed: _fetchOverview, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOverview,
                  child: ListView(
                    padding: const EdgeInsets.all(LabelLensSpacing.s4),
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(LabelLensSpacing.s4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Platform Lead Portal', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            const Text('Marketplace Audit Overview', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Checked', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text('$totalChecked', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Pass Rate', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text('${passRate.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: LabelLensSpacing.s4),

                      // Quick Action: Check Listing
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFCCFBF1),
                            child: Icon(Icons.link, color: Color(0xFF0F766E)),
                          ),
                          title: const Text('Check Single Listing URL', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Instantly test any product listing against LMPC Rule 6(10)'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => context.go('/ecommerce'),
                        ),
                      ),
                      const SizedBox(height: LabelLensSpacing.s4),

                      // Recent Failures Section
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber, color: LabelLensColors.statusFail, size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('Recent Non-Compliant Listings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: LabelLensColors.statusFail.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${recentFailures.length}',
                                      style: const TextStyle(color: LabelLensColors.statusFail, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (recentFailures.isEmpty)
                                const Text('No recent listing failures found.', style: TextStyle(color: LabelLensColors.textSecondary))
                              else
                                ...recentFailures.map((item) {
                                  final url = item['listing_url'] ?? '';
                                  final missing = (item['missing_fields'] as List?) ?? [];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: LabelLensColors.surface0,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: LabelLensColors.surface3),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          url,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: LabelLensColors.textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: missing.map((f) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: LabelLensColors.statusFail.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Missing: $f',
                                              style: const TextStyle(fontSize: 11, color: LabelLensColors.statusFail, fontWeight: FontWeight.w500),
                                            ),
                                          )).toList(),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
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
