import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCategoryOptimized {
  final String id;
  final String name;
  final String description;
  final String? parentId;
  final String path; // Materialized path: "/root/parent/child"
  final List<String> pathArray; // Array path: ["root", "parent", "child"]
  final int level; // Hierarchy level (0 = root, 1 = first level, etc.)
  final bool isSmart;
  final String? conditionType;
  final List<Map<String, dynamic>>? conditions;
  final Timestamp? createdAt;

  ProductCategoryOptimized({
    required this.id,
    required this.name,
    this.description = '',
    this.parentId,
    required this.path,
    required this.pathArray,
    required this.level,
    this.isSmart = false,
    this.conditionType,
    this.conditions,
    this.createdAt,
  });

  factory ProductCategoryOptimized.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductCategoryOptimized(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      parentId: data['parentId'],
      path: data['path'] ?? '',
      pathArray: List<String>.from(data['pathArray'] ?? []),
      level: data['level'] ?? 0,
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
      'path': path,
      'pathArray': pathArray,
      'level': level,
      if (isSmart) 'is_smart': isSmart,
      if (conditionType != null) 'condition_type': conditionType,
      if (conditions != null) 'conditions': conditions,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  // Helper methods
  bool get isRoot => level == 0;
  bool get hasChildren => path.isNotEmpty; // Will be updated by service
  
  // Get immediate parent name
  String? get parentName {
    if (pathArray.length > 1) {
      return pathArray[pathArray.length - 2];
    }
    return null;
  }

  // Get root category name
  String get rootName => pathArray.isNotEmpty ? pathArray.first : name;

  ProductCategoryOptimized copyWith({
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
    return ProductCategoryOptimized(
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