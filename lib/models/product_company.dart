import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCompany {
  final String id;
  final String productId;
  final String companyId;
  final bool isPrimary; // Công ty chính
  final double? price; // Giá từ công ty này
  final String? notes; // Ghi chú
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductCompany({
    required this.id,
    required this.productId,
    required this.companyId,
    this.isPrimary = false,
    this.price,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'company_id': companyId,
      'is_primary': isPrimary,
      'price': price,
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  factory ProductCompany.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductCompany(
      id: doc.id,
      productId: data['product_id'] ?? '',
      companyId: data['company_id'] ?? '',
      isPrimary: data['is_primary'] ?? false,
      price: data['price']?.toDouble(),
      notes: data['notes'],
      createdAt: (data['created_at'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updated_at'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  ProductCompany copyWith({
    String? id,
    String? productId,
    String? companyId,
    bool? isPrimary,
    double? price,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductCompany(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      companyId: companyId ?? this.companyId,
      isPrimary: isPrimary ?? this.isPrimary,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 