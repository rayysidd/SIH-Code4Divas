import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../services/api_service.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _logs = [];

  String _selectedAction = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final logs = await ApiService.getAuditLog(
        action: _selectedAction.isNotEmpty ? _selectedAction : null,
        dateSince: _selectedDate?.toUtc().toIso8601String(),
      );
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedAction,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('All Actions')),
                      DropdownMenuItem(value: 'LOGIN', child: Text('LOGIN')),
                      DropdownMenuItem(value: 'REGISTER', child: Text('REGISTER')),
                      DropdownMenuItem(value: 'USER_DEACTIVATED', child: Text('USER_DEACTIVATED')),
                      DropdownMenuItem(value: 'USER_REACTIVATED', child: Text('USER_REACTIVATED')),
                      DropdownMenuItem(value: 'ROLE_CHANGED', child: Text('ROLE_CHANGED')),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedAction = val!);
                      _fetchLogs();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_selectedDate != null ? '${_selectedDate!.day}/${_selectedDate!.month}' : 'Since'),
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ),
                if (_selectedAction.isNotEmpty || _selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: LabelLensColors.statusFail),
                    onPressed: () {
                      setState(() {
                        _selectedAction = '';
                        _selectedDate = null;
                      });
                      _fetchLogs();
                    },
                  )
              ],
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
                            const SizedBox(height: 16),
                            Text('Failed to load audit log', style: Theme.of(context).textTheme.titleLarge),
                            TextButton(onPressed: _fetchLogs, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchLogs,
                        child: _logs.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 100),
                                  Center(child: Icon(Icons.receipt_long_outlined, size: 64, color: LabelLensColors.textTertiary)),
                                  SizedBox(height: 16),
                                  Center(child: Text('No audit events match filters.')),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(LabelLensSpacing.s4),
                                itemCount: _logs.length,
                                itemBuilder: (context, index) {
                                  final log = _logs[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: LabelLensSpacing.s3),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      title: Row(
                                        children: [
                                          Expanded(child: Text(log['action'], style: const TextStyle(fontWeight: FontWeight.bold))),
                                          Text(
                                            DateTime.parse(log['timestamp']).toLocal().toString().split('.')[0],
                                            style: const TextStyle(fontSize: 12, color: LabelLensColors.textTertiary),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Actor: ${log['actor_username'] ?? log['actor_user_id'] ?? log['actor']}'),
                                            if (log['target'] != null) Text('Target: ${log['target']}'),
                                            if (log['details'] != null) Text('Details: ${log['details']}'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
