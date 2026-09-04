import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/scan_home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/verdict_screen.dart';
import 'screens/scan_history_screen.dart';
import 'screens/ecommerce_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/citizen_report_screen.dart';
import 'screens/admin_citizen_reports_screen.dart';
import 'screens/admin_invite_codes_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_audit_log_screen.dart';
import 'screens/admin_rules_version_screen.dart';
import 'screens/admin_analytics_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/products_screen.dart';
import 'screens/violations_screen.dart';
import 'screens/batch_audit_screen.dart';
import 'screens/scan_detail_screen.dart';
import 'screens/analytics_screen.dart';
import 'package:design_system/tokens/colors.dart';

/// LabelLens — Automated LMPC Label Compliance Verification
/// SIH 2026, Problem Statement SIH26034

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: LabelLensApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/role-select', builder: (_, __) => const RoleSelectionScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/citizen', builder: (_, __) => const CitizenReportScreen()),

    // Main app shell with bottom navigation
    ShellRoute(
      builder: (_, state, child) => ShellScreen(child: child, routerState: state),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const ScanHomeScreen()),
        GoRoute(path: '/history', builder: (_, __) => const ScanHistoryScreen()),
        GoRoute(path: '/ecommerce', builder: (_, __) => const EcommerceScreen()),
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/products', builder: (_, __) => const ProductsScreen()),
        GoRoute(path: '/violations', builder: (_, __) => const ViolationsScreen()),
        GoRoute(path: '/batch-audit', builder: (_, __) => const BatchAuditScreen()),
        GoRoute(path: '/citizen-reports', builder: (_, __) => const AdminCitizenReportsScreen()),
        
        // Admin routes
        GoRoute(
          path: '/admin/invite-codes',
          builder: (context, __) => _adminGatedScreen(context, const AdminInviteCodesScreen()),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, __) => _adminGatedScreen(context, const AdminUsersScreen()),
        ),
        GoRoute(
          path: '/admin/audit-log',
          builder: (context, __) => _adminGatedScreen(context, const AdminAuditLogScreen()),
        ),
        GoRoute(
          path: '/admin/rules-version',
          builder: (context, __) => _adminGatedScreen(context, const AdminRulesVersionScreen()),
        ),
        GoRoute(
          path: '/admin/analytics',
          builder: (context, __) => _adminGatedScreen(context, const AdminAnalyticsScreen()),
        ),
      ],
    ),

    // Full-screen flows (no bottom nav)
    GoRoute(path: '/camera', builder: (_, __) => const CameraScreen()),
    GoRoute(path: '/processing', builder: (_, __) => const ProcessingScreen()),
    GoRoute(path: '/verdict', builder: (_, __) => const VerdictScreen()),
    GoRoute(
      path: '/scan/:id', 
      builder: (context, state) => ScanDetailScreen(scanId: state.pathParameters['id'] ?? '1'),
    ),
  ],
);

Widget _adminGatedScreen(BuildContext context, Widget screen) {
  // We can check role via ProviderScope, but since this builder runs 
  // in the widget tree, we can use ProviderScope.containerOf(context) 
  // or simply rely on the auth state.
  return Consumer(
    builder: (context, ref, child) {
      final authState = ref.watch(authProvider);
      if (authState.role == 'ADMIN') {
        return screen;
      } else {
        return const Scaffold(
          body: Center(
            child: Text('Officer access required', style: TextStyle(fontSize: 18)),
          ),
        );
      }
    },
  );
}

class LabelLensApp extends ConsumerWidget {
  const LabelLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'LabelLens',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Noto Sans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: LabelLensColors.brandPrimary,
          primary: LabelLensColors.brandPrimary,
          secondary: LabelLensColors.brandSecondary,
        ),
        scaffoldBackgroundColor: LabelLensColors.surface1,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Noto Sans',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: LabelLensColors.dmBrandPrimary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: LabelLensColors.dmSurface1,
      ),
      routerConfig: _router,
    );
  }
}
