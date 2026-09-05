import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../services/api_service.dart';

class BatchAuditScreen extends StatefulWidget {
  const BatchAuditScreen({super.key});

  @override
  State<BatchAuditScreen> createState() => _BatchAuditScreenState();
}

class _BatchAuditScreenState extends State<BatchAuditScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _batches = [];

  @override
  void initState() {
    super.initState();
    _fetchBatches();
  }

  Future<void> _fetchBatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getBatchListings();
      setState(() {
        _batches = data;
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
        title: const Text('Batch Audit', style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: 50, right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 300, height: 300, decoration: BoxDecoration(color: LabelLensColors.brandPrimary.withOpacity(0.2), shape: BoxShape.circle)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Upload New Batch Button
                Padding(
                  padding: const EdgeInsets.all(LabelLensSpacing.s4),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LabelLensColors.brandPrimary.withOpacity(0.3)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: LabelLensColors.brandPrimary.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.cloud_upload, color: LabelLensColors.brandPrimary, size: 32),
                              ),
                              const SizedBox(height: 12),
                              const Text('Upload CSV for Batch Processing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              const Text('Format: url, category, brand', style: TextStyle(color: LabelLensColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('RECENT BATCHES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: LabelLensColors.textTertiary, letterSpacing: 1.2)),
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
                                    onPressed: _fetchBatches,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _batches.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.inbox_outlined, size: 48, color: LabelLensColors.textTertiary),
                                      SizedBox(height: 12),
                                      Text('No batch jobs yet', style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 16, fontWeight: FontWeight.w600)),
                                      SizedBox(height: 4),
                                      Text('Submit your first batch to see results here.', style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 13)),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchBatches,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4),
                                    itemCount: _batches.length,
                                    itemBuilder: (context, index) {
                                      final b = _batches[index];
                                      final isProcessing = b['status'] == 'PROCESSING';
                                      final total = b['total'] ?? b['total_urls'] ?? 0;
                                      final pass = b['pass_count'] ?? b['pass'] ?? 0;
                                      final fail = b['fail_count'] ?? b['fail'] ?? 0;
                                      final processed = b['processed'] ?? (pass + fail);
                                      final batchId = b['batch_id'] ?? b['id'] ?? 'Unknown';
                                      
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
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      batchId.toString(),
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isProcessing ? LabelLensColors.brandSecondary.withOpacity(0.2) : LabelLensColors.statusPass.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      (b['status'] ?? 'UNKNOWN').toString(),
                                                      style: TextStyle(
                                                        color: isProcessing ? LabelLensColors.brandSecondary : LabelLensColors.statusPass,
                                                        fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              if (isProcessing) ...[
                                                LinearProgressIndicator(
                                                  value: total > 0 ? processed / total : 0,
                                                  backgroundColor: LabelLensColors.surface2,
                                                  valueColor: const AlwaysStoppedAnimation<Color>(LabelLensColors.brandPrimary),
                                                ),
                                                const SizedBox(height: 8),
                                                Text('$processed / $total processed', style: const TextStyle(fontSize: 12, color: LabelLensColors.textSecondary)),
                                              ] else ...[
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                  children: [
                                                    _Stat(label: 'Total', value: total.toString(), icon: Icons.link),
                                                    _Stat(label: 'Pass', value: pass.toString(), icon: Icons.check_circle, color: LabelLensColors.statusPass),
                                                    _Stat(label: 'Fail', value: fail.toString(), icon: Icons.cancel, color: LabelLensColors.statusFail),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 16),
                                              Container(height: 1, color: LabelLensColors.surface3.withOpacity(0.5)),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  const Icon(Icons.access_time, size: 14, color: LabelLensColors.textTertiary),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      b['created_at'] != null ? DateTime.tryParse(b['created_at'])?.toLocal().toString().split('.')[0] ?? '—' : '—',
                                                      style: const TextStyle(fontSize: 12, color: LabelLensColors.textTertiary),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
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

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _Stat({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? LabelLensColors.textSecondary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? LabelLensColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: LabelLensColors.textSecondary)),
      ],
    );
  }
}
