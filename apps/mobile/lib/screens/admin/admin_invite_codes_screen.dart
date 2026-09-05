import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../services/api_service.dart';

class AdminInviteCodesScreen extends StatefulWidget {
  const AdminInviteCodesScreen({super.key});

  @override
  State<AdminInviteCodesScreen> createState() => _AdminInviteCodesScreenState();
}

class _AdminInviteCodesScreenState extends State<AdminInviteCodesScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _codes = [];

  @override
  void initState() {
    super.initState();
    _fetchCodes();
  }

  Future<void> _fetchCodes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final codes = await ApiService.getInviteCodes();
      setState(() {
        _codes = codes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _revokeCode(String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Code'),
        content: Text('Are you sure you want to revoke code $code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: LabelLensColors.statusFail),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.revokeInviteCode(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code revoked successfully')),
        );
        _fetchCodes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: LabelLensColors.statusFail),
        );
      }
    }
  }

  Future<void> _showGenerateDialog() async {
    String role = 'INSPECTOR';
    String district = '';
    bool isGenerating = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Generate Code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'INSPECTOR', child: Text('Inspector')),
                      DropdownMenuItem(value: 'QA_MANAGER', child: Text('QA Manager')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                    ],
                    onChanged: (v) => setStateDialog(() => role = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'District (Optional)', border: OutlineInputBorder()),
                    onChanged: (v) => district = v,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isGenerating ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isGenerating ? null : () async {
                    setStateDialog(() => isGenerating = true);
                    try {
                      final result = await ApiService.createInviteCode(role, district);
                      if (context.mounted) {
                        Navigator.pop(context);
                        _showCodeGeneratedDialog(result['invite_code']);
                        _fetchCodes();
                      }
                    } catch (e) {
                      setStateDialog(() => isGenerating = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: LabelLensColors.statusFail),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: LabelLensColors.brandPrimary),
                  child: isGenerating 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Generate', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      }
    );
  }

  void _showCodeGeneratedDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code Generated'),
        content: SelectableText(
          code, 
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LabelLensColors.surface0,
      appBar: AppBar(
        title: const Text('Manage Invites', style: TextStyle(color: LabelLensColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: LabelLensColors.textPrimary),
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
                      Text('Failed to load codes', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(onPressed: _fetchCodes, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchCodes,
                  child: _codes.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Icon(Icons.group_outlined, size: 64, color: LabelLensColors.textTertiary)),
                            SizedBox(height: 16),
                            Center(child: Text('No invite codes found.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: LabelLensSpacing.s4, right: LabelLensSpacing.s4, top: LabelLensSpacing.s4, bottom: 96),
                          itemCount: _codes.length,
                          itemBuilder: (context, index) {
                            final code = _codes[index];
                            final isExpired = DateTime.parse(code['expires_at']).isBefore(DateTime.now());
                            final statusLabel = code['used'] ? 'Used' : isExpired ? 'Expired' : 'Active';
                            final statusColor = code['used'] 
                                ? LabelLensColors.textTertiary 
                                : isExpired ? LabelLensColors.statusFail : LabelLensColors.statusPass;

                            return Card(
                              margin: const EdgeInsets.only(bottom: LabelLensSpacing.s3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        code['code'], 
                                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Role: ${code['role']}'),
                                      if (code['district'] != null) Text('District: ${code['district']}'),
                                      Text('Issued by: ${code['issued_by']}'),
                                      Text('Issued at: ${DateTime.parse(code['issued_at']).toLocal().toString().split('.')[0]}'),
                                      if (code['used_by'] != null) Text('Used by: ${code['used_by']}'),
                                    ],
                                  ),
                                ),
                                trailing: !code['used']
                                    ? IconButton(
                                        icon: const Icon(Icons.delete_outline, color: LabelLensColors.statusFail),
                                        onPressed: () => _revokeCode(code['code']),
                                      )
                                    : null,
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: code['code']));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                                },
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGenerateDialog,
        backgroundColor: LabelLensColors.brandPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
