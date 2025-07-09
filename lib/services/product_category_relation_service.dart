import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_category_relation.dart';
import '../models/product_category.dart';

class ProductCategoryRelationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'product_categories';

  // Thêm mối quan hệ Product-Category
  Future<void> addProductCategory(ProductCategoryRelation relation) async {
    await _firestore.collection(_collection).add(relation.toMap());
  }

  // Thêm nhiều mối quan hệ cho một sản phẩm
  Future<void> addProductCategories(String productId, List<String> categoryIds) async {
    final batch = _firestore.batch();
    
    for (final categoryId in categoryIds) {
      final docRef = _firestore.collection(_collection).doc();
      final relation = ProductCategoryRelation(
        id: docRef.id,
        productId: productId,
        categoryId: categoryId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      batch.set(docRef, relation.toMap());
    }
    
    await batch.commit();
  }

  // Cập nhật mối quan hệ Product-Category
  Future<void> updateProductCategory(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Xóa mối quan hệ Product-Category
  Future<void> deleteProductCategory(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Xóa tất cả mối quan hệ của một sản phẩm
  Future<void> deleteProductCategories(String productId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('product_id', isEqualTo: productId)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Xóa tất cả mối quan hệ của một danh mục
  Future<void> deleteCategoryProducts(String categoryId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('category_id', isEqualTo: categoryId)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Xóa tất cả mối quan hệ của một danh mục (alias)
  Future<void> deleteProductCategoryByCategoryId(String categoryId) async {
    await deleteCategoryProducts(categoryId);
  }

  // Lấy tất cả mối quan hệ của một sản phẩm
  Stream<List<ProductCategoryRelation>> getProductCategories(String productId) {
    return _firestore
        .collection(_collection)
        .where('product_id', isEqualTo: productId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategoryRelation.fromFirestore(doc))
            .toList());
  }

  // Lấy tất cả mối quan hệ của một danh mục
  Stream<List<ProductCategoryRelation>> getCategoryProducts(String categoryId) {
    return _firestore
        .collection(_collection)
        .where('category_id', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategoryRelation.fromFirestore(doc))
            .toList());
  }

  // Lấy danh sách ID danh mục của một sản phẩm
  Future<List<String>> getCategoryIdsForProduct(String productId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('product_id', isEqualTo: productId)
        .get();
    
    return querySnapshot.docs
        .map((doc) => doc.data()['category_id'] as String)
        .toList();
  }

  // Lấy danh sách ID sản phẩm của một danh mục
  Future<List<String>> getProductIdsForCategory(String categoryId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('category_id', isEqualTo: categoryId)
        .get();
    
    return querySnapshot.docs
        .map((doc) => doc.data()['product_id'] as String)
        .toList();
  }

  // Cập nhật mối quan hệ cho một sản phẩm
  Future<void> updateProductCategories(String productId, List<String> categoryIds) async {
    // Xóa tất cả mối quan hệ cũ
    await deleteProductCategories(productId);
    
    // Thêm mối quan hệ mới
    if (categoryIds.isNotEmpty) {
      await addProductCategories(productId, categoryIds);
    }
  }

  // Xóa sản phẩm khỏi tất cả danh mục
  Future<void> removeProductFromAllCategories(String productId) async {
    await deleteProductCategories(productId);
  }

  // === HIERARCHICAL CATEGORY METHODS ===

  // Lấy tất cả parent categories của một category
  Future<List<String>> getAllParentCategoryIds(String categoryId) async {
    List<String> parentIds = [];
    String currentId = categoryId;
    
    while (currentId.isNotEmpty) {
      final categoryDoc = await _firestore.collection('categories').doc(currentId).get();
      if (categoryDoc.exists) {
        final data = categoryDoc.data() as Map<String, dynamic>;
        final parentId = data['parentId'] as String?;
        if (parentId != null && parentId.isNotEmpty) {
          parentIds.add(parentId);
          currentId = parentId;
        } else {
          break;
        }
      } else {
        break;
      }
    }
    
    return parentIds;
  }

  // Lấy tất cả child categories của một category
  Future<List<String>> getAllChildCategoryIds(String categoryId) async {
    List<String> childIds = [];
    
    final querySnapshot = await _firestore
        .collection('categories')
        .where('parentId', isEqualTo: categoryId)
        .get();
    
    for (final doc in querySnapshot.docs) {
      childIds.add(doc.id);
      // Recursively get children of children
      final grandChildren = await getAllChildCategoryIds(doc.id);
      childIds.addAll(grandChildren);
    }
    
    return childIds;
  }

  // Lấy tất cả sản phẩm trong một category và tất cả sub-categories
  Future<List<String>> getProductIdsForCategoryAndChildren(String categoryId) async {
    // Lấy tất cả child categories
    final childIds = await getAllChildCategoryIds(categoryId);
    final allCategoryIds = [categoryId, ...childIds];
    
    // Lấy tất cả sản phẩm trong các categories này
    List<String> allProductIds = [];
    for (final catId in allCategoryIds) {
      final productIds = await getProductIdsForCategory(catId);
      allProductIds.addAll(productIds);
    }
    
    // Remove duplicates
    return allProductIds.toSet().toList();
  }

  // Lấy category path (full hierarchy) cho một category
  Future<List<ProductCategory>> getCategoryPath(String categoryId) async {
    List<ProductCategory> path = [];
    String currentId = categoryId;
    
    while (currentId.isNotEmpty) {
      final categoryDoc = await _firestore.collection('categories').doc(currentId).get();
      if (categoryDoc.exists) {
        final category = ProductCategory.fromFirestore(categoryDoc);
        path.insert(0, category);
        currentId = category.parentId ?? '';
      } else {
        break;
      }
    }
    
    return path;
  }

  // Lấy category path string (ví dụ: "Thuốc > Vitamin > Vitamin B")
  Future<String> getCategoryPathString(String categoryId) async {
    final path = await getCategoryPath(categoryId);
    return path.map((cat) => cat.name).join(' > ');
  }

  // Lấy tất cả categories với hierarchy info
  Future<List<Map<String, dynamic>>> getCategoriesWithHierarchy() async {
    final categoriesSnapshot = await _firestore.collection('categories').get();
    final categories = categoriesSnapshot.docs.map((doc) => ProductCategory.fromFirestore(doc)).toList();
    
    List<Map<String, dynamic>> result = [];
    
    for (final category in categories) {
      final path = await getCategoryPath(category.id);
      final pathString = path.map((cat) => cat.name).join(' > ');
      
      result.add({
        'category': category,
        'path': path,
        'pathString': pathString,
        'level': path.length - 1, // 0 = root, 1 = first level, etc.
      });
    }
    
    // Sort by path string for proper hierarchy display
    result.sort((a, b) => (a['pathString'] as String).compareTo(b['pathString'] as String));
    
    return result;
  }
} 