import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCategory {
  final String id;
  final String name;
  final String description;
  final String? parentId;
  final String? path; // Materialized path: "/Thuốc/Vitamin/Vitamin B"
  final List<String>? pathArray; // Array path: ["Thuốc", "Vitamin", "Vitamin B"]
  final int? level; // Hierarchy level (0 = root, 1 = first level, etc.)
  final bool isSmart;
  final String? conditionType;
  final List<Map<String, dynamic>>? conditions;
  final Timestamp? createdAt;

  ProductCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.parentId,
    this.path,
    this.pathArray,
    this.level,
    this.isSmart = false,
    this.conditionType,
    this.conditions,
    this.createdAt,
  });

  factory ProductCategory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    int? levelValue;
    if (data['level'] is int) {
      levelValue = data['level'];
    } else if (data['level'] != null) {
      levelValue = int.tryParse(data['level'].toString());
    }
    return ProductCategory(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      parentId: data['parentId'],
      path: data['path'],
      pathArray: data['pathArray'] != null 
          ? List<String>.from(data['pathArray']) 
          : null,
      level: levelValue,
      isSmart: data['is_smart'] ?? false,
      conditionType: data['condition_type'],
      conditions: List<Map<String, dynamic>>.from(data['conditions'] ?? []),
      createdAt: data['created_at'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      if (parentId != null) 'parentId': parentId,
      if (path != null) 'path': path,
      if (pathArray != null) 'pathArray': pathArray,
      if (level != null) 'level': level,
      if (isSmart) 'is_smart': isSmart,
      if (conditionType != null) 'condition_type': conditionType,
      if (conditions != null) 'conditions': conditions,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  // Helper methods for hierarchy
  bool get isRoot => level == 0 || (parentId == null || parentId!.isEmpty);
  bool get hasPath => path != null && path!.isNotEmpty;
  
  // Get immediate parent name from path
  String? get parentName {
    if (pathArray != null && pathArray!.length > 1) {
      return pathArray![pathArray!.length - 2];
    }
    return null;
  }

  // Get root category name
  String get rootName {
    if (pathArray != null && pathArray!.isNotEmpty) {
      return pathArray!.first;
    }
    return name;
  }

  // Get full path string (e.g., "Thuốc > Vitamin > Vitamin B")
  String get pathString {
    if (pathArray != null && pathArray!.isNotEmpty) {
      return pathArray!.join(' > ');
    }
    return name;
  }

  // Check if this category is ancestor of another
  bool isAncestorOf(ProductCategory other) {
    if (path == null || other.path == null) return false;
    return other.path!.startsWith(path!) && path != other.path;
  }

  // Check if this category is descendant of another
  bool isDescendantOf(ProductCategory other) {
    if (path == null || other.path == null) return false;
    return path!.startsWith(other.path!) && path != other.path;
  }

  // Check if this category is parent of another
  bool isParentOf(ProductCategory other) {
    return other.parentId == id;
  }

  // Check if this category is child of another
  bool isChildOf(ProductCategory other) {
    return parentId == other.id;
  }

  ProductCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? parentId,
    String? path,
    List<String>? pathArray,
    int? level,
    bool? isSmart,
    String? conditionType,
    List<Map<String, dynamic>>? conditions,
    Timestamp? createdAt,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      path: path ?? this.path,
      pathArray: pathArray ?? this.pathArray,
      level: level ?? this.level,
      isSmart: isSmart ?? this.isSmart,
      conditionType: conditionType ?? this.conditionType,
      conditions: conditions ?? this.conditions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 