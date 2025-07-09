import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../widgets/common/design_system.dart';
import '../../widgets/main_layout.dart';
import 'add_user_screen.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _userService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  void _loadUsers() {
    _userService.getAllUsers().listen((users) {
      final userList = users.map((e) => e as User).toList();
      setState(() {
        _allUsers = userList;
        _filteredUsers = userList;
        _isLoading = false;
      });
    });
  }

  void _filterUsers(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredUsers = _allUsers;
      });
    } else {
      final lowercaseQuery = query.toLowerCase();
      setState(() {
        _filteredUsers = _allUsers.where((user) {
          return user.name?.toLowerCase().contains(lowercaseQuery) == true ||
              user.email.toLowerCase().contains(lowercaseQuery) ||
              user.roleDisplayName.toLowerCase().contains(lowercaseQuery);
        }).toList();
      });
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    try {
      await _userService.toggleUserStatus(user.id, !user.isActive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(user.isActive ? 'Đã vô hiệu hóa người dùng' : 'Đã kích hoạt người dùng'),
          backgroundColor: mainGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra'),
          backgroundColor: destructiveRed,
        ),
      );
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: destructiveRed),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.deleteUser(user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa người dùng'),
            backgroundColor: mainGreen,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi xóa người dùng'),
            backgroundColor: destructiveRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: const Text('Quản lý nhân viên'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentUser?.hasPermission(Permission.addUsers) == true)
            IconButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddUserScreen()),
                );
                if (result == true) {
                  // Refresh list
                }
              },
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm nhân viên...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: mainGreen, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: _filterUsers,
            ),
          ),
          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có nhân viên nào',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserCard(user, isMobile);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Color(user.roleColor).withOpacity(0.1),
          child: Text(
            user.name?.substring(0, 1).toUpperCase() ?? user.email.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Color(user.roleColor),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name ?? 'Chưa có tên',
          style: h3Mobile.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email, style: smallMobile.copyWith(color: textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(user.roleColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.roleDisplayName,
                    style: caption.copyWith(
                      color: Color(user.roleColor),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isActive ? mainGreen.withOpacity(0.1) : destructiveRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive ? 'Hoạt động' : 'Vô hiệu',
                    style: caption.copyWith(
                      color: user.isActive ? mainGreen : destructiveRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _currentUser?.hasPermission(Permission.editUsers) == true
            ? PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserDetailScreen(user: user),
                        ),
                      );
                      break;
                    case 'toggle':
                      await _toggleUserStatus(user);
                      break;
                    case 'delete':
                      if (_currentUser?.hasPermission(Permission.deleteUsers) == true) {
                        await _deleteUser(user);
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          user.isActive ? Icons.block : Icons.check_circle,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(user.isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
                      ],
                    ),
                  ),
                  if (_currentUser?.hasPermission(Permission.deleteUsers) == true)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: destructiveRed),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: destructiveRed)),
                        ],
                      ),
                    ),
                ],
              )
            : null,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(user: user),
            ),
          );
        },
      ),
    );
  }
} 