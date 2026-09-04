import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';

class EcommerceScreen extends StatefulWidget {
  const EcommerceScreen({super.key});

  @override
  State<EcommerceScreen> createState() => _EcommerceScreenState();
}

class _EcommerceScreenState extends State<EcommerceScreen> {
  final _urlController = TextEditingController();
  bool _showResult = false;

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
        title: const Text('E-Commerce Compliance Checker', style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 150, left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 250, height: 250, decoration: BoxDecoration(color: LabelLensColors.brandSecondary.withOpacity(0.2), shape: BoxShape.circle)),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(LabelLensSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STEP 1
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Step 1: Physical Label', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: LabelLensColors.surface3, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.upload_file, size: 32, color: LabelLensColors.brandPrimary),
                              const SizedBox(height: 12),
                              const Text('Tap to upload image', style: TextStyle(color: LabelLensColors.brandPrimary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: Text('OR', style: TextStyle(color: LabelLensColors.textTertiary, fontWeight: FontWeight.bold))),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: LabelLensColors.brandPrimary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Select from existing scans...', style: TextStyle(color: LabelLensColors.brandPrimary, fontWeight: FontWeight.w600)),
                              Icon(Icons.keyboard_arrow_down, color: LabelLensColors.brandPrimary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // STEP 2
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Step 2: E-Commerce Listing URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _urlController,
                                decoration: InputDecoration(
                                  hintText: 'https://www.amazon.in/dp/...',
                                  hintStyle: const TextStyle(color: LabelLensColors.textTertiary),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: LabelLensColors.surface3)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: LabelLensColors.surface3)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => setState(() => _showResult = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LabelLensColors.brandSecondary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              child: const Text('Check', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_showResult) ...[
                    const SizedBox(height: LabelLensSpacing.s6),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LabelLensColors.statusFail.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: LabelLensColors.statusFail.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: LabelLensColors.statusFail.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber, color: LabelLensColors.statusFail, size: 18),
                                const SizedBox(width: 8),
                                const Text('4 Declarations Missing', style: TextStyle(color: LabelLensColors.statusFail, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Rule 6(10), LMPC Rules 2011', style: TextStyle(fontSize: 12, color: LabelLensColors.textSecondary, fontWeight: FontWeight.w600)),
                          const Divider(height: 32),
                          _ComparisonRow(decl: 'MRP', physical: '₹89.00', listing: '₹89.00', match: true),
                          _ComparisonRow(decl: 'Net Qty', physical: '500ml', listing: '500ml', match: true),
                          _ComparisonRow(decl: 'Country', physical: 'India', listing: '—', match: false),
                          _ComparisonRow(decl: 'Mfr Address', physical: 'Full', listing: '—', match: false),
                          _ComparisonRow(decl: 'Consumer Care', physical: '1800-123', listing: '—', match: false),
                          _ComparisonRow(decl: 'MFG Date', physical: 'Jan 2026', listing: '—', match: false),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String decl;
  final String physical;
  final String listing;
  final bool match;
  
  const _ComparisonRow({required this.decl, required this.physical, required this.listing, required this.match});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110, 
            child: Text(decl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: LabelLensColors.textPrimary))
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Physical', style: TextStyle(fontSize: 10, color: LabelLensColors.textTertiary)),
                Text(physical, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            )
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Listing', style: TextStyle(fontSize: 10, color: LabelLensColors.textTertiary)),
                Text(listing, style: const TextStyle(fontSize: 13, color: LabelLensColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            )
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: match ? LabelLensColors.statusPass.withOpacity(0.1) : LabelLensColors.statusFail.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              match ? Icons.check : Icons.close, 
              size: 16,
              color: match ? LabelLensColors.statusPass : LabelLensColors.statusFail
            ),
          ),
        ],
      ),
    );
  }
}
