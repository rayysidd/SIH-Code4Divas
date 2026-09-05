import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/tokens/colors.dart';
import '../../providers/auth_provider.dart';
import '../../routing/role_routes.dart';

/// Screen M-01: Splash / Launch Screen
/// Shows logo, loading bar, and model loading progress.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.wait([
        ref.read(authProvider.notifier).rehydrate().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('Session rehydration timed out');
          },
        ),
        Future.delayed(const Duration(seconds: 3)),
      ]);
    } catch (e) {
      debugPrint('Error during splash rehydration: $e');
    } finally {
      ref.read(authProvider.notifier).resetLoading();
    }

    if (!mounted) return;
    try {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        final role = authState.role ?? 'INSPECTOR';
        context.go(homeRouteForRole(role));
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      debugPrint('Error navigating from splash: $e');
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LabelLensColors.brandPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('🔍', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'LabelLens',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 48),

            // Loading bar
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _controller.value,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 4,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Loading inspection model...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 80),
            Text(
              'Dept. of Consumer Affairs',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
