// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../theme/fbla_colors.dart';
import '../widgets/app_chrome.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showEntry = true;
  String? _error;
  late final AnimationController _paintController;
  late final Animation<double> _paintProgress;

  @override
  void initState() {
    super.initState();
    _paintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _paintProgress = CurvedAnimation(
      parent: _paintController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _paintController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _startEntry() async {
    if (!_showEntry || _paintController.isAnimating) return;
    await _paintController.forward();
    if (!mounted) return;
    setState(() => _showEntry = false);
    _paintController.reset();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      String message = e.toString();
      if (message.contains('firebase') ||
          message.contains('network') ||
          message.contains('API') ||
          message.contains('configuration')) {
        message =
            'Login failed. Check that Firebase is configured with your project (see SWITCH_FIREBASE.md). Details: ${e.toString()}';
      } else if (message.contains('user-not-found') ||
          message.contains('wrong-password') ||
          message.contains('invalid-credential')) {
        message = 'Invalid email or password.';
      } else if (message.contains('invalid-email')) {
        message = 'Invalid email address.';
      } else if (message.contains('too-many-requests')) {
        message = 'Too many attempts. Try again later.';
      }
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _authService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 126, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/fbla_logo.png', height: 92),
                  const SizedBox(height: 28),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: FblaColors.crimson.withOpacity(0.45)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFF8B1538)),
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFD7D7D7),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Value',
                              border: OutlineInputBorder(),
                            ),
                            validator: validateEmail,
                          ),
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Value',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: validatePassword,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 44,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _login,
                              style: FilledButton.styleFrom(
                                backgroundColor: FblaColors.navy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: _resetPassword,
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: FblaColors.text,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  const Center(
                    child: Text(
                      'The Official* FBLA Member App',
                      style: TextStyle(fontSize: 19, color: Color(0xFF2D2B2B)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen()),
                        );
                      },
                      child: const Text('Create account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showEntry) _EntryScreen(onStart: _startEntry),
          AnimatedBuilder(
            animation: _paintProgress,
            builder: (context, _) {
              return PaintStrokeReveal(progress: _paintProgress.value);
            },
          ),
        ],
      ),
    );
  }
}

class _EntryScreen extends StatelessWidget {
  const _EntryScreen({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onStart,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Spacer(),
                  Image.asset('assets/fbla_logo.png', height: 120),
                  const SizedBox(height: 16),
                  const Text(
                    'The Official* FBLA Member App',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Color(0xFF2D2B2B)),
                  ),
                  const Spacer(),
                  const Text(
                    'Tap Anywhere to Start',
                    style: TextStyle(
                      color: Color(0xFF2D2B2B),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
