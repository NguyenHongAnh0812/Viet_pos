import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_layout.dart';
import '../widgets/common/design_system.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'admin1@gmail.com');
  final _passwordController = TextEditingController(text: 'admin123');
  String? _error;
  bool _loading = false;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    } catch (e) {
      setState(() {
        _error = 'Đăng nhập thất bại: ${e.toString()}';
      });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final cardWidth = isMobile ? screenWidth - 48 : 400.0;

    return Scaffold(
      backgroundColor: appBackground,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo and Title
                Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(borderRadiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 40,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        'VET-POS',
                        style: h1.copyWith(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đăng nhập vào hệ thống',
                        style: body.copyWith(
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Email Field
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(fontSize: 14),
                        decoration: designSystemInputDecoration(
                          label: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined, color: textSecondary),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      TextField(
                        controller: _passwordController,
                        style: const TextStyle(fontSize: 14),
                        decoration: designSystemInputDecoration(
                          label: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline, color: textSecondary),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: primaryButtonStyle,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Đăng nhập',
                                  style: body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: destructiveRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(borderRadiusMedium),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: destructiveRed,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: caption.copyWith(color: destructiveRed),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Footer
                const SizedBox(height: 24),
                Text(
                  '© 2024 VET-POS. All rights reserved.',
                  style: caption.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 