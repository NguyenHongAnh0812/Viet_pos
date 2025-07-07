import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/payment.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _ordersCollection = 'orders';
  final String _orderItemsCollection = 'order_items';
  final String _paymentsCollection = 'payments';

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
        final orderRef = _firestore.collection(_ordersCollection).doc();
        transaction.set(orderRef, order.copyWith(id: orderRef.id).toMap());
        
        // 2. Tạo order items trong collection riêng
        for (final item in items) {
          final itemRef = _firestore.collection(_orderItemsCollection).doc();
          transaction.set(itemRef, item.copyWith(
            id: itemRef.id,
            orderId: orderRef.id,
          ).toMap());
        }
        
        // 3. Tạo payment trong collection riêng
        final paymentRef = _firestore.collection(_paymentsCollection).doc();
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
        .collection(_ordersCollection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  // Lấy đơn hàng theo ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection(_ordersCollection).doc(orderId).get();
      if (!doc.exists) return null;
      return Order.fromFirestore(doc);
    } catch (e) {
      throw 'Lỗi khi lấy đơn hàng: $e';
    }
  }

  // Lấy order items của một đơn hàng
  Stream<List<OrderItem>> getOrderItems(String orderId) {
    return _firestore
        .collection(_orderItemsCollection)
        .where('order_id', isEqualTo: orderId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderItem.fromFirestore(doc)).toList());
  }

  // Lấy payments của một đơn hàng
  Stream<List<Payment>> getOrderPayments(String orderId) {
    return _firestore
        .collection(_paymentsCollection)
        .where('order_id', isEqualTo: orderId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  // Lấy tất cả order items (cho báo cáo)
  Stream<List<OrderItem>> getAllOrderItems() {
    return _firestore
        .collection(_orderItemsCollection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderItem.fromFirestore(doc)).toList());
  }

  // Lấy tất cả payments (cho báo cáo)
  Stream<List<Payment>> getAllPayments() {
    return _firestore
        .collection(_paymentsCollection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  // Lấy order items theo sản phẩm
  Stream<List<OrderItem>> getOrderItemsByProduct(String productId) {
    return _firestore
        .collection(_orderItemsCollection)
        .where('product_id', isEqualTo: productId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderItem.fromFirestore(doc)).toList());
  }

  // Lấy payments theo phương thức
  Stream<List<Payment>> getPaymentsByMethod(String method) {
    return _firestore
        .collection(_paymentsCollection)
        .where('method', isEqualTo: method)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  // Cập nhật đơn hàng
  Future<void> updateOrder(String orderId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Lỗi khi cập nhật đơn hàng: $e';
    }
  }

  // Cập nhật order item
  Future<void> updateOrderItem(String itemId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_orderItemsCollection).doc(itemId).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Lỗi khi cập nhật order item: $e';
    }
  }

  // Cập nhật payment
  Future<void> updatePayment(String paymentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_paymentsCollection).doc(paymentId).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Lỗi khi cập nhật payment: $e';
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
          .collection(_paymentsCollection)
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
        .collection(_ordersCollection)
        .where('created_at', isGreaterThanOrEqualTo: startOfDay)
        .where('created_at', isLessThan: endOfDay)
        .get();
    
    final orderNumber = (snapshot.docs.length + 1).toString().padLeft(3, '0');
    return 'DH$dateStr$orderNumber';
  }

  // Lấy đơn hàng theo customer
  Stream<List<Order>> getOrdersByCustomer(String customerId) {
    return _firestore
        .collection(_ordersCollection)
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  // Lấy đơn hàng theo trạng thái
  Stream<List<Order>> getOrdersByStatus(String status) {
    return _firestore
        .collection(_ordersCollection)
        .where('status', isEqualTo: status)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  // Lấy đơn hàng theo trạng thái thanh toán
  Stream<List<Order>> getOrdersByPaymentStatus(String paymentStatus) {
    return _firestore
        .collection(_ordersCollection)
        .where('payment_status', isEqualTo: paymentStatus)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  // Báo cáo: Top sản phẩm bán chạy
  Stream<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 10}) async* {
    final snapshot = await _firestore
        .collection(_orderItemsCollection)
        .get();
    
    final Map<String, int> productSales = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final productId = data['product_id'] as String;
      final quantity = data['quantity'] as int;
      productSales[productId] = (productSales[productId] ?? 0) + quantity;
    }
    
    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    yield sortedProducts.take(limit).map((entry) => {
      'product_id': entry.key,
      'total_quantity': entry.value,
    }).toList();
  }

  // Báo cáo: Doanh thu theo phương thức thanh toán
  Stream<List<Map<String, dynamic>>> getRevenueByPaymentMethod() async* {
    final snapshot = await _firestore
        .collection(_paymentsCollection)
        .where('status', isEqualTo: 'completed')
        .get();
    
    final Map<String, double> methodRevenue = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final method = data['method'] as String;
      final amount = (data['amount'] as num).toDouble();
      methodRevenue[method] = (methodRevenue[method] ?? 0) + amount;
    }
    
    yield methodRevenue.entries.map((entry) => {
      'method': entry.key,
      'total_revenue': entry.value,
    }).toList();
  }
} 