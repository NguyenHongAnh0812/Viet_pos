import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCategoryRelation {
  final String id;
  final String productId;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductCategoryRelation({
    required this.id,
    required this.productId,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'category_id': categoryId,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  factory ProductCategoryRelation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductCategoryRelation(
      id: doc.id,
      productId: data['product_id'] ?? '',
      categoryId: data['category_id'] ?? '',
      createdAt: (data['created_at'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updated_at'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  ProductCategoryRelation copyWith({
    String? id,
    String? productId,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductCategoryRelation(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 