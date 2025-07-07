import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_category_optimized.dart';

class ProductCategoryOptimizedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all categories with optimized query
  Future<List<ProductCategoryOptimized>> getAllCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .orderBy('path')
        .get();
    
    return snapshot.docs
        .map((doc) => ProductCategoryOptimized.fromFirestore(doc))
        .toList();
  }

  // Get descendants using path query (much faster)
  Future<List<ProductCategoryOptimized>> getDescendants(String categoryId) async {
    final category = await getCategoryById(categoryId);
    if (category == null) return [];
    
    final snapshot = await _firestore
        .collection('categories')
        .where('path', isGreaterThan: category.path)
        .where('path', isLessThan: '${category.path}\\uf8ff')
        .orderBy('path')
        .get();
    
    return snapshot.docs
        .map((doc) => ProductCategoryOptimized.fromFirestore(doc))
        .toList();
  }

  // Get ancestors using path array (much faster)
  Future<List<ProductCategoryOptimized>> getAncestors(String categoryId) async {
    final category = await getCategoryById(categoryId);
    if (category == null) return [];
    
    if (category.pathArray.isEmpty) return [];
    
    final ancestorNames = category.pathArray.sublist(0, category.pathArray.length - 1);
    
    final snapshot = await _firestore
        .collection('categories')
        .where('name', whereIn: ancestorNames)
        .get();
    
    return snapshot.docs
        .map((doc) => ProductCategoryOptimized.fromFirestore(doc))
        .toList();
  }

  // Get category by ID
  Future<ProductCategoryOptimized?> getCategoryById(String id) async {
    final doc = await _firestore.collection('categories').doc(id).get();
    if (!doc.exists) return null;
    return ProductCategoryOptimized.fromFirestore(doc);
  }

  // Create category with optimized path
  Future<void> createCategory(ProductCategoryOptimized category) async {
    await _firestore.collection('categories').doc(category.id).set(category.toMap());
  }

  // Update category path when parent changes
  Future<void> updateCategoryPath(String categoryId, String newParentId) async {
    final category = await getCategoryById(categoryId);
    if (category == null) return;
    
    final newParent = newParentId.isNotEmpty ? await getCategoryById(newParentId) : null;
    final newPath = newParent != null ? '${newParent.path}/${category.name}' : category.name;
    final newPathArray = newParent != null ? [...newParent.pathArray, category.name] : [category.name];
    final newLevel = newParent != null ? newParent.level + 1 : 0;
    
    await _firestore.collection('categories').doc(categoryId).update({
      'path': newPath,
      'pathArray': newPathArray,
      'level': newLevel,
      'parentId': newParentId.isEmpty ? null : newParentId,
    });
    
    // Update all descendants
    final descendants = await getDescendants(categoryId);
    for (final descendant in descendants) {
      final descendantNewPath = '$newPath/${descendant.name}';
      final descendantNewPathArray = [...newPathArray, descendant.name];
      final descendantNewLevel = newLevel + 1;
      
      await _firestore.collection('categories').doc(descendant.id).update({
        'path': descendantNewPath,
        'pathArray': descendantNewPathArray,
        'level': descendantNewLevel,
      });
    }
  }
}
