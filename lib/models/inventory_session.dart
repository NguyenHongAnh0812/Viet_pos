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
    return InventorySession(
      id: doc.id,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      note: data['note'] ?? '',
      status: data['status'] ?? 'done',
      products: (data['products'] as List<dynamic>? ?? []).map((p) => InventoryProduct.fromMap(p)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'createdBy': createdBy,
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
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      systemQty: map['systemQty'] ?? 0,
      actualQty: map['actualQty'] ?? 0,
      diff: map['diff'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'systemQty': systemQty,
      'actualQty': actualQty,
      'diff': diff,
    };
  }
} 