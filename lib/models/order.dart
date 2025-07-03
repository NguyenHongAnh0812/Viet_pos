import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String customerId;
  final String orderCode;
  final String orderType; // 'retail' hoặc 'wholesale'
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String paymentStatus; // 'pending', 'paid', 'partial'
  final String status; // 'active', 'cancelled', 'completed'
  final String? note;
  final String? customerName;
  final String? customerPhone;

  Order({
    required this.id,
    required this.customerId,
    required this.orderCode,
    required this.orderType,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentStatus,
    required this.status,
    this.note,
    this.customerName,
    this.customerPhone,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
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

    return Order(
      id: doc.id,
      customerId: data['customer_id'] ?? '',
      orderCode: data['order_code'] ?? '',
      orderType: data['order_type'] ?? 'retail',
      createdBy: data['created_by'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      totalAmount: (data['total_amount'] ?? 0).toDouble(),
      discountAmount: (data['discount_amount'] ?? 0).toDouble(),
      finalAmount: (data['final_amount'] ?? 0).toDouble(),
      paymentStatus: data['payment_status'] ?? 'pending',
      status: data['status'] ?? 'active',
      note: data['note'],
      customerName: data['customer_name'],
      customerPhone: data['customer_phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'order_code': orderCode,
      'order_type': orderType,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'final_amount': finalAmount,
      'payment_status': paymentStatus,
      'status': status,
      if (note != null) 'note': note,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
    };
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? orderCode,
    String? orderType,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalAmount,
    double? discountAmount,
    double? finalAmount,
    String? paymentStatus,
    String? status,
    String? note,
    String? customerName,
    String? customerPhone,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      orderCode: orderCode ?? this.orderCode,
      orderType: orderType ?? this.orderType,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      note: note ?? this.note,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }
} 