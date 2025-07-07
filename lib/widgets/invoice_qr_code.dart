import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/order.dart';
import '../models/customer.dart';

class InvoiceQRCode extends StatelessWidget {
  final Order order;
  final Customer customer;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const InvoiceQRCode({
    super.key,
    required this.order,
    required this.customer,
    this.size = 200,
    this.backgroundColor,
    this.foregroundColor,
  });

  String _generateQRData() {
    // Tạo dữ liệu QR code bao gồm thông tin đơn hàng
    final data = {
      'order_code': order.orderCode,
      'customer_name': customer.name ?? '',
      'customer_phone': customer.phone ?? '',
      'total_amount': order.finalAmount,
      'payment_status': order.paymentStatus,
      'created_at': order.createdAt.toIso8601String(),
      'type': 'invoice',
    };
    
    // Chuyển đổi thành JSON string
    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.qr_code,
                color: foregroundColor ?? const Color(0xFF16A34A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'QR Code Hóa đơn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: foregroundColor ?? Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // QR Code
          QrImageView(
            data: _generateQRData(),
            version: QrVersions.auto,
            size: size,
            backgroundColor: backgroundColor ?? Colors.white,
            foregroundColor: foregroundColor ?? Colors.black,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            padding: const EdgeInsets.all(8),
          ),
          
          const SizedBox(height: 12),
          
          // Thông tin đơn hàng
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã đơn hàng: ${order.orderCode}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Khách hàng: ${customer.name ?? 'N/A'}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tổng tiền: ${_formatCurrency(order.finalAmount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Trạng thái: ${_getPaymentStatusText(order.paymentStatus)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getPaymentStatusColor(order.paymentStatus),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final s = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$sđ';
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Đã thanh toán';
      case 'partial':
        return 'Thanh toán một phần';
      case 'pending':
        return 'Chờ thanh toán';
      default:
        return 'Không xác định';
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF16A34A);
      case 'partial':
        return const Color(0xFFFFA726);
      case 'pending':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }
}

// Component QR Code đơn giản (chỉ hiển thị QR code)
class SimpleQRCode extends StatelessWidget {
  final String data;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SimpleQRCode({
    super.key,
    required this.data,
    this.size = 150,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        backgroundColor: backgroundColor ?? Colors.white,
        foregroundColor: foregroundColor ?? Colors.black,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        padding: const EdgeInsets.all(4),
      ),
    );
  }
}

// Component QR Code cho thanh toán
class PaymentQRCode extends StatelessWidget {
  final String orderCode;
  final double amount;
  final String paymentMethod;
  final double size;

  const PaymentQRCode({
    super.key,
    required this.orderCode,
    required this.amount,
    required this.paymentMethod,
    this.size = 200,
  });

  String _generatePaymentQRData() {
    // Tạo dữ liệu QR code cho thanh toán
    final data = {
      'order_code': orderCode,
      'amount': amount,
      'payment_method': paymentMethod,
      'type': 'payment',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon thanh toán
          Icon(
            paymentMethod == 'cash' ? Icons.money : Icons.account_balance,
            color: const Color(0xFF16A34A),
            size: 24,
          ),
          const SizedBox(height: 8),
          
          // QR Code
          QrImageView(
            data: _generatePaymentQRData(),
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            padding: const EdgeInsets.all(8),
          ),
          
          const SizedBox(height: 12),
          
          // Thông tin thanh toán
          Text(
            'Quét để thanh toán',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final s = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$sđ';
  }
} 