import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../services/api_service.dart';

class ViolationsScreen extends StatefulWidget {
  const ViolationsScreen({super.key});

  @override
  State<ViolationsScreen> createState() => _ViolationsScreenState();
}

class _ViolationsScreenState extends State<ViolationsScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _violations = [];

  @override
  void initState() {
    super.initState();
    _fetchViolations();
  }

  Future<void> _fetchViolations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getTopViolations();
      setState(() {
        _violations = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
                                    onPressed: _fetchViolations,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _violations.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.check_circle_outline, size: 48, color: LabelLensColors.textTertiary),
                                      SizedBox(height: 12),
                                      Text('No violations recorded', style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 16, fontWeight: FontWeight.w600)),
                                      SizedBox(height: 4),
                                      Text('All scanned products are currently compliant.', style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 13)),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchViolations,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4, vertical: 8),
                                    itemCount: _violations.length,
                                    itemBuilder: (context, index) {
                                      final v = _violations[index];
                                      final rule = v['rule']?.toString() ?? 'Unknown';
                                      final desc = v['description']?.toString() ?? '';
                                      final count = v['count'] ?? 0;
                                      final percentage = v['percentage'] ?? 0;
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withOpacity(0.5)),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                                        ),
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
                                                      color: LabelLensColors.statusFail,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '$count occurrences',
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
                                                      '$percentage%',
                                                      style: const TextStyle(color: LabelLensColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  const Icon(Icons.gavel, size: 14, color: LabelLensColors.brandSecondary),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(rule, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LabelLensColors.brandSecondary)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(desc, style: const TextStyle(color: LabelLensColors.textSecondary, fontSize: 14)),
                                            ],
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
