import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../widgets/common/design_system.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late UserRole _selectedRole;
  late bool _isActive;
  bool _isLoading = false;
  String? _errorMessage;

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _userService.updateUser(widget.user.id, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole.name,
        'isActive': _isActive,
      });

      // Cập nhật permissions theo role mới
      await _userService.updateUserRole(widget.user.id, _selectedRole);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin thành công'),
            backgroundColor: mainGreen,
          ),
        );
        Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết nhân viên'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _updateUser,
              child: Text('Lưu', style: body.copyWith(color: mainGreen, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF6F7F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thông tin cơ bản
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(widget.user.roleColor).withOpacity(0.1),
                          child: Text(
                            widget.user.name?.substring(0, 1).toUpperCase() ?? 
                            widget.user.email.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              color: Color(widget.user.roleColor),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.name ?? 'Chưa có tên',
                                style: h3.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.user.email,
                                style: body.copyWith(color: textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(widget.user.roleColor).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      widget.user.roleDisplayName,
                                      style: caption.copyWith(
                                        color: Color(widget.user.roleColor),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _isActive ? mainGreen.withOpacity(0.1) : destructiveRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _isActive ? 'Hoạt động' : 'Vô hiệu',
                                      style: caption.copyWith(
                                        color: _isActive ? mainGreen : destructiveRed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                    TextFormField(
                      controller: _phoneController,
                      decoration: designSystemInputDecoration(
                        label: 'Số điện thoại',
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Phân quyền
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phân quyền', style: h4.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      decoration: designSystemInputDecoration(
                        label: 'Vai trò *',
                        prefixIcon: const Icon(Icons.work),
                      ),
                      items: UserRole.values.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(role == UserRole.admin ? 0xFFDC2626 : 0xFF059669),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(role == UserRole.admin ? 'Quản trị viên' : 'Nhân viên'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Trạng thái hoạt động'),
                      subtitle: Text(_isActive ? 'Đang hoạt động' : 'Đã vô hiệu hóa'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: mainGreen,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Thông tin bổ sung
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin bổ sung', style: h4.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    _buildInfoRow('Ngày tạo', _formatDate(widget.user.createdAt)),
                    const SizedBox(height: 8),
                    _buildInfoRow('Cập nhật lần cuối', _formatDate(widget.user.updatedAt)),
                    if (widget.user.createdBy != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Tạo bởi', widget.user.createdBy!),
                    ],
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
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: small.copyWith(color: textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: small.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 