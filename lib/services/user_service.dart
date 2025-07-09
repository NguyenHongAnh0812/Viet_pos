import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final String _collection = 'users';

  // Lấy user hiện tại từ Firestore
  Future<User?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final doc = await _firestore.collection(_collection).doc(firebaseUser.uid).get();
      if (!doc.exists) return null;
      return User.fromFirestore(doc);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Stream user hiện tại
  Stream<User?> getCurrentUserStream() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return Stream.value(null);

    return _firestore
        .collection(_collection)
        .doc(firebaseUser.uid)
        .snapshots()
        .map((doc) => doc.exists ? User.fromFirestore(doc) : null);
  }

  // Lấy tất cả users (chỉ admin mới được)
  Stream<List<User>> getAllUsers() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => User.fromFirestore(doc))
            .toList());
  }

  // Tạo user mới
  Future<void> createUser(User user) async {
    await _firestore.collection(_collection).doc(user.id).set(user.toMap());
  }

  // Cập nhật user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(userId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Xóa user
  Future<void> deleteUser(String userId) async {
    await _firestore.collection(_collection).doc(userId).delete();
  }

  // Tạo user từ Firebase Auth
  Future<User?> createUserFromAuth(fb_auth.UserCredential credential, {
    String? name,
    UserRole role = UserRole.employee,
  }) async {
    final firebaseUser = credential.user;
    if (firebaseUser == null) return null;

    final user = User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: name,
      role: role,
      permissions: User.getDefaultPermissions(role.name),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await createUser(user);
      return user;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  // Kiểm tra quyền của user hiện tại
  Future<bool> hasPermission(Permission permission) async {
    final user = await getCurrentUser();
    return user?.hasPermission(permission) ?? false;
  }

  // Kiểm tra role của user hiện tại
  Future<bool> hasRole(UserRole role) async {
    final user = await getCurrentUser();
    return user?.hasRole(role) ?? false;
  }

  // Đăng ký user mới
  Future<User?> registerUser({
    required String email,
    required String password,
    String? name,
    UserRole role = UserRole.employee,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return await createUserFromAuth(credential, name: name, role: role);
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  // Đăng nhập
  Future<User?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await getCurrentUser();
    } catch (e) {
      print('Error signing in user: $e');
      return null;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Kiểm tra user có tồn tại không
  Future<bool> userExists(String email) async {
    final query = await _firestore
        .collection(_collection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // Lấy user theo ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return null;
      return User.fromFirestore(doc);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Cập nhật permissions cho user
  Future<void> updateUserPermissions(String userId, List<Permission> permissions) async {
    await updateUser(userId, {
      'permissions': permissions.map((p) => p.name).toList(),
    });
  }

  // Cập nhật role cho user
  Future<void> updateUserRole(String userId, UserRole role) async {
    await updateUser(userId, {
      'role': role.name,
      'permissions': User.getDefaultPermissions(role.name).map((p) => p.name).toList(),
    });
  }

  // Kích hoạt/vô hiệu hóa user
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    await updateUser(userId, {
      'isActive': isActive,
    });
  }

  // Kiểm tra xem có user nào trong hệ thống không
  Future<bool> hasAnyUsers() async {
    try {
      final snapshot = await _firestore.collection(_collection).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if users exist: $e');
      return false;
    }
  }

  // Kiểm tra xem có admin nào trong hệ thống không
  Future<bool> hasAnyAdmins() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if admins exist: $e');
      return false;
    }
  }

  // Xóa tất cả users (chỉ dùng cho testing)
  Future<void> clearAllUsers() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print('DEBUG: Cleared all users');
    } catch (e) {
      print('Error clearing users: $e');
    }
  }
} 