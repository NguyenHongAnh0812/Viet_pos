import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../widgets/common/design_system.dart';
import 'user_permissions_screen.dart';

class PermissionsOverviewScreen extends StatefulWidget {
  const PermissionsOverviewScreen({super.key});

  @override
  State<PermissionsOverviewScreen> createState() => _PermissionsOverviewScreenState();
}

class _PermissionsOverviewScreenState extends State<PermissionsOverviewScreen> {
  final UserService _userService = UserService();
  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _userService.getAllUsers().listen((users) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    });
  }

  List<User> get _filteredUsers {
    if (_searchQuery.trim().isEmpty) {
      return _users;
    }
    final query = _searchQuery.toLowerCase();
    return _users.where((user) {
      return user.name?.toLowerCase().contains(query) == true ||
          user.email.toLowerCase().contains(query) ||
          user.roleDisplayName.toLowerCase().contains(query);
    }).toList();
  }

  String _getPermissionSummary(User user) {
    final totalPermissions = Permission.values.length;
    final userPermissions = user.permissions.length;
    return '$userPermissions/$totalPermissions quyền';
  }

  List<String> _getTopPermissions(User user) {
    final permissions = user.permissions.take(3).map((p) => p.name.replaceAll('_', ' ').toUpperCase()).toList();
    if (permissions.length < 3) {
      permissions.addAll(List.filled(3 - permissions.length, ''));
    }
    return permissions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: const Text('Quản lý phân quyền'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: designSystemInputDecoration(
                label: 'Tìm kiếm nhân viên',
                prefixIcon: const Icon(Icons.search),
                hint: 'Nhập tên hoặc email...',
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text('Không tìm thấy nhân viên nào'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final topPermissions = _getTopPermissions(user);
    
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
                    color: mainGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPermissionSummary(user),
                    style: caption.copyWith(
                      color: mainGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Top permissions
            Wrap(
              spacing: 4,
              children: topPermissions.where((p) => p.isNotEmpty).map((permission) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    permission,
                    style: caption.copyWith(
                      color: textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.security, color: mainGreen),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserPermissionsScreen(user: user),
              ),
            );
          },
          tooltip: 'Chỉnh sửa quyền',
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserPermissionsScreen(user: user),
            ),
          );
        },
      ),
    );
  }
} 