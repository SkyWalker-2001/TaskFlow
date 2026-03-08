import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2EFE6), Color(0xFFEAE4D8), Color(0xFFF6F2E9)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -40,
              child: _DecorativeOrb(
                size: 230,
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              top: 180,
              left: -100,
              child: _DecorativeOrb(
                size: 220,
                color: const Color(0xFFF09A36).withValues(alpha: 0.13),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0C6B58,
                                ).withValues(alpha: 0.16),
                                blurRadius: 26,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset('assets/icons/app_icon.png'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'TaskFlow',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Welcome Back',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Login to continue managing your tasks.',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: const Color(0xFF4B5B51),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                    ),
                                    validator: (value) {
                                      final text = (value ?? '').trim();
                                      final regex = RegExp(
                                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                      );
                                      if (text.isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!regex.hasMatch(text)) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                    ),
                                    validator: (value) {
                                      if ((value ?? '').isEmpty) {
                                        return 'Password is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text('Forgot Password?'),
                                    ),
                                  ),
                                  if (auth.error != null) ...[
                                    Text(
                                      auth.error!,
                                      style: const TextStyle(
                                        color: Color(0xFFB42318),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(56),
                                      textStyle: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    onPressed: auth.isLoading ? null : _login,
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Login'),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const SignupScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('Create an account'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
