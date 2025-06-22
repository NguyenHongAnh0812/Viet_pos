import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_category_optimized.dart';

class ProductCategoryOptimizedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories_optimized';

  // === CREATE CATEGORY WITH PATH CALCULATION ===
  Future<String> addCategory(ProductCategoryOptimized category) async {
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
    
    return docRef.id;
  }

  // === PATH CALCULATION ===
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
    final parentPath = parentData['path'] as String;
    final parentPathArray = List<String>.from(parentData['pathArray']);
    final parentLevel = parentData['level'] as int;

    final newPath = '$parentPath/$categoryName';
    final newPathArray = [...parentPathArray, categoryName];
    final newLevel = parentLevel + 1;

    return {
      'path': newPath,
      'pathArray': newPathArray,
      'level': newLevel,
    };
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
      final childPathArray = List<String>.from(childData['pathArray']);
      
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
    
    await batch.commit();
  }

  // === OPTIMIZED QUERIES ===

  // Get all categories with hierarchy info
  Stream<List<ProductCategoryOptimized>> getCategories() {
    return _firestore
        .collection(_collection)
        .orderBy('path') // Natural hierarchy order
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategoryOptimized.fromFirestore(doc))
            .toList());
  }

  // Get root categories only
  Stream<List<ProductCategoryOptimized>> getRootCategories() {
    return _firestore
        .collection(_collection)
        .where('level', isEqualTo: 0)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategoryOptimized.fromFirestore(doc))
            .toList());
  }

  // Get children of a category
  Stream<List<ProductCategoryOptimized>> getChildren(String parentId) {
    return _firestore
        .collection(_collection)
        .where('parentId', isEqualTo: parentId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategoryOptimized.fromFirestore(doc))
            .toList());
  }

  // Get all descendants of a category (using path prefix)
  Future<List<ProductCategoryOptimized>> getDescendants(String categoryId) async {
    final categoryDoc = await _firestore.collection(_collection).doc(categoryId).get();
    if (!categoryDoc.exists) return [];

    final categoryPath = categoryDoc.data()!['path'] as String;
    
    final descendantsSnapshot = await _firestore
        .collection(_collection)
        .where('path', isGreaterThan: categoryPath)
        .where('path', isLessThan: '$categoryPath\uf8ff') // Unicode trick for prefix matching
        .get();

    return descendantsSnapshot.docs
        .map((doc) => ProductCategoryOptimized.fromFirestore(doc))
        .toList();
  }

  // Get all ancestors of a category (using path array)
  Future<List<ProductCategoryOptimized>> getAncestors(String categoryId) async {
    final categoryDoc = await _firestore.collection(_collection).doc(categoryId).get();
    if (!categoryDoc.exists) return [];

    final pathArray = List<String>.from(categoryDoc.data()!['pathArray']);
    if (pathArray.length <= 1) return []; // Root category has no ancestors

    // Get all categories in the path (excluding the current category)
    final ancestorNames = pathArray.sublist(0, pathArray.length - 1);
    
    final ancestorsSnapshot = await _firestore
        .collection(_collection)
        .where('name', whereIn: ancestorNames)
        .get();

    // Sort by level to maintain hierarchy order
    final ancestors = ancestorsSnapshot.docs
        .map((doc) => ProductCategoryOptimized.fromFirestore(doc))
        .toList();
    
    ancestors.sort((a, b) => a.level.compareTo(b.level));
    return ancestors;
  }

  // Get category path string (e.g., "Thuốc > Vitamin > Vitamin B")
  Future<String> getCategoryPathString(String categoryId) async {
    final categoryDoc = await _firestore.collection(_collection).doc(categoryId).get();
    if (!categoryDoc.exists) return '';

    final pathArray = List<String>.from(categoryDoc.data()!['pathArray']);
    return pathArray.join(' > ');
  }

  // Search categories by name with hierarchy context
  Future<List<ProductCategoryOptimized>> searchCategories(String searchTerm) async {
    final searchLower = searchTerm.toLowerCase();
    
    final snapshot = await _firestore.collection(_collection).get();
    final allCategories = snapshot.docs
        .map((doc) => ProductCategoryOptimized.fromFirestore(doc))
        .toList();

    return allCategories.where((category) {
      // Search in name
      if (category.name.toLowerCase().contains(searchLower)) return true;
      
      // Search in path
      if (category.path.toLowerCase().contains(searchLower)) return true;
      
      return false;
    }).toList();
  }

  // Get categories by level
  Stream<List<ProductCategoryOptimized>> getCategoriesByLevel(int level) {
    return _firestore
        .collection(_collection)
        .where('level', isEqualTo: level)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategoryOptimized.fromFirestore(doc))
            .toList());
  }

  // === UPDATE CATEGORY ===
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    final categoryDoc = await _firestore.collection(_collection).doc(id).get();
    if (!categoryDoc.exists) throw Exception('Category not found');

    final currentData = categoryDoc.data()!;
    final oldPath = currentData['path'] as String;
    
    // If parent is changing, recalculate path
    if (data.containsKey('parentId') && data['parentId'] != currentData['parentId']) {
      final newPathData = await _calculatePath(data['parentId'], data['name'] ?? currentData['name']);
      data['path'] = newPathData['path'];
      data['pathArray'] = newPathData['pathArray'];
      data['level'] = newPathData['level'];
      
      // Update children paths
      await _updateChildrenPaths(id, newPathData['path']);
    }

    await _firestore.collection(_collection).doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // === DELETE CATEGORY ===
  Future<void> deleteCategory(String id) async {
    final batch = _firestore.batch();
    
    // Get all descendants
    final descendants = await getDescendants(id);
    
    // Delete descendants first
    for (final descendant in descendants) {
      batch.delete(_firestore.collection(_collection).doc(descendant.id));
    }
    
    // Delete the category itself
    batch.delete(_firestore.collection(_collection).doc(id));
    
    await batch.commit();
  }

  // === MIGRATION HELPER ===
  // Convert existing categories to optimized format
  Future<void> migrateExistingCategories() async {
    final oldCategoriesSnapshot = await _firestore.collection('categories').get();
    
    for (final oldDoc in oldCategoriesSnapshot.docs) {
      final oldData = oldDoc.data();
      final parentId = oldData['parentId'] as String?;
      final name = oldData['name'] as String;
      
      // Calculate new path
      final pathData = await _calculatePath(parentId, name);
      
      // Create optimized category
      final optimizedData = {
        'name': name,
        'description': oldData['description'] ?? '',
        if (parentId != null) 'parentId': parentId,
        'path': pathData['path'],
        'pathArray': pathData['pathArray'],
        'level': pathData['level'],
        'is_smart': oldData['is_smart'] ?? false,
        if (oldData['condition_type'] != null) 'condition_type': oldData['condition_type'],
        if (oldData['conditions'] != null) 'conditions': oldData['conditions'],
        'created_at': oldData['created_at'],
      };
      
      await _firestore.collection(_collection).add(optimizedData);
    }
  }
} 