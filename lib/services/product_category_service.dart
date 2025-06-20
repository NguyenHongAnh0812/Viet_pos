import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../screens/product_category_detail_screen.dart'; // Import ProductCondition
import './product_service.dart';

class ProductCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';
  final _productService = ProductService();

  Stream<List<ProductCategory>> getCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductCategory.fromFirestore(doc)).toList();
    });
  }

  Future<void> addCategory(ProductCategory category) async {
    await _firestore.collection(_collection).add({
      'name': category.name,
      'description': category.description,
      if (category.parentId != null) 'parentId': category.parentId,
    });
  }

  Future<void> updateCategory(
    String id,
    String name,
    String description,
    String? parentId,
    bool isSmart,
    List<ProductCondition> conditions,
    String conditionType,
    List<String>? manualProductIds,
  ) async {
    final batch = _firestore.batch();
    
    // 1. Update category data
    final categoryRef = _firestore.collection('categories').doc(id);
    batch.update(categoryRef, {
      'name': name,
      'description': description,
      'parentId': parentId,
      'is_smart': isSmart,
      'condition_type': isSmart ? conditionType : null,
      'conditions': isSmart ? conditions.map((c) => c.toMap()).toList() : [],
      'updated_at': FieldValue.serverTimestamp(),
    });

    // 2. Clear existing product links for this category
    final linksSnapshot = await _firestore.collection('product_category').where('category_id', isEqualTo: id).get();
    for (final doc in linksSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // 3. Add new product links
    List<String> productIdsToLink = [];
    if (isSmart) {
      // Smart mode: evaluate conditions
      final productService = ProductService();
      final allProducts = await productService.getProducts().first;
      productIdsToLink = allProducts
          .where((p) {
            if (conditions.isEmpty) return false;
            if (conditionType == 'all') {
              return conditions.every((cond) => cond.evaluate(p));
            } else {
              return conditions.any((cond) => cond.evaluate(p));
    }
          })
          .map((p) => p.id)
          .toList();
    } else {
      // Manual mode
      productIdsToLink = manualProductIds ?? [];
    }

    for (final productId in productIdsToLink) {
      final linkRef = _firestore.collection('product_category').doc();
      batch.set(linkRef, {
        'product_id': productId,
        'category_id': id,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> deleteCategory(String id) async {
    final batch = _firestore.batch();

    // Delete category
    final categoryRef = _firestore.collection('categories').doc(id);
    batch.delete(categoryRef);

    // Delete associated product links
    final linksSnapshot = await _firestore.collection('product_category').where('category_id', isEqualTo: id).get();
    for (final doc in linksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // TODO: Handle children categories. For now, they become orphans.
    
    await batch.commit();
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
    final productCategories = prodDocs.docs.map((d) => d['category']?.toString().trim()).where((c) => c != null && c.isNotEmpty).cast<String>().toSet();
    // Lấy tất cả danh mục chuẩn
    final catDocs = await _firestore.collection(_collection).get();
    final existingCategories = catDocs.docs.map((d) => d['name']?.toString().trim().toLowerCase()).where((c) => c != null && c.isNotEmpty).cast<String>().toSet();
    // Tìm các category còn thiếu
    final missing = productCategories.where((c) => !existingCategories.contains(c.toLowerCase()));
    // Thêm vào collection chuẩn
    for (final name in missing) {
      await _firestore.collection(_collection).add({'name': name, 'description': ''});
    }
  }
}

class ProductCategoryLinkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'product_category';

  Future<void> addProductToCategory({required String productId, required String categoryId}) async {
    await _firestore.collection(_collection).add({
      'product_id': productId,
      'category_id': categoryId,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeProductFromCategory({required String productId, required String categoryId}) async {
    final query = await _firestore.collection(_collection)
      .where('product_id', isEqualTo: productId)
      .where('category_id', isEqualTo: categoryId)
      .get();
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  Future<List<String>> getProductIdsByCategory(String categoryId) async {
    final query = await _firestore.collection(_collection)
      .where('category_id', isEqualTo: categoryId)
      .get();
    return query.docs.map((doc) => doc['product_id'] as String).toList();
  }

  Future<List<String>> getCategoryIdsByProduct(String productId) async {
    final query = await _firestore.collection(_collection)
      .where('product_id', isEqualTo: productId)
      .get();
    return query.docs.map((doc) => doc['category_id'] as String).toList();
  }
} 