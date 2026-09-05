import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getScans();
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _verdictColor(String verdict) {
    switch (verdict.toUpperCase()) {
      case 'PASS': return LabelLensColors.statusPass;
      case 'FAIL': return LabelLensColors.statusFail;
      case 'NEEDS_VERIFICATION': return LabelLensColors.statusWarn;
      default: return LabelLensColors.textSecondary;
    }
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
                        hintText: 'Search scans by ID...',
                        hintStyle: const TextStyle(color: LabelLensColors.textTertiary, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: LabelLensColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: LabelLensColors.statusFail),
                                  const SizedBox(height: 12),
                                  Text(_error!, style: const TextStyle(color: LabelLensColors.statusFail)),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _fetchProducts,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _products.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.inventory_2_outlined, size: 48, color: LabelLensColors.textTertiary),
                                      SizedBox(height: 12),
                                      Text('No products scanned yet', style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 16, fontWeight: FontWeight.w600)),
                                      SizedBox(height: 4),
                                      Text('Start your first scan to see products here.', style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 13)),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchProducts,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4, vertical: 8),
                                    itemCount: _products.length,
                                    itemBuilder: (context, index) {
                                      final p = _products[index];
                                      final scanId = p['scan_id']?.toString() ?? '';
                                      final verdict = p['overall_verdict']?.toString() ?? 'PROCESSING';
                                      final confidence = (p['overall_confidence'] as num?)?.toDouble() ?? 0.0;
                                      final createdAt = p['created_at']?.toString() ?? '';
                                      final ruleVersion = p['rule_version']?.toString() ?? '2024.01';
                                      
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
                                            onTap: () => context.push('/scan/$scanId'),
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
                                                            Text(scanId.length > 12 ? '${scanId.substring(0, 12)}…' : scanId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: LabelLensColors.textPrimary, fontFamily: 'monospace')),
                                                            const SizedBox(height: 2),
                                                            Text('Rules v$ruleVersion • ${(confidence * 100).toStringAsFixed(0)}% confidence', style: const TextStyle(color: LabelLensColors.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: _verdictColor(verdict).withOpacity(0.15),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          verdict,
                                                          style: TextStyle(color: _verdictColor(verdict), fontSize: 10, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Container(height: 1, color: LabelLensColors.surface3.withOpacity(0.5)),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.calendar_today, size: 14, color: LabelLensColors.textTertiary),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          createdAt.isNotEmpty ? DateTime.tryParse(createdAt)?.toLocal().toString().split('.')[0] ?? '—' : '—',
                                                          style: const TextStyle(fontSize: 12, color: LabelLensColors.textTertiary),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
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
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
