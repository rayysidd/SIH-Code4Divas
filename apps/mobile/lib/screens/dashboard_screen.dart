import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

/// Screen M-13: Dashboard (KPIs for QA/Inspectors) with updated aesthetics
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final role = authState.role ?? 'INSPECTOR';

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
        title: const Text('Overview', style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // Subtle background blobs for visual depth
          Positioned(
            top: -100,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  color: LabelLensColors.brandSecondary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: LabelLensColors.brandPrimary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(LabelLensSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Good morning, System.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: LabelLensColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('System-wide compliance overview', style: TextStyle(fontSize: 14, color: LabelLensColors.textSecondary)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _KpiCard(title: 'Total Scans', value: '247', trend: 'this month', isPositive: true)),
                      const SizedBox(width: LabelLensSpacing.s4),
                      Expanded(child: _KpiCard(title: 'Pass Rate', value: '78%', trend: '↑ 3%', isPositive: true)),
                    ],
                  ),
                  const SizedBox(height: LabelLensSpacing.s4),
                  Row(
                    children: [
                      Expanded(child: _KpiCard(title: 'Violations', value: '53', trend: 'Open', isPositive: false)),
                      const SizedBox(width: LabelLensSpacing.s4),
                      Expanded(child: _KpiCard(title: 'Avg Time', value: '4.2s', trend: '↓ 0.3s', isPositive: true)),
                    ],
                  ),
                  const SizedBox(height: LabelLensSpacing.s6),
                  
                  // Quick Actions (Only for Admin)
                  if (role == 'ADMIN') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/citizen-reports'),
                            icon: const Icon(Icons.groups, size: 18),
                            label: const Text('Citizen Reports'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: LabelLensColors.brandPrimary,
                              side: const BorderSide(color: LabelLensColors.surface3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/batch-audit'),
                            icon: const Icon(Icons.batch_prediction, size: 18),
                            label: const Text('Batch Audit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: LabelLensColors.brandPrimary,
                              side: const BorderSide(color: LabelLensColors.surface3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: LabelLensSpacing.s6),
                  ],

                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Top Violations', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: LabelLensSpacing.s4),
                        _RuleBar(rule: 'Rule 7(4)', desc: 'Font Size', pct: 0.8),
                        _RuleBar(rule: 'Rule 6(1)(e)', desc: 'MRP format', pct: 0.6),
                        _RuleBar(rule: 'Rule 6(1)(h)', desc: 'Consumer care', pct: 0.4),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Padding for the floating bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(LabelLensSpacing.s5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool isPositive;
  const _KpiCard({required this.title, required this.value, required this.trend, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LabelLensColors.textSecondary)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: LabelLensColors.textPrimary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isPositive ? LabelLensColors.statusPass : LabelLensColors.statusFail,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? LabelLensColors.statusPass : LabelLensColors.statusFail,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RuleBar extends StatelessWidget {
  final String rule;
  final String desc;
  final double pct;
  const _RuleBar({required this.rule, required this.desc, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rule, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LabelLensColors.textPrimary)),
              Text(desc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: LabelLensColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(color: LabelLensColors.surface2, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  color: LabelLensColors.brandPrimary,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: LabelLensColors.brandPrimary.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
