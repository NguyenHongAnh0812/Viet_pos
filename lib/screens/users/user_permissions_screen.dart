import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../widgets/common/design_system.dart';

class UserPermissionsScreen extends StatefulWidget {
  final User user;
  const UserPermissionsScreen({super.key, required this.user});

  @override
  State<UserPermissionsScreen> createState() => _UserPermissionsScreenState();
}

class _UserPermissionsScreenState extends State<UserPermissionsScreen> {
  final UserService _userService = UserService();
  late List<Permission> _selectedPermissions;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedPermissions = List.from(widget.user.permissions);
  }

  Future<void> _savePermissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _userService.updateUserPermissions(widget.user.id, _selectedPermissions);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật quyền thành công'),
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

  void _togglePermission(Permission permission) {
    setState(() {
      if (_selectedPermissions.contains(permission)) {
        _selectedPermissions.remove(permission);
      } else {
        _selectedPermissions.add(permission);
      }
    });
  }

  String _getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.viewProducts:
        return 'Xem danh sách sản phẩm';
      case Permission.addProducts:
        return 'Thêm sản phẩm mới';
      case Permission.editProducts:
        return 'Chỉnh sửa thông tin sản phẩm';
      case Permission.deleteProducts:
        return 'Xóa sản phẩm';
      case Permission.viewCustomers:
        return 'Xem danh sách khách hàng';
      case Permission.addCustomers:
        return 'Thêm khách hàng mới';
      case Permission.editCustomers:
        return 'Chỉnh sửa thông tin khách hàng';
      case Permission.deleteCustomers:
        return 'Xóa khách hàng';
      case Permission.viewOrders:
        return 'Xem danh sách đơn hàng';
      case Permission.createOrders:
        return 'Tạo đơn hàng mới';
      case Permission.editOrders:
        return 'Chỉnh sửa đơn hàng';
      case Permission.deleteOrders:
        return 'Xóa đơn hàng';
      case Permission.viewInventory:
        return 'Xem kiểm kê';
      case Permission.createInventory:
        return 'Tạo phiên kiểm kê';
      case Permission.editInventory:
        return 'Chỉnh sửa kiểm kê';
      case Permission.confirmInventory:
        return 'Xác nhận kiểm kê';
      case Permission.viewCompanies:
        return 'Xem danh sách nhà cung cấp';
      case Permission.addCompanies:
        return 'Thêm nhà cung cấp mới';
      case Permission.editCompanies:
        return 'Chỉnh sửa nhà cung cấp';
      case Permission.deleteCompanies:
        return 'Xóa nhà cung cấp';
      case Permission.viewCategories:
        return 'Xem danh mục sản phẩm';
      case Permission.addCategories:
        return 'Thêm danh mục mới';
      case Permission.editCategories:
        return 'Chỉnh sửa danh mục';
      case Permission.deleteCategories:
        return 'Xóa danh mục';
      case Permission.viewSettings:
        return 'Xem cài đặt hệ thống';
      case Permission.editSettings:
        return 'Chỉnh sửa cài đặt hệ thống';
      case Permission.viewUsers:
        return 'Xem danh sách nhân viên';
      case Permission.addUsers:
        return 'Thêm nhân viên mới';
      case Permission.editUsers:
        return 'Chỉnh sửa thông tin nhân viên';
      case Permission.deleteUsers:
        return 'Xóa nhân viên';
    }
  }

  IconData _getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.viewProducts:
      case Permission.addProducts:
      case Permission.editProducts:
      case Permission.deleteProducts:
        return Icons.inventory;
      case Permission.viewCustomers:
      case Permission.addCustomers:
      case Permission.editCustomers:
      case Permission.deleteCustomers:
        return Icons.people;
      case Permission.viewOrders:
      case Permission.createOrders:
      case Permission.editOrders:
      case Permission.deleteOrders:
        return Icons.shopping_cart;
      case Permission.viewInventory:
      case Permission.createInventory:
      case Permission.editInventory:
      case Permission.confirmInventory:
        return Icons.assessment;
      case Permission.viewCompanies:
      case Permission.addCompanies:
      case Permission.editCompanies:
      case Permission.deleteCompanies:
        return Icons.business;
      case Permission.viewCategories:
      case Permission.addCategories:
      case Permission.editCategories:
      case Permission.deleteCategories:
        return Icons.category;
      case Permission.viewSettings:
      case Permission.editSettings:
        return Icons.settings;
      case Permission.viewUsers:
      case Permission.addUsers:
      case Permission.editUsers:
      case Permission.deleteUsers:
        return Icons.admin_panel_settings;
    }
  }

  Color _getPermissionColor(Permission permission) {
    if (permission.toString().contains('delete')) {
      return destructiveRed;
    } else if (permission.toString().contains('add') || permission.toString().contains('create')) {
      return mainGreen;
    } else if (permission.toString().contains('edit')) {
      return Colors.orange;
    } else {
      return textSecondary;
    }
  }

  Widget _buildPermissionGroup(String title, List<Permission> permissions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: h4.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ...permissions.map((permission) => _buildPermissionTile(permission)),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(Permission permission) {
    final isSelected = _selectedPermissions.contains(permission);
    final icon = _getPermissionIcon(permission);
    final color = _getPermissionColor(permission);
    final description = _getPermissionDescription(permission);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                permission.name.replaceAll('_', ' ').toUpperCase(),
                style: body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Text(
          description,
          style: small.copyWith(color: textSecondary),
        ),
        value: isSelected,
        onChanged: (value) => _togglePermission(permission),
        activeColor: mainGreen,
        checkColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: Text('Quyền của ${widget.user.name ?? widget.user.email}'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _savePermissions,
              child: Text(
                'Lưu',
                style: body.copyWith(
                  color: mainGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin user
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(widget.user.roleColor).withOpacity(0.1),
                    child: Text(
                      widget.user.name?.substring(0, 1).toUpperCase() ?? 
                      widget.user.email.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
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
                          style: h4.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.email,
                          style: body.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 8),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Thống kê permissions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: mainGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mainGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: mainGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã chọn ${_selectedPermissions.length}/${Permission.values.length} quyền',
                      style: body.copyWith(
                        color: mainGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Các nhóm quyền
            _buildPermissionGroup('Sản phẩm', [
              Permission.viewProducts,
              Permission.addProducts,
              Permission.editProducts,
              Permission.deleteProducts,
            ]),
            
            _buildPermissionGroup('Khách hàng', [
              Permission.viewCustomers,
              Permission.addCustomers,
              Permission.editCustomers,
              Permission.deleteCustomers,
            ]),
            
            _buildPermissionGroup('Đơn hàng', [
              Permission.viewOrders,
              Permission.createOrders,
              Permission.editOrders,
              Permission.deleteOrders,
            ]),
            
            _buildPermissionGroup('Kiểm kê', [
              Permission.viewInventory,
              Permission.createInventory,
              Permission.editInventory,
              Permission.confirmInventory,
            ]),
            
            _buildPermissionGroup('Nhà cung cấp', [
              Permission.viewCompanies,
              Permission.addCompanies,
              Permission.editCompanies,
              Permission.deleteCompanies,
            ]),
            
            _buildPermissionGroup('Danh mục', [
              Permission.viewCategories,
              Permission.addCategories,
              Permission.editCategories,
              Permission.deleteCategories,
            ]),
            
            _buildPermissionGroup('Hệ thống', [
              Permission.viewSettings,
              Permission.editSettings,
              Permission.viewUsers,
              Permission.addUsers,
              Permission.editUsers,
              Permission.deleteUsers,
            ]),
            
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
            
            const SizedBox(height: 100), // Space for bottom
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _savePermissions,
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
                  'Lưu thay đổi',
                  style: body.copyWith(fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
} 