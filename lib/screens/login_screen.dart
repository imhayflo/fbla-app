// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../theme/fbla_colors.dart';
import '../widgets/app_chrome.dart';
import 'demo_tour_screen.dart';
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

  void _openDemo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DemoTourScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FblaColors.paper,
      body: Stack(
        children: [
          const _LoginBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 126, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: FblaColors.navy.withOpacity(0.12),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/fbla_logo.png', height: 76),
                  ),
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
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: FblaColors.navy.withOpacity(0.14),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Value',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                                  borderRadius: BorderRadius.circular(16),
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
                      style: TextStyle(
                        fontSize: 19,
                        color: FblaColors.text,
                        fontWeight: FontWeight.w700,
                      ),
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
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _openDemo,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Launch guided demo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FblaColors.navy,
                      side: const BorderSide(color: FblaColors.navy),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showEntry) _EntryScreen(onStart: _startEntry, onDemo: _openDemo),
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
  const _EntryScreen({required this.onStart, required this.onDemo});

  final VoidCallback onStart;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onStart,
          child: SafeArea(
            child: Stack(
              children: [
                const _LoginBackdrop(),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: SizedBox.expand(
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          FblaColors.navy.withOpacity(0.14),
                                      blurRadius: 32,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/fbla_logo.png',
                                  height: 104,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'The Official* FBLA Member App',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: FblaColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: onDemo,
                                  icon: const Icon(Icons.play_circle_outline),
                                  label: const Text('Watch guided demo'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: FblaColors.navy,
                                    side: const BorderSide(
                                      color: FblaColors.navy,
                                      width: 1.5,
                                    ),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Tap Anywhere to Start',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: FblaColors.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF9FBFF),
              Color(0xFFEAF1FB),
              Color(0xFFFAF9F6),
            ],
          ),
        ),
      ),
    );
  }
}
