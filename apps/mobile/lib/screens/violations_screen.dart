import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';

class ViolationsScreen extends StatelessWidget {
  const ViolationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data matching web ViolationsPage
    final violations = [
      { 'product': 'Sunflower Oil 1L', 'rule': 'Rule 6(1)(e)', 'desc': 'MRP - "Inclusive of all taxes" missing', 'severity': 'CRITICAL', 'status': 'Open', 'date': '26 Aug 2026' },
      { 'product': 'Sunflower Oil 1L', 'rule': 'Rule 7(4)', 'desc': 'Numeral height 1.8mm < 2.5mm required', 'severity': 'HIGH', 'status': 'Open', 'date': '26 Aug 2026' },
      { 'product': 'Sunflower Oil 1L', 'rule': 'Rule 6(1)(h)', 'desc': 'Customer care details absent', 'severity': 'CRITICAL', 'status': 'Open', 'date': '26 Aug 2026' },
      { 'product': 'Soap Bar 100g', 'rule': 'Rule 6(11)', 'desc': 'Unit sale price not declared', 'severity': 'HIGH', 'status': 'In Review', 'date': '25 Aug 2026' },
    ];

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
        title: const Text('Violations', style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 100, left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 250, height: 250, decoration: BoxDecoration(color: LabelLensColors.statusFail.withOpacity(0.15), shape: BoxShape.circle)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Filter Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4, vertical: LabelLensSpacing.s2),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(label: 'All', isSelected: true),
                        _FilterChip(label: 'Critical', isSelected: false, color: LabelLensColors.statusFail),
                        _FilterChip(label: 'High', isSelected: false, color: LabelLensColors.statusWarn),
                        _FilterChip(label: 'Open', isSelected: false),
                      ],
                    ),
                  ),
                ),
                
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4, vertical: 8),
                    itemCount: violations.length,
                    itemBuilder: (context, index) {
                      final v = violations[index];
                      final isCritical = v['severity'] == 'CRITICAL';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isCritical ? LabelLensColors.statusFail.withOpacity(0.3) : Colors.white.withOpacity(0.5)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/scan/1'),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCritical ? LabelLensColors.statusFail : LabelLensColors.statusWarn,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          v['severity']!,
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: LabelLensColors.surface2,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          v['status']!,
                                          style: const TextStyle(color: LabelLensColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(v['date']!, style: const TextStyle(fontSize: 12, color: LabelLensColors.textTertiary)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(v['product']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LabelLensColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.gavel, size: 14, color: LabelLensColors.brandSecondary),
                                      const SizedBox(width: 4),
                                      Text(v['rule']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LabelLensColors.brandSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(v['desc']!, style: const TextStyle(color: LabelLensColors.textSecondary, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 80), // Padding for bottom nav
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;

  const _FilterChip({required this.label, required this.isSelected, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? (color ?? LabelLensColors.brandPrimary) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : LabelLensColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
