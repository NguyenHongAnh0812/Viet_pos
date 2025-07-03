import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double discountAmount;
  final bool isPercentageDiscount;
  final double finalPrice;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.discountAmount,
    required this.isPercentageDiscount,
    required this.finalPrice,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime createdAt;
    DateTime updatedAt;
    
    if (data['created_at'] is Timestamp) {
      createdAt = (data['created_at'] as Timestamp).toDate();
    } else if (data['created_at'] is DateTime) {
      createdAt = data['created_at'] as DateTime;
    } else {
      createdAt = DateTime.now();
    }
    
    if (data['updated_at'] is Timestamp) {
      updatedAt = (data['updated_at'] as Timestamp).toDate();
    } else if (data['updated_at'] is DateTime) {
      updatedAt = data['updated_at'] as DateTime;
    } else {
      updatedAt = DateTime.now();
    }

    return OrderItem(
      id: doc.id,
      orderId: data['order_id'] ?? '',
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      discountAmount: (data['discount_amount'] ?? 0).toDouble(),
      isPercentageDiscount: data['is_percentage_discount'] ?? false,
      finalPrice: (data['final_price'] ?? 0).toDouble(),
      totalPrice: (data['total_price'] ?? 0).toDouble(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'discount_amount': discountAmount,
      'is_percentage_discount': isPercentageDiscount,
      'final_price': finalPrice,
      'total_price': totalPrice,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    double? discountAmount,
    bool? isPercentageDiscount,
    double? finalPrice,
    double? totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
      isPercentageDiscount: isPercentageDiscount ?? this.isPercentageDiscount,
      finalPrice: finalPrice ?? this.finalPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method để tính finalPrice và totalPrice
  static OrderItem createFromProduct({
    required String orderId,
    required String productId,
    required String productName,
    required double price,
    required int quantity,
    double discountAmount = 0,
    bool isPercentageDiscount = false,
  }) {
    double finalPrice;
    if (isPercentageDiscount) {
      finalPrice = price - (price * discountAmount / 100);
    } else {
      finalPrice = price - discountAmount;
    }
    
    final totalPrice = finalPrice * quantity;
    
    return OrderItem(
      id: '',
      orderId: orderId,
      productId: productId,
      productName: productName,
      price: price,
      quantity: quantity,
      discountAmount: discountAmount,
      isPercentageDiscount: isPercentageDiscount,
      finalPrice: finalPrice,
      totalPrice: totalPrice,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
} 