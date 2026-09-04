import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import 'package:design_system/components/verdict_badge.dart';
import 'package:go_router/go_router.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data matching web ProductsPage
    final products = [
      {'name': 'Sunflower Oil 1L', 'brand': 'NatureDrop', 'gtin': '8901234567890', 'category': 'Food', 'verdict': VerdictType.fail, 'date': '26 Aug 2026'},
      {'name': 'Wheat Biscuits', 'brand': 'CrunchyBites', 'gtin': '8909876543210', 'category': 'Food', 'verdict': VerdictType.pass, 'date': '26 Aug 2026'},
      {'name': 'Soap Bar 100g', 'brand': 'CleanLife', 'gtin': '8901122334455', 'category': 'Cosmetics', 'verdict': VerdictType.pass, 'date': '25 Aug 2026'},
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
        title: const Text('Products', style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50, right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 250, height: 250, decoration: BoxDecoration(color: LabelLensColors.brandSecondary.withOpacity(0.3), shape: BoxShape.circle)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(LabelLensSpacing.s4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products by name or GTIN...',
                        hintStyle: const TextStyle(color: LabelLensColors.textTertiary, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: LabelLensColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4, vertical: 8),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
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
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(
                                          color: LabelLensColors.brandPrimary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.inventory_2, color: LabelLensColors.brandPrimary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LabelLensColors.textPrimary)),
                                            const SizedBox(height: 2),
                                            Text('${p['brand']} • ${p['category']}', style: const TextStyle(color: LabelLensColors.textSecondary, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      VerdictBadge(verdict: p['verdict'] as VerdictType, size: BadgeSize.sm),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(height: 1, color: LabelLensColors.surface3.withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.qr_code, size: 14, color: LabelLensColors.textTertiary),
                                          const SizedBox(width: 4),
                                          Text(p['gtin'] as String, style: const TextStyle(fontSize: 12, color: LabelLensColors.textSecondary, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 14, color: LabelLensColors.textTertiary),
                                          const SizedBox(width: 4),
                                          Text('Last scanned: ${p['date']}', style: const TextStyle(fontSize: 12, color: LabelLensColors.textTertiary)),
                                        ],
                                      ),
                                    ],
                                  ),
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
