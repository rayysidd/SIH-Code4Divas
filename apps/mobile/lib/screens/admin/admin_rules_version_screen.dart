import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../services/api_service.dart';

class AdminRulesVersionScreen extends StatefulWidget {
  const AdminRulesVersionScreen({super.key});

  @override
  State<AdminRulesVersionScreen> createState() => _AdminRulesVersionScreenState();
}

class _AdminRulesVersionScreenState extends State<AdminRulesVersionScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchRulesVersion();
  }

  Future<void> _fetchRulesVersion() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getRulesVersion();
      setState(() {
        _data = data;
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
      appBar: AppBar(
        title: const Text('Rules Version'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: LabelLensColors.statusFail),
                      const SizedBox(height: 16),
                      Text('Failed to load rules version', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(onPressed: _fetchRulesVersion, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchRulesVersion,
                  child: ListView(
                    padding: const EdgeInsets.all(LabelLensSpacing.s4),
                    children: [
                      Card(
                        margin: const EdgeInsets.only(bottom: LabelLensSpacing.s4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current Active Version', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.description_outlined, color: LabelLensColors.brandPrimary),
                                  const SizedBox(width: 8),
                                  Text(_data!['version'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Effective Date: ${_data!['effective_date']}'),
                              const SizedBox(height: 8),
                              Text('Amendment Basis: ${_data!['amendment_basis']}'),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Scans by Rules Version', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              if ((_data!['scan_counts'] as List).isEmpty)
                                const Text('No scans processed yet.')
                              else
                                ...(_data!['scan_counts'] as List).map((countObj) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('v${countObj['version']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text('${countObj['count']} scans', style: const TextStyle(color: LabelLensColors.textSecondary)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Rules update roadmap note: Upload functionality disabled. Requires review workflow to be implemented.',
                        style: TextStyle(color: LabelLensColors.textTertiary, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                ),
    );
  }
}
