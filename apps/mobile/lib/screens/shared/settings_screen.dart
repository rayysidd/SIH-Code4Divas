import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

/// Screen M-15: Settings Screen with Glassmorphism
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: const Text('Settings', style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // Subtle background blobs for visual depth
          Positioned(
            top: -50,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: LabelLensColors.brandSecondary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(LabelLensSpacing.s4),
              children: [
                _GlassSection(
                  title: 'Account',
                  children: [
                    _SettingsItem(icon: Icons.person_outline, title: 'Profile', onTap: () {}),
                    _SettingsItem(
                      icon: Icons.logout,
                      title: 'Log Out',
                      isDestructive: true,
                      onTap: () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: LabelLensSpacing.s6),
                
                _GlassSection(
                  title: 'App',
                  children: [
                    _SettingsItem(icon: Icons.language, title: 'Language', trailing: 'English', onTap: () {}),
                    _SettingsItem(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      trailing: ref.watch(themeModeProvider) == ThemeMode.dark ? 'On' : (ref.watch(themeModeProvider) == ThemeMode.light ? 'Off' : 'System'),
                      onTap: () {
                        final current = ref.read(themeModeProvider);
                        if (current == ThemeMode.system) {
                          ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
                        } else if (current == ThemeMode.dark) {
                          ref.read(themeModeProvider.notifier).state = ThemeMode.light;
                        } else {
                          ref.read(themeModeProvider.notifier).state = ThemeMode.system;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: LabelLensSpacing.s6),
                
                _GlassSection(
                  title: 'About',
                  children: [
                    _SettingsItem(icon: Icons.info_outline, title: 'App Version', trailing: '1.0.0 (SIH 2026)', onTap: () {}),
                    _SettingsItem(icon: Icons.gavel, title: 'Rules Engine', trailing: 'LMPC 2024.01', onTap: () {}),
                  ],
                ),
                
                const SizedBox(height: 100), // Padding for the floating bottom bar
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _GlassSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: LabelLensColors.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: children.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final widget = entry.value;
                  final isLast = idx == children.length - 1;
                  return Column(
                    children: [
                      widget,
                      if (!isLast)
                        Container(
                          height: 1,
                          color: LabelLensColors.surface3.withOpacity(0.5),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? LabelLensColors.statusFail.withOpacity(0.1) : LabelLensColors.brandPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? LabelLensColors.statusFail : LabelLensColors.brandPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? LabelLensColors.statusFail : LabelLensColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  color: LabelLensColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (onTap != null && trailing == null)
              const Icon(Icons.chevron_right, color: LabelLensColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
