import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import 'package:design_system/components/verdict_badge.dart';
import '../providers/scan_provider.dart';

/// Screen M-04: Scan Tab — Home (Inspector Role) with glassmorphism
class ScanHomeScreen extends ConsumerStatefulWidget {
  const ScanHomeScreen({super.key});

  @override
  ConsumerState<ScanHomeScreen> createState() => _ScanHomeScreenState();
}

class _ScanHomeScreenState extends ConsumerState<ScanHomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (xFile == null) return;

    final imageFile = File(xFile.path);
    ref.read(scanProvider.notifier).setCapturedImage(imageFile);
    ref.read(scanProvider.notifier).uploadAndProcess(imageFile);
    if (mounted) context.go('/processing');
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
        title: const Text('LabelLens',
            style: TextStyle(fontWeight: FontWeight.w800, color: LabelLensColors.brandPrimary, letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: LabelLensColors.textPrimary), 
            onPressed: () => context.push('/settings')
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -50,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: LabelLensColors.brandPrimary.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: LabelLensColors.brandSecondary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(LabelLensSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Card
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Today's Scans: 14",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LabelLensColors.textPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const VerdictBadge(verdict: VerdictType.pass, size: BadgeSize.sm),
                            const SizedBox(width: 8),
                            const Text('11 Pass', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 24),
                            const VerdictBadge(verdict: VerdictType.fail, size: BadgeSize.sm),
                            const SizedBox(width: 8),
                            const Text('3 Fail', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: LabelLensColors.brandSecondary),
                            const SizedBox(width: 4),
                            Text('Sadar Bazaar, Delhi',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: LabelLensColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LabelLensSpacing.s6),

                  // Quick Scan Section
                  const Center(
                    child: Text('QUICK SCAN',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: LabelLensColors.textTertiary, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: LabelLensSpacing.s4),

                  // Camera Preview Placeholder
                  _GlassCard(
                    padding: EdgeInsets.zero,
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 64, color: LabelLensColors.textTertiary.withOpacity(0.3)),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (context, child) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: LabelLensColors.brandPrimary.withOpacity(0.1 + (_pulseCtrl.value * 0.1)),
                                    ),
                                    child: child,
                                  );
                                },
                                child: IconButton(
                                  iconSize: 48,
                                  icon: const Icon(Icons.document_scanner, color: LabelLensColors.brandPrimary),
                                  onPressed: () => context.go('/camera'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('Tap to scan label', style: TextStyle(fontWeight: FontWeight.w600, color: LabelLensColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: LabelLensSpacing.s6),

                  // OR Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _QuickAction(icon: Icons.photo_library, label: 'From Gallery', onTap: _pickFromGallery),
                      _QuickAction(icon: Icons.keyboard, label: 'Enter GTIN', onTap: () {}),
                      _QuickAction(icon: Icons.link, label: 'URL Check', onTap: () => context.go('/ecommerce')),
                    ],
                  ),
                  const SizedBox(height: LabelLensSpacing.s8),

                  // Recent Scans
                  const Text('RECENT ACTIVITY',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: LabelLensColors.textTertiary, letterSpacing: 1.5)),
                  const SizedBox(height: LabelLensSpacing.s4),
                  _RecentScanRow(name: 'Sunflower Oil', verdict: VerdictType.fail, time: '12m ago'),
                  _RecentScanRow(name: 'Wheat Biscuits', verdict: VerdictType.pass, time: '28m ago'),
                  _RecentScanRow(name: 'Soap Bar 100g', verdict: VerdictType.pass, time: '41m ago'),
                  const SizedBox(height: LabelLensSpacing.s4),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/history'),
                      style: TextButton.styleFrom(foregroundColor: LabelLensColors.brandPrimary),
                      child: const Text('View All History →', style: TextStyle(fontWeight: FontWeight.w700)),
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
  final EdgeInsets? padding;
  
  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(LabelLensSpacing.s5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: LabelLensColors.brandPrimary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, color: LabelLensColors.brandPrimary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LabelLensColors.textSecondary)),
        ],
      ),
    );
  }
}

class _RecentScanRow extends StatelessWidget {
  final String name;
  final VerdictType verdict;
  final String time;

  const _RecentScanRow({required this.name, required this.verdict, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
          VerdictBadge(verdict: verdict, size: BadgeSize.sm),
          const SizedBox(width: 12),
          Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: LabelLensColors.textTertiary)),
        ],
      ),
    );
  }
}
