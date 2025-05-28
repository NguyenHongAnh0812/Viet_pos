import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_category.dart';
import '../services/product_service.dart';

class ProductCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';
  final _productService = ProductService();

  Stream<List<ProductCategory>> getCategories() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductCategory.fromFirestore(doc)).toList();
    });
  }

  Future<void> addCategory(ProductCategory category) async {
    await _firestore.collection(_collection).add({
      'name': category.name,
      'description': category.description,
    });
  }

  Future<void> deleteCategory(String categoryName) async {
    // Xóa danh mục
    final catDocs = await _firestore.collection(_collection).where('name', isEqualTo: categoryName).get();
    for (final doc in catDocs.docs) {
      await doc.reference.delete();
    }
    // Cập nhật tất cả sản phẩm có category này về 'Khác'
    final prodDocs = await _firestore.collection('products').where('category', isEqualTo: categoryName).get();
    for (final doc in prodDocs.docs) {
      await doc.reference.update({'category': 'Khác'});
    }
  }

  Future<void> renameCategory(String oldName, String newName) async {
    // Đổi tên danh mục
    final catDocs = await _firestore.collection(_collection).where('name', isEqualTo: oldName).get();
    for (final doc in catDocs.docs) {
      await doc.reference.update({'name': newName});
    }
    // Cập nhật tất cả sản phẩm có category cũ sang tên mới
    final prodDocs = await _firestore.collection('products').where('category', isEqualTo: oldName).get();
    for (final doc in prodDocs.docs) {
      await doc.reference.update({'category': newName});
    }
  }

  Future<void> syncCategoriesFromProducts() async {
    // Lấy tất cả category từ sản phẩm
    final prodDocs = await _firestore.collection('products').get();
    final productCategories = prodDocs.docs.map((d) => d['category']?.toString().trim()).where((c) => c != null && c!.isNotEmpty).cast<String>().toSet();
    // Lấy tất cả danh mục chuẩn
    final catDocs = await _firestore.collection(_collection).get();
    final existingCategories = catDocs.docs.map((d) => d['name']?.toString().trim().toLowerCase()).where((c) => c != null && c!.isNotEmpty).cast<String>().toSet();
    // Tìm các category còn thiếu
    final missing = productCategories.where((c) => !existingCategories.contains(c.toLowerCase()));
    // Thêm vào collection chuẩn
    for (final name in missing) {
      await _firestore.collection(_collection).add({'name': name, 'description': ''});
    }
  }
} 