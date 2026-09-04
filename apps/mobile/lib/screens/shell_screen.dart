import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/tokens/colors.dart';
import '../providers/auth_provider.dart';

class TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  TabItem(this.label, this.icon, this.activeIcon, this.route);
}

/// App Shell containing the dynamic, role-based Glassmorphic Bottom Navigation Bar
class ShellScreen extends ConsumerWidget {
  final Widget child;
  final GoRouterState routerState;

  const ShellScreen({super.key, required this.child, required this.routerState});

  List<TabItem> _getTabsForRole(String role) {
    if (role == 'ADMIN') {
      return [
        TabItem('Overview', Icons.home_outlined, Icons.home, '/dashboard'),
        TabItem('Scan', Icons.document_scanner_outlined, Icons.document_scanner, '/'),
        TabItem('Menu', Icons.menu, Icons.menu_open, '#menu'),
      ];
    } else if (role == 'QA_MANAGER') {
      return [
        TabItem('Overview', Icons.home_outlined, Icons.home, '/dashboard'),
        TabItem('Products', Icons.inventory_2_outlined, Icons.inventory_2, '/products'),
        TabItem('Menu', Icons.menu, Icons.menu_open, '#menu'),
      ];
    } else {
      // Default to INSPECTOR
      return [
        TabItem('Overview', Icons.home_outlined, Icons.home, '/dashboard'),
        TabItem('Scan', Icons.document_scanner_outlined, Icons.document_scanner, '/'),
        TabItem('History', Icons.history_outlined, Icons.history, '/history'),
        TabItem('Menu', Icons.menu, Icons.menu_open, '#menu'),
      ];
    }
  }

  int _calculateSelectedIndex(BuildContext context, List<TabItem> tabs) {
    final String location = routerState.uri.toString();
    
    for (int i = 0; i < tabs.length; i++) {
      if (tabs[i].route == '#menu') continue;
      if (tabs[i].route == '/') {
        if (location == '/') return i;
      } else {
        if (location.startsWith(tabs[i].route)) return i;
      }
    }
    return 0; // Fallback
  }

  void _showMenu(BuildContext context, String role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: LabelLensColors.surface3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Menu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LabelLensColors.textPrimary)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      children: [
                        _MenuItem(icon: Icons.home_outlined, title: 'Overview', route: '/dashboard', currentPath: routerState.uri.toString()),
                        const SizedBox(height: 24),
                        
                        if (role == 'ADMIN') ...[
                          _MenuSection(title: 'ADMINISTRATION'),
                          _MenuItem(icon: Icons.people_outline, title: 'User Management', route: '/admin/users', currentPath: routerState.uri.toString()),
                          _MenuItem(icon: Icons.confirmation_number_outlined, title: 'Invite Codes', route: '/admin/invite-codes', currentPath: routerState.uri.toString()),
                          _MenuItem(icon: Icons.description_outlined, title: 'Rules Version', route: '/admin/rules-version', currentPath: routerState.uri.toString()),
                          _MenuItem(icon: Icons.receipt_long_outlined, title: 'Audit Log', route: '/admin/audit-log', currentPath: routerState.uri.toString()),
                          const SizedBox(height: 24),
                          _MenuSection(title: 'OVERSIGHT'),
                          _MenuItem(icon: Icons.bar_chart, title: 'District Analytics', route: '/admin/analytics', currentPath: routerState.uri.toString()),
                        ] else ...[
                          _MenuSection(title: 'OPERATIONS'),
                          if (role == 'INSPECTOR')
                            _MenuItem(icon: Icons.camera_alt, title: 'New Scan', route: '/', currentPath: routerState.uri.toString()),
                          _MenuItem(icon: Icons.inventory_2, title: 'Products', route: '/products', currentPath: routerState.uri.toString()),
                          if (role == 'INSPECTOR') ...[
                            _MenuItem(icon: Icons.warning_amber, title: 'Violations', route: '/violations', currentPath: routerState.uri.toString()),
                            _MenuItem(icon: Icons.history, title: 'Scan History', route: '/history', currentPath: routerState.uri.toString()),
                          ],
                          if (role == 'QA_MANAGER') ...[
                            const SizedBox(height: 24),
                            _MenuSection(title: 'INSIGHTS'),
                            _MenuItem(icon: Icons.bar_chart, title: 'Analytics', route: '/analytics', currentPath: routerState.uri.toString()),
                            _MenuItem(icon: Icons.language, title: 'E-Commerce', route: '/ecommerce', currentPath: routerState.uri.toString()),
                            _MenuItem(icon: Icons.batch_prediction, title: 'Batch Audit', route: '/batch-audit', currentPath: routerState.uri.toString()),
                          ],
                        ],
                        
                        const SizedBox(height: 24),
                        _MenuSection(title: 'SYSTEM'),
                        _MenuItem(icon: Icons.settings, title: 'Settings', route: '/settings', currentPath: routerState.uri.toString()),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final role = authState.role ?? 'INSPECTOR';
    final tabs = _getTabsForRole(role);
    final currentIndex = _calculateSelectedIndex(context, tabs);

    return Scaffold(
      extendBody: true, // Allows body to go behind the bottom bar
      body: child,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(tabs.length, (index) {
                    final tab = tabs[index];
                    final isSelected = currentIndex == index && tab.route != '#menu';
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (tab.route == '#menu') {
                          _showMenu(context, role);
                        } else if (!isSelected) {
                          context.go(tab.route);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 16 : 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? LabelLensColors.brandPrimary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? tab.activeIcon : tab.icon,
                              color: isSelected || tab.route == '#menu' ? LabelLensColors.brandPrimary : LabelLensColors.textTertiary,
                              size: 24,
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Text(
                                tab.label,
                                style: const TextStyle(
                                  color: LabelLensColors.brandPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  const _MenuSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: LabelLensColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final String currentPath;

  const _MenuItem({required this.icon, required this.title, required this.route, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final isSelected = currentPath == route || (route != '/' && currentPath.startsWith(route));
    
    return InkWell(
      onTap: () {
        Navigator.pop(context); // close modal
        if (!isSelected) {
          context.go(route);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? LabelLensColors.brandPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? LabelLensColors.brandPrimary : LabelLensColors.textSecondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? LabelLensColors.brandPrimary : LabelLensColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
