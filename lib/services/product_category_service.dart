import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../screens/categories/product_category_detail_screen.dart'; // Import ProductCondition
import './product_service.dart';

class ProductCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';
  final _productService = ProductService();

  // === OPTIMIZED QUERIES WITH MATERIALIZED PATH ===

  Stream<List<ProductCategory>> getCategories() {
    return _firestore
        .collection(_collection)
        .orderBy('path', descending: false) // Natural hierarchy order
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => ProductCategory.fromFirestore(doc)).toList();
        });
  }

  // Get root categories only
  Stream<List<ProductCategory>> getRootCategories() {
    return _firestore
        .collection(_collection)
        .where('level', isEqualTo: 0)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromFirestore(doc))
            .toList());
  }

  // Get children of a category
  Stream<List<ProductCategory>> getChildren(String parentId) {
    return _firestore
        .collection(_collection)
        .where('parentId', isEqualTo: parentId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromFirestore(doc))
            .toList());
  }

  // Get all descendants of a category (using path prefix)
  Future<List<ProductCategory>> getDescendants(String categoryId) async {
    final categoryDoc = await _firestore.collection(_collection).doc(categoryId).get();
    if (!categoryDoc.exists) return [];

    final categoryPath = categoryDoc.data()!['path'] as String?;
    if (categoryPath == null) return [];

    final descendantsSnapshot = await _firestore
        .collection(_collection)
        .where('path', isGreaterThan: categoryPath)
        .where('path', isLessThan: '$categoryPath\uf8ff') // Unicode trick for prefix matching
        .get();

    return descendantsSnapshot.docs
        .map((doc) => ProductCategory.fromFirestore(doc))
        .toList();
  }

  // Get all ancestors of a category (using path array)
  Future<List<ProductCategory>> getAncestors(String categoryId) async {
    final categoryDoc = await _firestore.collection(_collection).doc(categoryId).get();
    if (!categoryDoc.exists) return [];

    final pathArray = categoryDoc.data()!['pathArray'] as List<dynamic>?;
    if (pathArray == null || pathArray.length <= 1) return []; // Root category has no ancestors

    // Get all categories in the path (excluding the current category)
    final ancestorNames = pathArray.sublist(0, pathArray.length - 1).cast<String>();
    
    final ancestorsSnapshot = await _firestore
        .collection(_collection)
        .where('name', whereIn: ancestorNames)
        .get();

    // Sort by level to maintain hierarchy order
    final ancestors = ancestorsSnapshot.docs
        .map((doc) => ProductCategory.fromFirestore(doc))
        .toList();
    
    ancestors.sort((a, b) => (a.level ?? 0).compareTo(b.level ?? 0));
    return ancestors;
  }

  // Get category path string (e.g., "Thuốc > Vitamin > Vitamin B")
  Future<String> getCategoryPathString(String categoryId) async {
    final categoryDoc = await _firestore.collection(_collection).doc(categoryId).get();
    if (!categoryDoc.exists) return '';

    final pathArray = categoryDoc.data()!['pathArray'] as List<dynamic>?;
    if (pathArray == null) return '';

    return pathArray.cast<String>().join(' > ');
  }

  // Search categories by name with hierarchy context
  Future<List<ProductCategory>> searchCategories(String searchTerm) async {
    final searchLower = searchTerm.toLowerCase();
    
    final snapshot = await _firestore.collection(_collection).get();
    final allCategories = snapshot.docs
        .map((doc) => ProductCategory.fromFirestore(doc))
        .toList();

    return allCategories.where((category) {
      // Search in name
      if (category.name.toLowerCase().contains(searchLower)) return true;
      
      // Search in path
      if (category.path != null && category.path!.toLowerCase().contains(searchLower)) return true;
      
      return false;
    }).toList();
  }

  // Get categories by level
  Stream<List<ProductCategory>> getCategoriesByLevel(int level) {
    return _firestore
        .collection(_collection)
        .where('level', isEqualTo: level)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromFirestore(doc))
            .toList());
  }

  // === PATH CALCULATION METHODS ===

  Future<Map<String, dynamic>> _calculatePath(String? parentId, String categoryName) async {
    if (parentId == null || parentId.isEmpty) {
      // Root category
      return {
        'path': '/$categoryName',
        'pathArray': [categoryName],
        'level': 0,
      };
    }

    // Get parent category
    final parentDoc = await _firestore.collection(_collection).doc(parentId).get();
    if (!parentDoc.exists) {
      throw Exception('Parent category not found');
    }

    final parentData = parentDoc.data()!;
    final parentPath = parentData['path'] as String?;
    final parentPathArray = parentData['pathArray'] as List<dynamic>?;
    final parentLevel = parentData['level'] as int?;

    if (parentPath == null || parentPathArray == null || parentLevel == null) {
      // Fallback to old method if path not calculated yet
      return {
        'path': '/$categoryName',
        'pathArray': [categoryName],
        'level': 0,
      };
    }

    final newPath = '$parentPath/$categoryName';
    final newPathArray = [...parentPathArray.cast<String>(), categoryName];
    final newLevel = parentLevel + 1;

    return {
      'path': newPath,
      'pathArray': newPathArray,
      'level': newLevel,
    };
  }

  // === CREATE CATEGORY WITH PATH CALCULATION ===

  Future<String> addCategory(ProductCategory category) async {
    // Calculate path and level
    final pathData = await _calculatePath(category.parentId, category.name);
    
    final categoryData = {
      'name': category.name,
      'description': category.description,
      if (category.parentId != null) 'parentId': category.parentId,
      'path': pathData['path'],
      'pathArray': pathData['pathArray'],
      'level': pathData['level'],
      'is_smart': category.isSmart,
      if (category.conditionType != null) 'condition_type': category.conditionType,
      if (category.conditions != null) 'conditions': category.conditions,
      'created_at': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore.collection(_collection).add(categoryData);
    
    // Update children paths if this category has children
    await _updateChildrenPaths(docRef.id, pathData['path']);
    
    return docRef.id; // Trả về ID của category vừa tạo
  }

  // === UPDATE CHILDREN PATHS ===

  Future<void> _updateChildrenPaths(String categoryId, String newParentPath) async {
    final childrenSnapshot = await _firestore
        .collection(_collection)
        .where('parentId', isEqualTo: categoryId)
        .get();

    final batch = _firestore.batch();
    
    for (final childDoc in childrenSnapshot.docs) {
      final childData = childDoc.data();
      final childName = childData['name'] as String;
      final childPathArray = childData['pathArray'] as List<dynamic>?;
      
      if (childPathArray != null) {
        // Update child path
        final newChildPath = '$newParentPath/$childName';
        final newChildLevel = childPathArray.length;
        
        batch.update(childDoc.reference, {
          'path': newChildPath,
          'level': newChildLevel,
        });
        
        // Recursively update grandchildren
        await _updateChildrenPaths(childDoc.id, newChildPath);
      }
    }
    
    await batch.commit();
  }

  // === UPDATE CATEGORY ===

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
    
    // Get current category data
    final categoryDoc = await _firestore.collection(_collection).doc(id).get();
    if (!categoryDoc.exists) throw Exception('Category not found');

    final currentData = categoryDoc.data()!;
    final oldParentId = currentData['parentId'] as String?;
    
    // Check if parent is changing
    bool parentChanged = (oldParentId != parentId);
    
    Map<String, dynamic> updateData = {
      'name': name,
      'description': description,
      'parentId': parentId,
      'is_smart': isSmart,
      'condition_type': isSmart ? conditionType : null,
      'conditions': isSmart ? conditions.map((c) => c.toMap()).toList() : [],
      'updated_at': FieldValue.serverTimestamp(),
    };

    // If parent is changing, recalculate path
    if (parentChanged) {
      final pathData = await _calculatePath(parentId, name);
      updateData['path'] = pathData['path'];
      updateData['pathArray'] = pathData['pathArray'];
      updateData['level'] = pathData['level'];
      
      // Update children paths
      await _updateChildrenPaths(id, pathData['path']);
    }

    // Update category
    final categoryRef = _firestore.collection('categories').doc(id);
    batch.update(categoryRef, updateData);

    // Handle product links (existing logic)
    final linksSnapshot = await _firestore.collection('product_category').where('category_id', isEqualTo: id).get();
    for (final doc in linksSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    List<String> productIdsToLink = [];
    if (isSmart) {
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

  // === UPDATE CATEGORY (SIMPLE VERSION) ===

  Future<void> updateCategorySimple(ProductCategory category) async {
    final batch = _firestore.batch();
    
    // Get current category data
    final categoryDoc = await _firestore.collection(_collection).doc(category.id).get();
    if (!categoryDoc.exists) throw Exception('Category not found');

    final currentData = categoryDoc.data()!;
    final oldParentId = currentData['parentId'] as String?;
    
    // Check if parent is changing
    bool parentChanged = (oldParentId != category.parentId);
    
    Map<String, dynamic> updateData = {
      'name': category.name,
      'description': category.description,
      'parentId': category.parentId,
      'updated_at': FieldValue.serverTimestamp(),
    };

    // If parent is changing, recalculate path
    if (parentChanged) {
      final pathData = await _calculatePath(category.parentId, category.name);
      updateData['path'] = pathData['path'];
      updateData['pathArray'] = pathData['pathArray'];
      updateData['level'] = pathData['level'];
      
      // Update children paths
      await _updateChildrenPaths(category.id, pathData['path']);
    }

    // Update category
    final categoryRef = _firestore.collection('categories').doc(category.id);
    batch.update(categoryRef, updateData);

    await batch.commit();
  }

  // === DELETE CATEGORY ===

  Future<void> deleteCategory(String id) async {
    final batch = _firestore.batch();

    // Get all descendants first
    final descendants = await getDescendants(id);
    
    // Delete descendants first
    for (final descendant in descendants) {
      batch.delete(_firestore.collection(_collection).doc(descendant.id));
    }
    
    // Delete the category itself
    final categoryRef = _firestore.collection('categories').doc(id);
    batch.delete(categoryRef);

    // Delete associated product links
    final linksSnapshot = await _firestore.collection('product_category').where('category_id', isEqualTo: id).get();
    for (final doc in linksSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // === MIGRATION HELPER ===

  // Calculate paths for existing categories
  Future<void> calculatePathsForExistingCategories() async {
    final categoriesSnapshot = await _firestore.collection(_collection).get();
    final categories = categoriesSnapshot.docs
        .map((doc) => ProductCategory.fromFirestore(doc))
        .toList();

    // Sort by level (root categories first)
    categories.sort((a, b) => (a.level ?? 0).compareTo(b.level ?? 0));

    for (final category in categories) {
      if (category.path == null) {
        // Calculate path for this category
        final pathData = await _calculatePath(category.parentId, category.name);
        
        await _firestore.collection(_collection).doc(category.id).update({
          'path': pathData['path'],
          'pathArray': pathData['pathArray'],
          'level': pathData['level'],
        });
      }
    }
  }

  // === LEGACY METHODS (for backward compatibility) ===

  Future<void> renameCategory(String oldName, String newName) async {
    final catDocs = await _firestore.collection(_collection).where('name', isEqualTo: oldName).get();
    for (final doc in catDocs.docs) {
      await doc.reference.update({'name': newName});
    }
    final prodDocs = await _firestore.collection('products').where('category', isEqualTo: oldName).get();
    for (final doc in prodDocs.docs) {
      await doc.reference.update({'category': newName});
    }
  }

  Future<void> syncCategoriesFromProducts() async {
    final prodDocs = await _firestore.collection('products').get();
    final productCategories = prodDocs.docs.map((d) => d['category']?.toString().trim()).where((c) => c != null && c.isNotEmpty).cast<String>().toSet();
    final catDocs = await _firestore.collection(_collection).get();
    final existingCategories = catDocs.docs.map((d) => d['name']?.toString().trim().toLowerCase()).where((c) => c != null && c.isNotEmpty).cast<String>().toSet();
    final missing = productCategories.where((c) => !existingCategories.contains(c.toLowerCase()));
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