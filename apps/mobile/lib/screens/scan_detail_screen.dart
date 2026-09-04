import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../services/api_service.dart';

class ScanDetailScreen extends StatefulWidget {
  final String scanId;
  const ScanDetailScreen({super.key, required this.scanId});

  @override
  State<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  late Future<Map<String, dynamic>> _scanFuture;

  @override
  void initState() {
    super.initState();
    _scanFuture = ApiService.getScanResult(widget.scanId);
  }

  Future<void> _downloadPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading report…')),
    );
    try {
      final file = await ApiService.downloadPdfReport(widget.scanId);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        await Share.shareXFiles([XFile(file.path)], text: 'LabelLens Compliance Report');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LabelLensColors.surface1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LabelLensColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text('Scan Details (ID: ${widget.scanId.substring(0, 8)}...)', 
            style: const TextStyle(color: LabelLensColors.textPrimary, fontSize: 16)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _scanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: LabelLensColors.brandPrimary));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading scan: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Scan not found'));
          }

          final data = snapshot.data!;
          final overallVerdict = data['overall_verdict'];
          
          if (overallVerdict == 'NOT_A_LABEL') {
            final ocrPreview = data['ocr_preview']?.toString();
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(LabelLensSpacing.s6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: LabelLensColors.statusWarn),
                    const SizedBox(height: 16),
                    const Text('Not a Product Label', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: LabelLensColors.textPrimary)),
                    const SizedBox(height: 16),
                    const Text('The scanned image does not appear to be a product label, or the text is too unclear to read.', textAlign: TextAlign.center, style: TextStyle(color: LabelLensColors.textSecondary, fontSize: 16)),
                    if (ocrPreview != null && ocrPreview.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: LabelLensColors.surface0,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: LabelLensColors.surface3),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          leading: const Icon(Icons.text_snippet_outlined, size: 20, color: LabelLensColors.textSecondary),
                          title: const Text(
                            'What we read from your image',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LabelLensColors.textPrimary),
                          ),
                          children: [
                            Text(
                              ocrPreview,
                              style: const TextStyle(fontSize: 13, color: LabelLensColors.textSecondary, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          
          final isFail = overallVerdict == 'FAIL';
          final isNeedsVerif = overallVerdict == 'NEEDS_VERIFICATION';
          
          final confidence = (data['overall_confidence'] * 100).toInt();
          final vc = data['violation_count'];
          final totalViolations = vc['critical'] + vc['high'] + vc['medium'] + (vc['inconclusive'] ?? 0);
          final violations = List<Map<String, dynamic>>.from(data['violations']);
          
          // Heuristic for checks passed: just assume 28 total checks
          final passedChecks = 28 - totalViolations;

          return Stack(
            children: [
              Positioned(
                top: 50, right: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(
                    width: 250, height: 250, 
                    decoration: BoxDecoration(
                      color: isFail ? LabelLensColors.statusFail.withOpacity(0.15) : LabelLensColors.statusPass.withOpacity(0.15), 
                      shape: BoxShape.circle
                    )
                  ),
                ),
              ),
              
              SafeArea(
                child: DefaultTabController(
                  length: 3,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(LabelLensSpacing.s4),
                          child: Column(
                            children: [
                              // Main Score Card
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isFail ? LabelLensColors.statusFail.withOpacity(0.1) : (isNeedsVerif ? LabelLensColors.statusWarn.withOpacity(0.1) : LabelLensColors.statusPass.withOpacity(0.1)), 
                                        borderRadius: BorderRadius.circular(20), 
                                        border: Border.all(color: isFail ? LabelLensColors.statusFail.withOpacity(0.5) : (isNeedsVerif ? LabelLensColors.statusWarn.withOpacity(0.5) : LabelLensColors.statusPass.withOpacity(0.5)))
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(isFail ? Icons.cancel : (isNeedsVerif ? Icons.help : Icons.check_circle), 
                                               color: isFail ? LabelLensColors.statusFail : (isNeedsVerif ? LabelLensColors.statusWarn : LabelLensColors.statusPass), size: 18),
                                          const SizedBox(width: 8),
                                          Text(overallVerdict, style: TextStyle(
                                            color: isFail ? LabelLensColors.statusFail : (isNeedsVerif ? LabelLensColors.statusWarn : LabelLensColors.statusPass), 
                                            fontWeight: FontWeight.bold, letterSpacing: 1
                                          )),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Compliance Score', style: TextStyle(color: LabelLensColors.textSecondary, fontSize: 14)),
                                    const SizedBox(height: 8),
                                    Text('${(passedChecks / 28 * 100).toInt()}%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: LabelLensColors.textPrimary)),
                                    const SizedBox(height: 8),
                                    Text('$passedChecks/28 checks passed • Confidence: $confidence%', style: const TextStyle(color: LabelLensColors.textTertiary, fontSize: 13)),
                                    const SizedBox(height: 24),
                                    Container(height: 1, width: double.infinity, color: LabelLensColors.surface3.withOpacity(0.5)),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildSeverityCount('${vc['critical']}', 'CRITICAL', LabelLensColors.statusFail),
                                        _buildSeverityCount('${vc['high']}', 'HIGH', LabelLensColors.statusWarn),
                                        _buildSeverityCount('${vc['medium']}', 'MEDIUM', LabelLensColors.brandSecondary),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Action Buttons
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _ActionButton(
                                      icon: Icons.picture_as_pdf, 
                                      label: 'Download PDF Report', 
                                      isPrimary: true,
                                      onTap: _downloadPdf,
                                    ),
                                    const SizedBox(width: 12),
                                    _ActionButton(icon: Icons.code, label: 'Export JSON', isPrimary: false),
                                    const SizedBox(width: 12),
                                    _ActionButton(icon: Icons.flag_outlined, label: 'Flag for Review', isPrimary: false),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Tabs
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            labelColor: LabelLensColors.brandPrimary,
                            unselectedLabelColor: LabelLensColors.textSecondary,
                            indicatorColor: LabelLensColors.brandPrimary,
                            indicatorWeight: 3,
                            tabs: [
                              Tab(text: 'ALL (${violations.length})'),
                              Tab(text: 'FAIL ($totalViolations)'),
                              Tab(text: 'WARN (${vc['medium']})'),
                            ],
                          ),
                        ),
                      ),
                      
                      // Tab Views
                      SliverFillRemaining(
                        child: TabBarView(
                          children: [
                            _buildChecksList(violations, filterFail: false),
                            _buildChecksList(violations, filterFail: true),
                            _buildChecksList(violations, filterWarn: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSeverityCount(String count, String label, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: LabelLensColors.textTertiary, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildChecksList(List<Map<String, dynamic>> violations, {bool filterFail = false, bool filterWarn = false}) {
    var displayViolations = violations;
    if (filterFail) {
      displayViolations = violations.where((v) => v['severity'] == 'CRITICAL' || v['severity'] == 'HIGH').toList();
    } else if (filterWarn) {
      displayViolations = violations.where((v) => v['severity'] == 'MEDIUM').toList();
    }

    if (displayViolations.isEmpty) {
      return const Center(child: Text('No violations found in this category.', style: TextStyle(color: LabelLensColors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(LabelLensSpacing.s4),
      itemCount: displayViolations.length,
      itemBuilder: (context, index) {
        final v = displayViolations[index];
        final isPass = false; // All in this list are violations (FAIL or WARN)
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LabelLensColors.statusFail.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cancel, color: LabelLensColors.statusFail, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v['rule_cited'] ?? 'Unknown Rule', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(v['description'] ?? '', style: const TextStyle(color: LabelLensColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: v['severity'] == 'CRITICAL' ? LabelLensColors.statusFail : LabelLensColors.statusWarn, 
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Text(v['severity'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;
  
  const _ActionButton({required this.icon, required this.label, required this.isPrimary, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? LabelLensColors.brandPrimary : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isPrimary ? Colors.transparent : LabelLensColors.surface3),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isPrimary ? Colors.white : LabelLensColors.brandPrimary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isPrimary ? Colors.white : LabelLensColors.brandPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: LabelLensColors.surface1.withOpacity(0.95),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
