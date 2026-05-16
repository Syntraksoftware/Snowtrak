import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/auth/register_screen.dart';

/// Social login button widget
class _SocialLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String label;

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    // Check if widget is still mounted before calling setState
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success && mounted) {
      // Show helpful error message with registration prompt
      final errorMessage = authProvider.error ?? 'Login failed';
      final isAuthError =
          errorMessage.toLowerCase().contains('invalid email or password') ||
              errorMessage.toLowerCase().contains('invalid credentials') ||
              errorMessage.toLowerCase().contains('unauthorized');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (isAuthError) ...[
                const SizedBox(height: 8),
                const Text(
                  'Don\'t have an account? Please register to create one.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: isAuthError
              ? SnackBarAction(
                  label: 'Sign Up',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                )
              : null,
        ),
      );
    } else if (success) {
      // Login successful - the Consumer in main.dart will automatically rebuild
      // Wait a moment to ensure state propagates
      print(
          '🔍 [LoginScreen] Login successful, isAuthenticated: ${authProvider.isAuthenticated}');

      // Give the Consumer time to rebuild
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify state
      if (mounted) {
        print(
            '🔍 [LoginScreen] After delay, isAuthenticated: ${authProvider.isAuthenticated}');
        // The Consumer should have rebuilt by now and shown HomeScreen
        // If still on login screen, there might be an issue with the Consumer
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to auth state changes
    // When authenticated, the Consumer in main.dart will automatically show HomeScreen
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // If user becomes authenticated while on this screen,
        // the Consumer in main.dart will rebuild and show HomeScreen
        if (authProvider.isAuthenticated) {
          print(
              '🔍 [LoginScreen] User authenticated, Consumer in main.dart should show HomeScreen');
          // Return a loading indicator briefly while navigation happens
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
              ),
            ),
          );
        }

        return _buildLoginForm(context);
      },
    );
  }

  // Google "G" icon widget
  Widget _buildGoogleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.red[600],
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Title
                  const Text(
                    'Syntrak',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF4500),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track your activities',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4500),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Log In',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Divider with "or"
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey[400]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social login buttons
                  Row(
                    children: [
                      // Google button
                      Expanded(
                        child: _SocialLoginButton(
                          onPressed: () {
                            // TODO: Implement Google Sign-In
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Google Sign-In coming soon!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: _buildGoogleIcon(),
                          label: 'Google',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Facebook button
                      Expanded(
                        child: _SocialLoginButton(
                          onPressed: () {
                            // TODO: Implement Facebook Sign-In
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Facebook Sign-In coming soon!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.facebook,
                            color: Color(0xFF1877F2),
                            size: 24,
                          ),
                          label: 'Facebook',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('Don\'t have an account? Sign up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
