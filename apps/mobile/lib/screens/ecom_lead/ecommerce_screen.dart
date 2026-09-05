import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../services/api_service.dart';

class EcommerceScreen extends StatefulWidget {
  const EcommerceScreen({super.key});

  @override
  State<EcommerceScreen> createState() => _EcommerceScreenState();
}

class _EcommerceScreenState extends State<EcommerceScreen> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkListing() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product listing URL')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final res = await ApiService.checkListingUrl(url);
      setState(() {
        _result = res;
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
    final verdict = _result?['verdict']?.toString();
    final isPass = verdict == 'PASS';
    final missingFields = (_result?['missing_fields'] as List?)?.map((e) => e.toString()).toList() ?? [];

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
        title: const Text('E-Commerce Compliance Checker', 
          style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 150, left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 250, height: 250, 
                decoration: BoxDecoration(
                  color: LabelLensColors.brandSecondary.withOpacity(0.2), 
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
                  // Explanation Card
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
                        const Row(
                          children: [
                            Icon(Icons.rule_folder_outlined, color: LabelLensColors.brandPrimary),
                            SizedBox(width: 8),
                            Text('LMPC Rule 6(10) Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Verifies mandatory e-commerce declarations: MRP, Net Quantity, Country of Origin, Manufacturer / Packer address, Consumer Care contact.',
                          style: TextStyle(color: LabelLensColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // URL Input Card
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
                        const Text('Product Listing URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _urlController,
                                decoration: InputDecoration(
                                  hintText: 'https://www.amazon.in/dp/... or flipkart.com/...',
                                  hintStyle: const TextStyle(color: LabelLensColors.textTertiary, fontSize: 13),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LabelLensColors.surface3)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LabelLensColors.surface3)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _checkListing,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LabelLensColors.brandPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              ),
                              child: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Check', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: LabelLensColors.statusFail.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: LabelLensColors.statusFail.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: LabelLensColors.statusFail),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_error!, style: const TextStyle(color: LabelLensColors.statusFail, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPass 
                            ? LabelLensColors.statusPass.withOpacity(0.4) 
                            : LabelLensColors.statusFail.withOpacity(0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isPass ? LabelLensColors.statusPass : LabelLensColors.statusFail).withOpacity(0.1), 
                            blurRadius: 15, 
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isPass 
                                      ? LabelLensColors.statusPass.withOpacity(0.15) 
                                      : LabelLensColors.statusFail.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isPass ? Icons.check_circle : Icons.warning_amber, 
                                        color: isPass ? LabelLensColors.statusPass : LabelLensColors.statusFail, 
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isPass ? 'COMPLIANT' : '${missingFields.length} Mandatory Declarations Missing',
                                          style: TextStyle(
                                            color: isPass ? LabelLensColors.statusPass : LabelLensColors.statusFail, 
                                            fontWeight: FontWeight.bold, 
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Evaluated under Rule 6(10), Legal Metrology (Packaged Commodities) Rules', 
                            style: TextStyle(fontSize: 12, color: LabelLensColors.textSecondary, fontWeight: FontWeight.w500)),
                          const Divider(height: 28),

                          // Declarations checklist
                          _DeclarationStatusItem(
                            field: 'Maximum Retail Price (MRP)',
                            isMissing: missingFields.contains('MRP'),
                          ),
                          _DeclarationStatusItem(
                            field: 'Net Quantity / Unit Sale Price',
                            isMissing: missingFields.contains('NET_QUANTITY'),
                          ),
                          _DeclarationStatusItem(
                            field: 'Country of Origin',
                            isMissing: missingFields.contains('COUNTRY_OF_ORIGIN'),
                          ),
                          _DeclarationStatusItem(
                            field: 'Manufacturer / Importer / Packer Details',
                            isMissing: missingFields.contains('MANUFACTURER_PACKER'),
                          ),
                          _DeclarationStatusItem(
                            field: 'Consumer Care / Contact Information',
                            isMissing: missingFields.contains('CONSUMER_CARE'),
                          ),
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

class _DeclarationStatusItem extends StatelessWidget {
  final String field;
  final bool isMissing;

  const _DeclarationStatusItem({required this.field, required this.isMissing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isMissing ? LabelLensColors.statusFail.withOpacity(0.1) : LabelLensColors.statusPass.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMissing ? Icons.close : Icons.check,
              size: 16,
              color: isMissing ? LabelLensColors.statusFail : LabelLensColors.statusPass,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              field,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: isMissing ? LabelLensColors.statusFail : LabelLensColors.textPrimary,
              ),
            ),
          ),
          Text(
            isMissing ? 'Missing' : 'Present',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isMissing ? LabelLensColors.statusFail : LabelLensColors.statusPass,
            ),
          ),
        ],
      ),
    );
  }
}
