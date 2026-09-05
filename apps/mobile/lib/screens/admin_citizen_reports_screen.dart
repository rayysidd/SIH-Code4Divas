import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../services/api_service.dart';

class AdminCitizenReportsScreen extends StatefulWidget {
  const AdminCitizenReportsScreen({super.key});

  @override
  State<AdminCitizenReportsScreen> createState() => _AdminCitizenReportsScreenState();
}

class _AdminCitizenReportsScreenState extends State<AdminCitizenReportsScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getCitizenReports();
      setState(() {
        _reports = data;
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
        title: const Text('Citizen Reports', style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 100, right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 250, height: 250, decoration: BoxDecoration(color: LabelLensColors.statusWarn.withOpacity(0.15), shape: BoxShape.circle)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
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
                                    onPressed: _fetchReports,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _reports.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.inbox_outlined, size: 48, color: LabelLensColors.textTertiary),
                                      SizedBox(height: 12),
                                      Text('No citizen reports', style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 16, fontWeight: FontWeight.w600)),
                                      SizedBox(height: 4),
                                      Text('No violation reports have been submitted yet.', style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 13)),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchReports,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4, vertical: 8),
                                    itemCount: _reports.length,
                                    itemBuilder: (context, index) {
                                      final r = _reports[index];
                                      final status = r['status']?.toString() ?? 'UNKNOWN';
                                      final isNew = status == 'SUBMITTED' || status == 'NEW';
                                      final dateStr = r['submitted_at']?.toString();
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: isNew ? LabelLensColors.brandPrimary.withOpacity(0.3) : Colors.white.withOpacity(0.5)),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(r['tracking_id']?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: LabelLensColors.textSecondary, fontFamily: 'monospace')),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isNew ? LabelLensColors.statusFail.withOpacity(0.1) : LabelLensColors.surface2,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      status.replaceAll('_', ' '),
                                                      style: TextStyle(
                                                        color: isNew ? LabelLensColors.statusFail : LabelLensColors.textSecondary,
                                                        fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  const Icon(Icons.warning_amber, size: 20, color: LabelLensColors.brandSecondary),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(r['problem_type']?.toString() ?? 'Unknown Issue', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LabelLensColors.textPrimary)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(r['description']?.toString() ?? 'No description provided.', style: const TextStyle(color: LabelLensColors.textSecondary, fontSize: 14)),
                                              const SizedBox(height: 16),
                                              Container(height: 1, color: LabelLensColors.surface3.withOpacity(0.5)),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today, size: 14, color: LabelLensColors.textTertiary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    dateStr != null ? DateTime.tryParse(dateStr)?.toLocal().toString().split('.')[0] ?? dateStr : '—',
                                                    style: const TextStyle(fontSize: 12, color: LabelLensColors.textTertiary)
                                                  ),
                                                ],
                                              ),
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
