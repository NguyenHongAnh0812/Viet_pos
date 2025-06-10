import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/design_system.dart';
import '../../widgets/main_layout.dart';

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
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          // Lưu trạng thái đăng nhập
          await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
          
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainLayout()),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'user-not-found') {
            _errorMessage = 'Không tìm thấy tài khoản với email này';
          } else if (e.code == 'wrong-password') {
            _errorMessage = 'Mật khẩu không đúng';
          } else if (e.code == 'invalid-email') {
            _errorMessage = 'Email không hợp lệ';
          } else {
            _errorMessage = e.message ?? 'Đã xảy ra lỗi khi đăng nhập';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Đã xảy ra lỗi không xác định';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'VET-POS',
                  style: responsiveTextStyle(context, h1.copyWith(color: primaryBlue), h1Mobile.copyWith(color: primaryBlue)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.width < 600 ? spaceMobile : space8),
                Text(
                  'Đăng nhập để tiếp tục',
                  style: responsiveTextStyle(context, small.copyWith(color: textSecondary), smallMobile.copyWith(color: textSecondary)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.width < 600 ? spaceMobile * 4 : space32),
                TextFormField(
                  controller: _emailController,
                  decoration: designSystemInputDecoration(
                    label: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    hint: 'example@email.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                SizedBox(height: MediaQuery.of(context).size.width < 600 ? spaceMobile * 2 : space16),
                TextFormField(
                  controller: _passwordController,
                  decoration: designSystemInputDecoration(
                    label: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock),
                    hint: 'Nhập mật khẩu của bạn',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: MediaQuery.of(context).size.width < 600 ? spaceMobile * 2 : space16),
                  Text(
                    _errorMessage!,
                    style: caption.copyWith(color: destructiveRed),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: MediaQuery.of(context).size.width < 600 ? spaceMobile * 3 : space24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: primaryButtonStyle,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Đăng nhập', style: body.copyWith(fontWeight: FontWeight.w600)),
                ),
                SizedBox(height: MediaQuery.of(context).size.width < 600 ? spaceMobile * 2 : space16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pushNamed(context, '/register'),
                  child: const Text(
                    'Chưa có tài khoản? Đăng ký ngay',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
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