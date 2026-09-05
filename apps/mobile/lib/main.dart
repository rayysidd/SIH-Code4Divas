import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';

// Auth screens
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/login_screen.dart';

// Shared screens
import 'screens/shared/shell_screen.dart';
import 'screens/shared/settings_screen.dart';

// Inspector screens
import 'screens/inspector/scan_home_screen.dart';
import 'screens/inspector/camera_screen.dart';
import 'screens/inspector/processing_screen.dart';
import 'screens/inspector/verdict_screen.dart';
import 'screens/inspector/scan_history_screen.dart';
import 'screens/inspector/violations_screen.dart';
import 'screens/inspector/scan_detail_screen.dart';
import 'screens/inspector/inspector_overview_screen.dart';

// QA Manager screens
import 'screens/qa_manager/products_screen.dart';
import 'screens/qa_manager/analytics_screen.dart';
import 'screens/qa_manager/batch_audit_screen.dart';

// Admin screens
import 'screens/admin/admin_overview_screen.dart';
import 'screens/admin/admin_citizen_reports_screen.dart';
import 'screens/admin/admin_invite_codes_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_audit_log_screen.dart';
import 'screens/admin/admin_rules_version_screen.dart';
import 'screens/admin/admin_analytics_screen.dart';

// Ecom Lead screens
import 'screens/ecom_lead/ecommerce_screen.dart';
import 'screens/ecom_lead/ecom_overview_screen.dart';

// Citizen screens
import 'screens/citizen/citizen_report_screen.dart';

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
        
        // Per-role overviews
        GoRoute(
          path: '/admin/overview',
          builder: (context, __) => _adminGatedScreen(context, const AdminOverviewScreen()),
        ),
        GoRoute(path: '/qa/overview', builder: (_, __) => const AnalyticsScreen()),
        GoRoute(path: '/inspector/overview', builder: (_, __) => const InspectorOverviewScreen()),
        GoRoute(path: '/ecom/overview', builder: (_, __) => const EcomOverviewScreen()),

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
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: LabelLensColors.brandPrimary),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: LabelLensColors.brandPrimary,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
