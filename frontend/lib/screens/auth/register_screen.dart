import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/auth/auth_feedback.dart';
import 'package:syntrak/ui/liquid/liquid.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      showAuthErrorSnackBar(
        context,
        authProvider.error ?? 'Registration failed',
      );
    }
  }

  void _showComingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign-up coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      title: 'Sign up for Snowtrak',
      onClose: () => Navigator.pop(context),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthLabeledField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your email';
                }
                if (!_emailRegex.hasMatch(value.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: SyntrakSpacing.lg),
            AuthLabeledField(
              label: 'Password',
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter a password';
                }
                if (value.length < 8) {
                  return 'At least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: SyntrakSpacing.lg),
            AuthLabeledField(
              label: 'Confirm password',
              controller: _confirmPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleRegister(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: SyntrakSpacing.xl),
            AuthPrimaryButton(
              label: 'Sign Up',
              isLoading: _isLoading,
              onPressed: _handleRegister,
            ),
            const SizedBox(height: SyntrakSpacing.xl),
            const AuthOrDivider(),
            const SizedBox(height: SyntrakSpacing.xl),
            AuthSocialButton(
              provider: AuthSocialProvider.google,
              onPressed: () => _showComingSoon('Google'),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            AuthSocialButton(
              provider: AuthSocialProvider.apple,
              onPressed: () => _showComingSoon('Apple'),
            ),
            const SizedBox(height: SyntrakSpacing.xl),
            AuthAccountLink(
              prompt: 'Already have an account?',
              actionLabel: 'Log in',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
