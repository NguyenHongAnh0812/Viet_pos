import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,      // Chủ cửa hàng - toàn quyền
  employee,   // Nhân viên - quyền hạn chế
}

enum Permission {
  // Sản phẩm
  viewProducts,
  addProducts,
  editProducts,
  deleteProducts,
  
  // Khách hàng
  viewCustomers,
  addCustomers,
  editCustomers,
  deleteCustomers,
  
  // Đơn hàng
  viewOrders,
  createOrders,
  editOrders,
  deleteOrders,
  
  // Kiểm kê
  viewInventory,
  createInventory,
  editInventory,
  confirmInventory,
  
  // Công ty/Nhà cung cấp
  viewCompanies,
  addCompanies,
  editCompanies,
  deleteCompanies,
  
  // Danh mục
  viewCategories,
  addCategories,
  editCategories,
  deleteCategories,
  
  // Cài đặt
  viewSettings,
  editSettings,
  
  // Quản lý nhân viên
  viewUsers,
  addUsers,
  editUsers,
  deleteUsers,
}

class User {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? avatar;
  final UserRole role;
  final List<Permission> permissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  User({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.avatar,
    required this.role,
    required this.permissions,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    print('DEBUG: Firestore user data = ' + data.toString());
    print('DEBUG: data["role"] =  [36m${data['role']} [0m, type = ${data['role']?.runtimeType}');
    final String roleStr = (data['role'] ?? 'employee').toString().toLowerCase();
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      phone: data['phone'],
      avatar: data['avatar'],
      role: UserRole.values.firstWhere(
        (role) => role.name == roleStr,
        orElse: () => UserRole.employee,
      ),
      permissions: (data['permissions'] as List<dynamic>?)
          ?.map((p) => Permission.values.firstWhere(
                (perm) => perm.name == p,
                orElse: () => Permission.viewProducts,
              ))
          .toList() ?? getDefaultPermissions(roleStr),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'avatar': avatar,
      'role': role.name,
      'permissions': permissions.map((p) => p.name).toList(),
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? avatar,
    UserRole? role,
    List<Permission>? permissions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Kiểm tra quyền
  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }

  // Kiểm tra role
  bool hasRole(UserRole role) {
    return this.role == role;
  }

  // Lấy tên hiển thị của role
  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.employee:
        return 'Nhân viên';
    }
  }

  // Lấy màu của role
  int get roleColor {
    switch (role) {
      case UserRole.admin:
        return 0xFFDC2626; // Red
      case UserRole.employee:
        return 0xFF059669; // Green
    }
  }

  // Permissions mặc định cho từng role
  static List<Permission> getDefaultPermissions(String role) {
    switch (role) {
      case 'admin':
        return Permission.values; // Tất cả quyền
      case 'employee':
        return [
          Permission.viewProducts,
          Permission.viewCustomers,
          Permission.addCustomers,
          Permission.editCustomers,
          Permission.viewOrders,
          Permission.createOrders,
          Permission.editOrders,
          Permission.viewInventory,
          Permission.createInventory,
          Permission.editInventory,
          Permission.viewCompanies,
          Permission.viewCategories,
        ];
      default:
        return [Permission.viewProducts];
    }
  }
} 