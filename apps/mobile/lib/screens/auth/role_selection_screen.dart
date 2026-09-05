import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../routing/role_routes.dart';

/// Screen M-03: Real Registration Screen
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _inviteCodeCtrl = TextEditingController();
  
  bool _obscurePassword = true;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).resetLoading();
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();

    final result = await ref.read(authProvider.notifier).register(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
      _fullNameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _inviteCodeCtrl.text.trim(),
    );

    if (result['success'] == true) {
      setState(() => _successMessage = result['message']);
      
      // Auto-route after a brief delay based on role
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        final role = result['role'] ?? 'INSPECTOR';
        context.go(homeRouteForRole(role));
      });
    }
  }
  
  String? _getDynamicEmailHint() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) return null;
    
    final domain = email.split('@').last.toLowerCase();
    if (['amazon.in', 'flipkart.com', 'meesho.com'].contains(domain)) {
      return "You'll get Platform Lead access";
    }
    
    if (_inviteCodeCtrl.text.trim().isEmpty) {
      return "You'll get Citizen access — ask your department for an officer code.";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: LabelLensColors.surface0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create Account',
            style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LabelLensSpacing.s6),
          child: _successMessage != null
            ? _buildSuccessView()
            : _buildForm(authState),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 64),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: LabelLensColors.statusPass,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: LabelLensColors.statusPass.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 48),
        ),
        const SizedBox(height: LabelLensSpacing.s6),
        const Text(
          'Registration Successful!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: LabelLensSpacing.s4),
        Text(
          _successMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: LabelLensColors.textSecondary),
        ),
        const SizedBox(height: LabelLensSpacing.s8),
        const CircularProgressIndicator(strokeWidth: 2),
        const SizedBox(height: LabelLensSpacing.s4),
        const Text(
          'Redirecting to your dashboard...',
          style: TextStyle(fontSize: 14, color: LabelLensColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildForm(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            controller: _fullNameCtrl,
            label: 'Full Name',
            icon: Icons.badge_outlined,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: LabelLensSpacing.s4),

          _buildTextField(
            controller: _emailCtrl,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
            onChanged: (_) => setState(() {}),
          ),
          if (_getDynamicEmailHint() != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: LabelLensColors.brandPrimary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getDynamicEmailHint()!,
                      style: const TextStyle(fontSize: 12, color: LabelLensColors.brandPrimary),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: LabelLensSpacing.s4),

          _buildTextField(
            controller: _usernameCtrl,
            label: 'Username',
            icon: Icons.person_outline,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: LabelLensSpacing.s4),

          _buildTextField(
            controller: _passwordCtrl,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null,
          ),
          const SizedBox(height: LabelLensSpacing.s4),

          _buildTextField(
            controller: _inviteCodeCtrl,
            label: 'Invite Code (Optional)',
            icon: Icons.vpn_key_outlined,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: LabelLensSpacing.s8),

          ElevatedButton(
            onPressed: authState.isLoading ? null : _onRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: LabelLensColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: authState.isLoading
                ? const SizedBox(
                    height: 20, width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          
          const SizedBox(height: LabelLensSpacing.s4),
          TextButton(
            onPressed: () => context.go('/login'), 
            child: const Text('Already have an account? Log in'),
          ),
          TextButton(
            onPressed: () => context.go('/onboarding'), 
            child: const Text('Back to Onboarding', style: TextStyle(color: LabelLensColors.textTertiary)),
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: LabelLensColors.textTertiary),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LabelLensColors.surface3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LabelLensColors.surface3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LabelLensColors.brandPrimary, width: 2),
        ),
        filled: true,
        fillColor: LabelLensColors.surface1,
      ),
    );
  }
}
