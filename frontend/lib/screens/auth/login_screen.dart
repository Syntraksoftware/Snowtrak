import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/auth/auth_feedback.dart';
import 'package:syntrak/screens/auth/register_screen.dart';
import 'package:syntrak/ui/liquid/liquid.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      showAuthErrorSnackBar(context, authProvider.error ?? 'Login failed');
    }
  }

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _showComingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign-in coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAuthenticated) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(SnowtrakAuthTheme.brand),
              ),
            ),
          );
        }

        return AuthPageScaffold(
          title: 'Log in to Snowtrak',
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
                    if (!value.contains('@')) {
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
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your password';
                    }
                    if (value.length < 6) {
                      return 'At least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: SyntrakSpacing.xl),
                AuthPrimaryButton(
                  label: 'Log In',
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
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
                  prompt: "Don't have an account?",
                  actionLabel: 'Sign up',
                  onPressed: _openRegister,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
