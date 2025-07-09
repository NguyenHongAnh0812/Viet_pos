import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_category.dart';
import '../services/product_category_service.dart';
import 'package:flutter/foundation.dart';

class CategoryMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductCategoryService _categoryService = ProductCategoryService();

  /// Migration script để tính toán Materialized Path cho tất cả categories hiện có
  Future<void> migrateToMaterializedPath() async {
    print('=== BẮT ĐẦU MIGRATION MATERIALIZED PATH ===');
    
    try {
      // 1. Lấy tất cả categories hiện có
      final categoriesSnapshot = await _firestore.collection('categories').get();
      final categories = categoriesSnapshot.docs
          .map((doc) => ProductCategory.fromFirestore(doc))
          .toList();

      print('Tìm thấy ${categories.length} categories cần migration');

      // 2. Sắp xếp theo hierarchy (root categories trước)
      final sortedCategories = _sortCategoriesByHierarchy(categories);
      
      // 3. Tính toán path cho từng category
      int processedCount = 0;
      for (final category in sortedCategories) {
        if (category.path == null) {
          await _calculateAndUpdatePath(category);
          processedCount++;
          print('Đã xử lý: ${category.name} ($processedCount/${sortedCategories.length})');
        } else {
          print('Bỏ qua (đã có path): ${category.name}');
        }
      }

      print('=== MIGRATION HOÀN THÀNH ===');
      print('Đã xử lý: $processedCount categories');
      
    } catch (e) {
      print('Lỗi migration: $e');
      rethrow;
    }
  }

  /// Sắp xếp categories theo hierarchy (root trước, children sau)
  List<ProductCategory> _sortCategoriesByHierarchy(List<ProductCategory> categories) {
    List<ProductCategory> sorted = [];
    Set<String> processedIds = {};

    // Helper function để thêm category và children
    void addCategoryAndChildren(ProductCategory category) {
      if (processedIds.contains(category.id)) return;
      
      // Thêm category hiện tại
      sorted.add(category);
      processedIds.add(category.id);
      
      // Thêm tất cả children
      final children = categories.where((c) => c.parentId == category.id).toList();
      for (final child in children) {
        addCategoryAndChildren(child);
      }
    }

    // Bắt đầu với root categories
    final rootCategories = categories.where((c) => 
      c.parentId == null || c.parentId!.isEmpty
    ).toList();
    
    for (final root in rootCategories) {
      addCategoryAndChildren(root);
    }

    return sorted;
  }

  /// Tính toán và cập nhật path cho một category
  Future<void> _calculateAndUpdatePath(ProductCategory category) async {
    final pathData = await _calculatePath(category.parentId, category.name);
    
    await _firestore.collection('categories').doc(category.id).update({
      'path': pathData['path'],
      'pathArray': pathData['pathArray'],
      'level': pathData['level'],
    });
  }

  /// Tính toán path cho category
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
    final parentDoc = await _firestore.collection('categories').doc(parentId).get();
    if (!parentDoc.exists) {
      print('Warning: Parent category $parentId không tồn tại cho category $categoryName');
      // Fallback to root
      return {
        'path': '/$categoryName',
        'pathArray': [categoryName],
        'level': 0,
      };
    }

    final parentData = parentDoc.data()!;
    final parentPath = parentData['path'] as String?;
    final parentPathArray = parentData['pathArray'] as List<dynamic>?;
    final parentLevel = parentData['level'] as int?;

    if (parentPath == null || parentPathArray == null || parentLevel == null) {
      print('Warning: Parent category $parentId chưa có path, tính toán lại...');
      // Recursively calculate parent path first
      final parentName = parentData['name'] as String;
      final parentParentId = parentData['parentId'] as String?;
      final parentPathData = await _calculatePath(parentParentId, parentName);
      
      // Update parent first
      await _firestore.collection('categories').doc(parentId).update({
        'path': parentPathData['path'],
        'pathArray': parentPathData['pathArray'],
        'level': parentPathData['level'],
      });
      
      // Now calculate child path
      final newPath = '${parentPathData['path']}/$categoryName';
      final newPathArray = [...parentPathData['pathArray'].cast<String>(), categoryName];
      final newLevel = parentPathData['level'] + 1;

      return {
        'path': newPath,
        'pathArray': newPathArray,
        'level': newLevel,
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

  /// Kiểm tra migration status
  Future<Map<String, dynamic>> checkMigrationStatus() async {
    final categoriesSnapshot = await _firestore.collection('categories').get();
    final categories = categoriesSnapshot.docs
        .map((doc) => ProductCategory.fromFirestore(doc))
        .toList();

    int totalCategories = categories.length;
    int migratedCategories = categories.where((c) => c.path != null).length;
    int pendingCategories = totalCategories - migratedCategories;

    return {
      'total': totalCategories,
      'migrated': migratedCategories,
      'pending': pendingCategories,
      'percentage': totalCategories > 0 ? (migratedCategories / totalCategories * 100).round() : 0,
    };
  }

  /// Validate migration results
  Future<List<String>> validateMigration() async {
    List<String> errors = [];
    
    final categoriesSnapshot = await _firestore.collection('categories').get();
    final categories = categoriesSnapshot.docs
        .map((doc) => ProductCategory.fromFirestore(doc))
        .toList();

    for (final category in categories) {
      // Check if path is calculated
      if (category.path == null) {
        errors.add('Category "${category.name}" chưa có path');
        continue;
      }

      // Check if path matches parent
      if (category.parentId != null && category.parentId!.isNotEmpty) {
        final parentDoc = await _firestore.collection('categories').doc(category.parentId).get();
        if (parentDoc.exists) {
          final parentData = parentDoc.data()!;
          final parentPath = parentData['path'] as String?;
          
          if (parentPath != null && !category.path!.startsWith(parentPath)) {
            errors.add('Category "${category.name}" có path không khớp với parent');
          }
        }
      }

      // Check if level is correct
      if (category.pathArray != null) {
        final expectedLevel = category.pathArray!.length - 1;
        if (category.level != expectedLevel) {
          errors.add('Category "${category.name}" có level không đúng (expected: $expectedLevel, actual: ${category.level})');
        }
      }
    }

    return errors;
  }

  /// Rollback migration (xóa các trường path)
  Future<void> rollbackMigration() async {
    print('=== BẮT ĐẦU ROLLBACK MIGRATION ===');
    
    final categoriesSnapshot = await _firestore.collection('categories').get();
    final batch = _firestore.batch();
    
    for (final doc in categoriesSnapshot.docs) {
      batch.update(doc.reference, {
        'path': FieldValue.delete(),
        'pathArray': FieldValue.delete(),
        'level': FieldValue.delete(),
      });
    }
    
    await batch.commit();
    print('=== ROLLBACK HOÀN THÀNH ===');
  }
} 