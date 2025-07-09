import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../widgets/common/design_system.dart';
import '../../widgets/main_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final UserService _userService = UserService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Kiểm tra email đã tồn tại chưa
        final exists = await _userService.userExists(_emailController.text.trim());
        if (exists) {
          setState(() {
            _errorMessage = 'Email này đã được sử dụng';
          });
          return;
        }

        // Tạo user mới với role employee
        final user = await _userService.registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          role: UserRole.employee, // Chỉ tạo employee, không tạo admin
        );

        if (user != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đăng ký thành công!'),
                backgroundColor: mainGreen,
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainLayout()),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'Có lỗi xảy ra khi đăng ký';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Có lỗi xảy ra: ${e.toString()}';
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
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF6F7F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: mainGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 40,
                      color: mainGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tạo tài khoản nhân viên',
                    style: responsiveTextStyle(
                      context, 
                      h1.copyWith(color: mainGreen), 
                      h1Mobile.copyWith(color: mainGreen)
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đăng ký tài khoản nhân viên mới',
                    style: responsiveTextStyle(
                      context, 
                      body.copyWith(color: textSecondary), 
                      bodyMobile.copyWith(color: textSecondary)
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              SizedBox(height: MediaQuery.of(context).size.width < 600 ? spaceMobile * 4 : space32),
              
              // Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin nhân viên',
                      style: h4.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 24),
                    
                    // Tên
                    TextFormField(
                      controller: _nameController,
                      decoration: designSystemInputDecoration(
                        label: 'Họ và tên *',
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập họ và tên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: designSystemInputDecoration(
                        label: 'Email *',
                        prefixIcon: const Icon(Icons.email),
                        hint: 'example@email.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Mật khẩu
                    TextFormField(
                      controller: _passwordController,
                      decoration: designSystemInputDecoration(
                        label: 'Mật khẩu *',
                        prefixIcon: const Icon(Icons.lock),
                        hint: 'Ít nhất 6 ký tự',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Xác nhận mật khẩu
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: designSystemInputDecoration(
                        label: 'Xác nhận mật khẩu *',
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu';
                        }
                        if (value != _passwordController.text) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: destructiveRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: destructiveRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: caption.copyWith(color: destructiveRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Thông tin về quyền employee
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: mainGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: mainGreen.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: mainGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Quyền nhân viên',
                          style: body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: mainGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tài khoản nhân viên có thể:\n'
                      '• Xem và quản lý sản phẩm\n'
                      '• Tạo và quản lý đơn hàng\n'
                      '• Quản lý khách hàng\n'
                      '• Thực hiện kiểm kê\n'
                      '• Xem báo cáo cơ bản',
                      style: small.copyWith(color: textSecondary),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: primaryButtonStyle,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Đăng ký tài khoản',
                        style: body.copyWith(fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pushReplacementNamed(context, '/login'),
                style: ghostButtonStyle,
                child: Text(
                  'Đã có tài khoản? Đăng nhập',
                  style: small.copyWith(color: mainGreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 