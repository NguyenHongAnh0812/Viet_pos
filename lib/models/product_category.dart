import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCategory {
  final String id;
  final String name;
  final String description;
  final String? parentId;
  final bool isSmart;
  final String? conditionType;
  final List<Map<String, dynamic>>? conditions;

  ProductCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.parentId,
    this.isSmart = false,
    this.conditionType,
    this.conditions,
  });

  factory ProductCategory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductCategory(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      parentId: data['parentId'],
      isSmart: data['is_smart'] ?? false,
      conditionType: data['condition_type'],
      conditions: List<Map<String, dynamic>>.from(data['conditions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      if (parentId != null) 'parentId': parentId,
    };
  }

  ProductCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? parentId,
    bool? isSmart,
    String? conditionType,
    List<Map<String, dynamic>>? conditions,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      isSmart: isSmart ?? this.isSmart,
      conditionType: conditionType ?? this.conditionType,
      conditions: conditions ?? this.conditions,
    );
  }
} 