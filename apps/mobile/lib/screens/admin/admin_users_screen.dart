import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await ApiService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(String userId, bool currentStatus) async {
    if (currentStatus) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Confirm Deactivation'),
          content: const Text('Are you sure you want to deactivate this account? They will lose access immediately.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              style: TextButton.styleFrom(foregroundColor: LabelLensColors.statusFail),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    
    try {
      await ApiService.patchUserStatus(userId, !currentStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(currentStatus ? 'User deactivated' : 'User reactivated')));
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: LabelLensColors.statusFail));
      }
    }
  }

  void _showEditRoleSheet(Map<String, dynamic> user) {
    String selectedRole = user['role'];
    final districtController = TextEditingController(text: user['district'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit Role: ${user['username']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                const Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: ['CITIZEN', 'INSPECTOR', 'QA_MANAGER', 'ECOM_LEAD', 'ADMIN'].map((role) {
                    return ChoiceChip(
                      label: Text(role),
                      selected: selectedRole == role,
                      onSelected: (bool selected) {
                        if (selected) {
                          setSheetState(() => selectedRole = role);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('District (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: districtController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. Mumbai North'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ApiService.patchUserRole(user['user_id'], selectedRole, districtController.text);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated successfully')));
                        _fetchUsers();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: LabelLensColors.statusFail));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: LabelLensColors.brandPrimary, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
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
                      Text('Failed to load users', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(onPressed: _fetchUsers, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: _users.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Icon(Icons.group_outlined, size: 64, color: LabelLensColors.textTertiary)),
                            SizedBox(height: 16),
                            Center(child: Text('No users found.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: LabelLensSpacing.s4, right: LabelLensSpacing.s4, top: LabelLensSpacing.s4, bottom: 96),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final isActive = user['is_active'] ?? true;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: LabelLensSpacing.s3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Opacity(
                                opacity: isActive ? 1.0 : 0.6,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    user['username'],
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isActive ? LabelLensColors.statusPass.withOpacity(0.2) : LabelLensColors.statusFail.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    isActive ? 'Active' : 'Inactive',
                                                    style: TextStyle(fontSize: 10, color: isActive ? LabelLensColors.statusPass : LabelLensColors.statusFail, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: LabelLensColors.brandPrimary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              user['role'],
                                              style: const TextStyle(fontSize: 12, color: LabelLensColors.brandPrimary, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Name: ${user['full_name']}'),
                                      if (user['district'] != null) Text('District: ${user['district']}'),
                                      const SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Wrap(
                                          alignment: WrapAlignment.end,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => _showEditRoleSheet(user),
                                              icon: const Icon(Icons.edit, size: 16),
                                              label: const Text('Edit Role'),
                                            ),
                                            TextButton.icon(
                                              onPressed: () => _toggleStatus(user['user_id'], isActive),
                                              icon: Icon(isActive ? Icons.block : Icons.check_circle_outline, size: 16),
                                              label: Text(isActive ? 'Deactivate' : 'Reactivate'),
                                              style: TextButton.styleFrom(foregroundColor: isActive ? LabelLensColors.statusFail : LabelLensColors.statusPass),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
