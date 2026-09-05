import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import 'package:design_system/components/verdict_badge.dart';
import 'package:design_system/components/compliance_score_ring.dart';
import 'package:design_system/components/check_row.dart';
import '../../providers/scan_provider.dart';
import '../../services/api_service.dart';

class VerdictScreen extends ConsumerStatefulWidget {
  const VerdictScreen({super.key});

  @override
  ConsumerState<VerdictScreen> createState() => _VerdictScreenState();
}

class _VerdictScreenState extends ConsumerState<VerdictScreen> {
  String _activeFilter = 'All';

  Future<void> _exportPdf(String scanId) async {
    try {
      final file = await ApiService.downloadPdfReport(scanId);

      await Share.shareXFiles([XFile(file.path)], text: 'LabelLens Scan Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export report: $e')),
        );
      }
    }
  }

  void _scanAgain() {
    ref.read(scanProvider.notifier).reset();
    context.go('/camera');
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final result = scanState.result;

    if (result == null) {
      return Scaffold(
        backgroundColor: LabelLensColors.surface1,
        appBar: AppBar(
          backgroundColor: LabelLensColors.surface0,
          title: const Text('Scan Result'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description, size: 64, color: Colors.black26),
              const SizedBox(height: 16),
              const Text('No scan result available.\nPlease scan a label first.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _scanAgain,
                child: const Text('Scan Now'),
              ),
            ],
          ),
        ),
      );
    }

    final scanId = result['scan_id']?.toString() ?? '';
    final overallVerdictStr = result['overall_verdict']?.toString() ?? 'INCONCLUSIVE';

    if (overallVerdictStr == 'NOT_A_LABEL') {
      final ocrPreview = result['ocr_preview']?.toString();
      return Scaffold(
        backgroundColor: LabelLensColors.surface1,
        appBar: AppBar(
          backgroundColor: LabelLensColors.surface0,
          title: const Text('Scan Result'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
               ref.read(scanProvider.notifier).reset();
               context.go('/');
            },
          ),
        ),
        body: Center(
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
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LabelLensColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  onPressed: _scanAgain,
                  child: const Text('Scan Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final overallVerdict = overallVerdictStr == 'FAIL' ? VerdictType.fail : 
                           (overallVerdictStr == 'PASS' ? VerdictType.pass : 
                           (overallVerdictStr == 'NEEDS_VERIFICATION' ? VerdictType.inconclusive : VerdictType.warn));
    
    final overallConfidence = (result['overall_confidence'] as num?)?.toDouble() ?? 0.0;
    final complianceScore = (overallConfidence * 100).round();
    
    final violations = (result['violations'] as List?) ?? [];
    final checksList = (result['checks'] as List?) ?? [];

    final totalChecks = (result['total_checks_run'] as num?)?.toInt() ?? (checksList.isNotEmpty ? checksList.length : violations.length);
    final passedChecks = (result['checks_passed'] as num?)?.toInt() ?? checksList.where((c) => c['result'] == 'PASS').length;

    // Filter checks: build from real checks list if available, otherwise from violations
    final List<Map<String, dynamic>> allChecks = [];
    
    if (checksList.isNotEmpty) {
      for (var c in checksList) {
        final isCheckPass = c['result'] == 'PASS';
        if (isCheckPass) {
          allChecks.add({
            'verdict': VerdictType.pass,
            'ruleCitation': c['rule_cited']?.toString() ?? '',
            'shortDescription': c['description']?.toString() ?? 'Declaration verified and compliant',
            'foundValue': null,
            'requiredValue': null,
            'confidence': ((c['confidence'] as num?)?.toDouble() ?? 1.0) > 1 
                ? (c['confidence'] as num).toInt() 
                : (((c['confidence'] as num?)?.toDouble() ?? 1.0) * 100).round(),
          });
        } else {
          // Find matching violation for details if present
          final matchingVio = violations.firstWhere(
            (v) => v['rule_cited'] == c['rule_cited'],
            orElse: () => null,
          );
          final severity = matchingVio?['severity']?.toString() ?? 'HIGH';
          allChecks.add({
            'verdict': severity == 'CRITICAL' || severity == 'HIGH' ? VerdictType.fail : 
                       (severity == 'INCONCLUSIVE' ? VerdictType.inconclusive : VerdictType.warn),
            'ruleCitation': c['rule_cited']?.toString() ?? matchingVio?['rule_cited']?.toString() ?? '',
            'shortDescription': c['description']?.toString() ?? matchingVio?['description']?.toString() ?? '',
            'foundValue': matchingVio?['measured_value']?.toString() ?? '',
            'requiredValue': matchingVio?['required_value']?.toString() ?? '',
            'confidence': matchingVio?['confidence'] ?? (((c['confidence'] as num?)?.toDouble() ?? 0.9) * 100).round(),
          });
        }
      }
    } else {
      for (var v in violations) {
        final severity = v['severity']?.toString() ?? 'WARN';
        allChecks.add({
          'verdict': severity == 'CRITICAL' || severity == 'HIGH' ? VerdictType.fail : 
                     (severity == 'INCONCLUSIVE' ? VerdictType.inconclusive : VerdictType.warn),
          'ruleCitation': v['rule_cited']?.toString() ?? '',
          'shortDescription': v['description']?.toString() ?? '',
          'foundValue': v['measured_value']?.toString() ?? '',
          'requiredValue': v['required_value']?.toString() ?? '',
          'confidence': v['confidence'] ?? 0,
        });
      }
    }

    final filteredChecks = allChecks.where((c) {
      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'FAIL') return c['verdict'] == VerdictType.fail;
      if (_activeFilter == 'WARN') return c['verdict'] == VerdictType.warn;
      if (_activeFilter == 'PASS') return c['verdict'] == VerdictType.pass;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: LabelLensColors.surface1,
      appBar: AppBar(
        backgroundColor: LabelLensColors.surface0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             ref.read(scanProvider.notifier).reset();
             context.go('/');
          },
        ),
        title: const Text('Scan Result'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LabelLensSpacing.s4),
        child: Column(
          children: [
            // Hero Verdict Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(LabelLensSpacing.s6),
              decoration: BoxDecoration(
                color: LabelLensColors.surface0,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 3)],
              ),
              child: Column(
                children: [
                  VerdictBadge(verdict: overallVerdict, size: BadgeSize.lg),
                  const SizedBox(height: LabelLensSpacing.s4),
                  ComplianceScoreRing(
                    score: complianceScore,
                    passedChecks: passedChecks,
                    totalChecks: totalChecks,
                    size: RingSize.md,
                  ),
                ],
              ),
            ),
            const SizedBox(height: LabelLensSpacing.s4),

            // Filter Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4, vertical: LabelLensSpacing.s2),
              decoration: BoxDecoration(
                color: LabelLensColors.surface0,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All (${allChecks.length})', 
                      active: _activeFilter == 'All',
                      onTap: () => setState(() => _activeFilter = 'All'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'FAIL (${allChecks.where((c) => c['verdict'] == VerdictType.fail).length})', 
                      active: _activeFilter == 'FAIL',
                      onTap: () => setState(() => _activeFilter = 'FAIL'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'WARN (${allChecks.where((c) => c['verdict'] == VerdictType.warn).length})', 
                      active: _activeFilter == 'WARN',
                      onTap: () => setState(() => _activeFilter = 'WARN'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'PASS (${allChecks.where((c) => c['verdict'] == VerdictType.pass).length})', 
                      active: _activeFilter == 'PASS',
                      onTap: () => setState(() => _activeFilter = 'PASS'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: LabelLensSpacing.s4),

            // Check Rows
            ...filteredChecks.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: CheckRow(
                verdict: c['verdict'],
                ruleCitation: c['ruleCitation'],
                shortDescription: c['shortDescription'],
                foundValue: c['foundValue'] != '' ? c['foundValue'] : null,
                requiredValue: c['requiredValue'] != '' ? c['requiredValue'] : null,
                confidence: (c['confidence'] as num).toInt(),
              ),
            )),

            const SizedBox(height: LabelLensSpacing.s6),
          ],
        ),
      ),

      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(LabelLensSpacing.s4),
        decoration: BoxDecoration(
          color: LabelLensColors.surface0,
          border: Border(top: BorderSide(color: LabelLensColors.surface3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(icon: Icons.camera_alt, label: 'Scan Again', onTap: _scanAgain),
            _ActionButton(icon: Icons.share, label: 'Export PDF', onTap: () => _exportPdf(scanId)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? LabelLensColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : LabelLensColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: LabelLensColors.brandSecondary, size: 22),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: LabelLensColors.textSecondary)),
        ],
      ),
    );
  }
}
