import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/payment.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'orders';

  // Tạo đơn hàng mới với order items và payment
  Future<String> createOrder({
    required Order order,
    required List<OrderItem> items,
    required Payment payment,
  }) async {
    try {
      // Bắt đầu transaction
      return await _firestore.runTransaction<String>((transaction) async {
        // 1. Tạo order document
        final orderRef = _firestore.collection(_collection).doc();
        transaction.set(orderRef, order.copyWith(id: orderRef.id).toMap());
        
        // 2. Tạo order items
        for (final item in items) {
          final itemRef = orderRef.collection('order_items').doc();
          transaction.set(itemRef, item.copyWith(
            id: itemRef.id,
            orderId: orderRef.id,
          ).toMap());
        }
        
        // 3. Tạo payment
        final paymentRef = orderRef.collection('payments').doc();
        transaction.set(paymentRef, payment.copyWith(
          id: paymentRef.id,
          orderId: orderRef.id,
        ).toMap());
        
        return orderRef.id;
      });
    } catch (e) {
      throw 'Lỗi khi tạo đơn hàng: $e';
    }
  }

  // Lấy danh sách đơn hàng
  Stream<List<Order>> getOrders() {
    return _firestore
        .collection(_collection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  // Lấy đơn hàng theo ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(orderId).get();
      if (!doc.exists) return null;
      return Order.fromFirestore(doc);
    } catch (e) {
      throw 'Lỗi khi lấy đơn hàng: $e';
    }
  }

  // Lấy order items của một đơn hàng
  Stream<List<OrderItem>> getOrderItems(String orderId) {
    return _firestore
        .collection(_collection)
        .doc(orderId)
        .collection('order_items')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderItem.fromFirestore(doc)).toList());
  }

  // Lấy payments của một đơn hàng
  Stream<List<Payment>> getOrderPayments(String orderId) {
    return _firestore
        .collection(_collection)
        .doc(orderId)
        .collection('payments')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  // Cập nhật đơn hàng
  Future<void> updateOrder(String orderId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Lỗi khi cập nhật đơn hàng: $e';
    }
  }

  // Cập nhật trạng thái đơn hàng
  Future<void> updateOrderStatus(String orderId, String status) async {
    await updateOrder(orderId, {'status': status});
  }

  // Cập nhật trạng thái thanh toán
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    await updateOrder(orderId, {'payment_status': paymentStatus});
  }

  // Thêm payment mới cho đơn hàng
  Future<void> addPayment(String orderId, Payment payment) async {
    try {
      final paymentRef = _firestore
          .collection(_collection)
          .doc(orderId)
          .collection('payments')
          .doc();
      
      await paymentRef.set(payment.copyWith(
        id: paymentRef.id,
        orderId: orderId,
      ).toMap());
    } catch (e) {
      throw 'Lỗi khi thêm payment: $e';
    }
  }

  // Xóa đơn hàng (soft delete)
  Future<void> deleteOrder(String orderId) async {
    await updateOrder(orderId, {'status': 'cancelled'});
  }

  // Tạo mã đơn hàng tự động
  Future<String> generateOrderCode() async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    // Lấy số đơn hàng trong ngày
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final snapshot = await _firestore
        .collection(_collection)
        .where('created_at', isGreaterThanOrEqualTo: startOfDay)
        .where('created_at', isLessThan: endOfDay)
        .get();
    
    final orderNumber = (snapshot.docs.length + 1).toString().padLeft(3, '0');
    return 'DH$dateStr$orderNumber';
  }

  // Lấy đơn hàng theo customer
  Stream<List<Order>> getOrdersByCustomer(String customerId) {
    return _firestore
        .collection(_collection)
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  // Lấy đơn hàng theo trạng thái
  Stream<List<Order>> getOrdersByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  // Lấy đơn hàng theo trạng thái thanh toán
  Stream<List<Order>> getOrdersByPaymentStatus(String paymentStatus) {
    return _firestore
        .collection(_collection)
        .where('payment_status', isEqualTo: paymentStatus)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }
} 