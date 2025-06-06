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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
    return Scaffold(
      backgroundColor: appBackground,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Đăng nhập', style: responsiveTextStyle(context, h2.copyWith(fontWeight: FontWeight.bold), h2Mobile.copyWith(fontWeight: FontWeight.bold))),
                SizedBox(height: MediaQuery.of(context).size.width < 1024 ? spaceMobile * 3 : space24),
                TextField(
                  controller: _emailController,
                  decoration: designSystemInputDecoration(label: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: MediaQuery.of(context).size.width < 1024 ? spaceMobile * 2 : space16),
                TextField(
                  controller: _passwordController,
                  decoration: designSystemInputDecoration(label: 'Mật khẩu'),
                  obscureText: true,
                ),
                SizedBox(height: MediaQuery.of(context).size.width < 1024 ? spaceMobile * 3 : space24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: primaryButtonStyle,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Đăng nhập', style: responsiveTextStyle(context, body.copyWith(fontWeight: FontWeight.w600), bodyMobile.copyWith(fontWeight: FontWeight.w600))),
                  ),
                ),
                if (_error != null) ...[
                  SizedBox(height: MediaQuery.of(context).size.width < 1024 ? spaceMobile * 2 : space16),
                  Text(_error!, style: responsiveTextStyle(context, caption.copyWith(color: destructiveRed), captionMobile.copyWith(color: destructiveRed))),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
} 