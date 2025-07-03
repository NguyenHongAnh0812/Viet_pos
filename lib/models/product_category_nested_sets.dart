import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCategoryNestedSets {
  final String id;
  final String name;
  final String description;
  final int left; // Left boundary
  final int right; // Right boundary
  final int level; // Hierarchy level
  final bool isSmart;
  final String? conditionType;
  final List<Map<String, dynamic>>? conditions;
  final Timestamp? createdAt;

  ProductCategoryNestedSets({
    required this.id,
    required this.name,
    this.description = '',
    required this.left,
    required this.right,
    required this.level,
    this.isSmart = false,
    this.conditionType,
    this.conditions,
    this.createdAt,
  });

  factory ProductCategoryNestedSets.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductCategoryNestedSets(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      left: data['left'] ?? 0,
      right: data['right'] ?? 0,
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
      'left': left,
      'right': right,
      'level': level,
      if (isSmart) 'is_smart': isSmart,
      if (conditionType != null) 'condition_type': conditionType,
      if (conditions != null) 'conditions': conditions,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  // Helper methods
  bool get isRoot => level == 0;
  bool get isLeaf => right == left + 1;
  int get width => right - left + 1;
  
  // Check if this category is ancestor of another
  bool isAncestorOf(ProductCategoryNestedSets other) {
    return left < other.left && right > other.right;
  }
  
  // Check if this category is descendant of another
  bool isDescendantOf(ProductCategoryNestedSets other) {
    return left > other.left && right < other.right;
  }
  
  // Check if this category is parent of another
  bool isParentOf(ProductCategoryNestedSets other) {
    return isAncestorOf(other) && level == other.level - 1;
  }
  
  // Check if this category is child of another
  bool isChildOf(ProductCategoryNestedSets other) {
    return isDescendantOf(other) && level == other.level + 1;
  }

  ProductCategoryNestedSets copyWith({
    String? id,
    String? name,
    String? description,
    int? left,
    int? right,
    int? level,
    bool? isSmart,
    String? conditionType,
    List<Map<String, dynamic>>? conditions,
    Timestamp? createdAt,
  }) {
    return ProductCategoryNestedSets(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      left: left ?? this.left,
      right: right ?? this.right,
      level: level ?? this.level,
      isSmart: isSmart ?? this.isSmart,
      conditionType: conditionType ?? this.conditionType,
      conditions: conditions ?? this.conditions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 