import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../widgets/common/design_system.dart';

class TestClearUsersScreen extends StatefulWidget {
  const TestClearUsersScreen({super.key});

  @override
  State<TestClearUsersScreen> createState() => _TestClearUsersScreenState();
}

class _TestClearUsersScreenState extends State<TestClearUsersScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;
  String _message = '';

  Future<void> _clearUsers() async {
    setState(() {
      _isLoading = true;
      _message = 'Đang xóa users...';
    });

    try {
      await _userService.clearAllUsers();
      setState(() {
        _message = 'Đã xóa tất cả users! Bây giờ hãy refresh app để thấy setup admin screen.';
      });
    } catch (e) {
      setState(() {
        _message = 'Lỗi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Clear Users'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'Test Setup Admin Screen',
                style: h2.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Màn hình này dùng để test setup admin screen.\n'
                'Nhấn nút bên dưới để xóa tất cả users trong Firestore.',
                style: body.copyWith(color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _clearUsers,
                style: primaryButtonStyle,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Xóa tất cả Users'),
              ),
              const SizedBox(height: 16),
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: mainGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: mainGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    _message,
                    style: body.copyWith(color: mainGreen),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Sau khi xóa users:\n'
                '1. Refresh app (F5)\n'
                '2. Sẽ thấy setup admin screen\n'
                '3. Tạo admin đầu tiên',
                style: small.copyWith(color: textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 