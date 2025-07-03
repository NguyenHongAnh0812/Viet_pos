import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String orderId;
  final double amount;
  final String method; // 'cash', 'bank_transfer', 'card'
  final String status; // 'pending', 'completed', 'failed'
  final DateTime paymentDate;
  final String? reference; // Mã giao dịch, số hóa đơn, v.v.
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    required this.paymentDate,
    this.reference,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime paymentDate;
    DateTime createdAt;
    DateTime updatedAt;
    
    if (data['payment_date'] is Timestamp) {
      paymentDate = (data['payment_date'] as Timestamp).toDate();
    } else if (data['payment_date'] is DateTime) {
      paymentDate = data['payment_date'] as DateTime;
    } else {
      paymentDate = DateTime.now();
    }
    
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

    return Payment(
      id: doc.id,
      orderId: data['order_id'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      method: data['method'] ?? 'cash',
      status: data['status'] ?? 'pending',
      paymentDate: paymentDate,
      reference: data['reference'],
      note: data['note'],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'amount': amount,
      'method': method,
      'status': status,
      'payment_date': Timestamp.fromDate(paymentDate),
      if (reference != null) 'reference': reference,
      if (note != null) 'note': note,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  Payment copyWith({
    String? id,
    String? orderId,
    double? amount,
    String? method,
    String? status,
    DateTime? paymentDate,
    String? reference,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      reference: reference ?? this.reference,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method để tạo payment mới
  static Payment create({
    required String orderId,
    required double amount,
    required String method,
    String status = 'pending',
    String? reference,
    String? note,
  }) {
    return Payment(
      id: '',
      orderId: orderId,
      amount: amount,
      method: method,
      status: status,
      paymentDate: DateTime.now(),
      reference: reference,
      note: note,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
} 