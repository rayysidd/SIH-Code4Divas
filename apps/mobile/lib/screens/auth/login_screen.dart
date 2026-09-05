import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../routing/role_routes.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  
  bool _obscurePassword = true;
  bool _showDemoPanel = false;
  late final AnimationController _animCtrl;

  final _demoAccounts = [
    {'username': 'admin', 'password': 'admin123', 'role': 'ADMIN', 'name': 'System Admin'},
    {'username': 'rajan', 'password': 'inspector123', 'role': 'INSPECTOR', 'name': 'Rajan Tiwari'},
    {'username': 'priya', 'password': 'manager123', 'role': 'QA_MANAGER', 'name': 'Priya Sharma'},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Ensure login button is ready and not stuck in loading state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).resetLoading();
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    ref.read(authProvider.notifier).clearError();

    try {
      final success = await ref.read(authProvider.notifier).login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );

      if (success) {
        if (!mounted) return;
        final role = ref.read(authProvider).role ?? '';
        context.go(homeRouteForRole(role));
      }
    } catch (e) {
      if (mounted) {
        ref.read(authProvider.notifier).resetLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _fillDemoCredentials(Map<String, String> demo) {
    ref.read(authProvider.notifier).resetLoading();
    ref.read(authProvider.notifier).clearError();
    setState(() {
      _usernameCtrl.text = demo['username']!;
      _passwordCtrl.text = demo['password']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: LabelLensColors.surface1,
      body: Stack(
        children: [
          // Background Blobs
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -size.width * 0.1,
                    left: -size.width * 0.1,
                    child: Transform.rotate(
                      angle: _animCtrl.value * 2 * math.pi,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                        child: Container(
                          width: size.width * 0.6,
                          height: size.width * 0.6,
                          decoration: const BoxDecoration(
                            color: LabelLensColors.brandPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -size.width * 0.2,
                    right: -size.width * 0.1,
                    child: Transform.rotate(
                      angle: -_animCtrl.value * 2 * math.pi,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                        child: Container(
                          width: size.width * 0.8,
                          height: size.width * 0.8,
                          decoration: const BoxDecoration(
                            color: LabelLensColors.brandSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Foreground Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(LabelLensSpacing.s4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.all(LabelLensSpacing.s8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🔍', style: TextStyle(fontSize: 32)),
                                SizedBox(width: 8),
                                Text(
                                  'LabelLens',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: LabelLensColors.brandPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Sign In',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: LabelLensColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Packaged Commodity Compliance Dashboard',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: LabelLensColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 32),

                            if (authState.error != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: LabelLensColors.statusFailBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: LabelLensColors.statusFailBorder),
                                ),
                                child: Text(
                                  authState.error!,
                                  style: const TextStyle(color: LabelLensColors.statusFail),
                                ),
                              ),

                            _buildTextField(
                              controller: _usernameCtrl,
                              label: 'Username',
                              icon: Icons.person_outline,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _passwordCtrl,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: authState.isLoading ? null : _onLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LabelLensColors.brandPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20, width: 20, 
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Demo Accounts Toggle
                            Center(
                              child: TextButton.icon(
                                onPressed: () => setState(() => _showDemoPanel = !_showDemoPanel),
                                icon: const Icon(Icons.account_circle_outlined, size: 18),
                                label: Text('${_showDemoPanel ? "Hide" : "Show"} demo accounts'),
                                style: TextButton.styleFrom(foregroundColor: LabelLensColors.textSecondary),
                              ),
                            ),
                            
                            if (_showDemoPanel) ...[
                              const SizedBox(height: 12),
                              ..._demoAccounts.map((demo) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => _fillDemoCredentials(demo),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: LabelLensColors.surface1,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: LabelLensColors.surface3),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: LabelLensColors.brandSecondary.withOpacity(0.1),
                                          child: Text(
                                            demo['name']!.split(' ').map((n) => n[0]).join(''),
                                            style: const TextStyle(
                                              color: LabelLensColors.brandSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(demo['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              Text(demo['role']!, style: const TextStyle(color: LabelLensColors.textTertiary, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                            ],
                            
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? ", style: TextStyle(color: LabelLensColors.textSecondary)),
                                GestureDetector(
                                  onTap: () => context.go('/role-select'),
                                  child: const Text('Register', style: TextStyle(color: LabelLensColors.brandPrimary, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () => context.go('/onboarding'), 
                                child: const Text('Back to Onboarding', style: TextStyle(color: LabelLensColors.textTertiary)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LabelLensColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          onChanged: (_) => ref.read(authProvider.notifier).clearError(),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: LabelLensColors.textTertiary, size: 20),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: LabelLensColors.surface3, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: LabelLensColors.surface3, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: LabelLensColors.brandPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: LabelLensColors.statusFail, width: 2),
            ),
            filled: true,
            fillColor: LabelLensColors.surface1,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
