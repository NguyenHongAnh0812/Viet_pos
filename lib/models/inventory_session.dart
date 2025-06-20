import 'package:cloud_firestore/cloud_firestore.dart';

class InventorySession {
  final String id;
  final DateTime createdAt;
  final String createdBy;
  final String note;
  final List<InventoryProduct> products;
  final String status;

  InventorySession({
    required this.id,
    required this.createdAt,
    required this.createdBy,
    required this.note,
    required this.products,
    required this.status,
  });

  factory InventorySession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime createdAt;
    if (data['created_at'] is Timestamp) {
      createdAt = (data['created_at'] as Timestamp).toDate();
    } else if (data['created_at'] is DateTime) {
      createdAt = data['created_at'] as DateTime;
    } else if (data['created_at'] != null) {
      createdAt = DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return InventorySession(
      id: doc.id,
      createdAt: createdAt,
      createdBy: data['created_by'] ?? '',
      note: data['note'] ?? '',
      status: data['status'] ?? 'done',
      products: (data['products'] as List<dynamic>? ?? []).map((p) => InventoryProduct.fromMap(p)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'created_at': createdAt,
      'created_by': createdBy,
      'note': note,
      'status': status,
      'products': products.map((p) => p.toMap()).toList(),
    };
  }
}

class InventoryProduct {
  final String productId;
  final String name;
  final int systemQty;
  final int actualQty;
  final int diff;

  InventoryProduct({
    required this.productId,
    required this.name,
    required this.systemQty,
    required this.actualQty,
    required this.diff,
  });

  factory InventoryProduct.fromMap(Map<String, dynamic> map) {
    return InventoryProduct(
      productId: map['product_id'] ?? '',
      name: map['product_name'] ?? '',
      systemQty: map['stock_system'] ?? 0,
      actualQty: map['stock_actual'] ?? 0,
      diff: map['diff'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': name,
      'stock_system': systemQty,
      'stock_actual': actualQty,
      'diff': diff,
    };
  }
} 