import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../models/inventory_session.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/design_system.dart';
import '../../utils/inventory_status_mapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/design_system.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/inventory_item_service.dart';
import '../../widgets/main_layout.dart';

class InventoryHistoryScreen extends StatefulWidget {
  final String sessionId;
  const InventoryHistoryScreen({super.key, required this.sessionId});

  @override
  State<InventoryHistoryScreen> createState() => _InventoryHistoryScreenState();
}

class _InventoryHistoryScreenState extends State<InventoryHistoryScreen> {
  DocumentSnapshot? _sessionDoc;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  final _productService = ProductService();
  final _itemService = InventoryItemService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final sessionDoc = await FirebaseFirestore.instance.collection('inventory_sessions').doc(widget.sessionId).get();
    final products = await _productService.getProducts().first;
    final itemsSnapshot = await FirebaseFirestore.instance
        .collection('inventory_items')
        .where('session_id', isEqualTo: widget.sessionId)
        .get();
    final itemsList = itemsSnapshot.docs.map((doc) {
      final data = doc.data();
      final productId = (data['product_id'] ?? '').toString();
      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => Product(
          id: '',
          internalName: 'Sản phẩm không xác định',
          tradeName: 'Sản phẩm không xác định',
          unit: '',
          description: '',
          notes: '',
          status: 'inactive',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return {
        'id': doc.id,
        'product_id': productId,
        'product_name': product.tradeName,
        'stock_system': data['stock_system'] ?? 0,
        'stock_actual': data['stock_actual'] ?? 0,
        'unit': product.unit,
        'diff': data['diff'] ?? 0,
      };
    }).toList();
    setState(() {
      _sessionDoc = sessionDoc;
      _items = itemsList.cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _sessionDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final session = _sessionDoc!.data() as Map<String, dynamic>;
    final total = _items.length;
    final matched = _items.where((i) => (i['diff'] ?? 0) == 0).length;
    final up = _items.where((i) => (i['diff'] ?? 0) > 0).length;
    final down = _items.where((i) => (i['diff'] ?? 0) < 0).length;
    final diffItems = _items.where((i) => (i['diff'] ?? 0) != 0).toList();
    
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: mainGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Luôn đảm bảo về danh sách kiểm kê
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => MainLayout(initialPage: MainPage.inventory)),
              (route) => false,
            );
          },
        ),
        centerTitle: true,
        title: Text('Lịch sử kiểm kê', style: h2Mobile.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin phiếu kiểm kê
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin phiếu kiểm kê', style: body.copyWith(color: mainGreen, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text('Tên phiếu:', style: body)),
                        Expanded(child: Text(session['name'] ?? '', style: body.copyWith(fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(child: Text('Ngày kiểm kê:', style: body)),
                        Expanded(child: Text(_formatDate(session['created_at']), style: body.copyWith(fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(child: Text('Người kiểm kê:', style: body)),
                        Expanded(child: Text(session['created_by'] ?? '', style: body.copyWith(fontWeight: FontWeight.w600))),
                      ],
                    ),
                    if (session['update_note'] != null && session['update_note'].toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(child: Text('Ghi chú cập nhật:', style: body)),
                          Expanded(child: Text(session['update_note'] ?? '', style: body.copyWith(fontWeight: FontWeight.w600, fontStyle: FontStyle.italic))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Kết quả kiểm kê
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kết quả kiểm kê', style: body.copyWith(color: mainGreen, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text('Tổng sản phẩm kiểm kê:', style: body)),
                        Text('$total', style: body.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: Text('Sản phẩm khớp:', style: body)),
                        Text('$matched', style: body.copyWith(fontWeight: FontWeight.w600, color: mainGreen)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: Text('Sản phẩm lệch lên:', style: body)),
                        Text('$up', style: body.copyWith(fontWeight: FontWeight.w600, color: Colors.orange)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: Text('Sản phẩm lệch xuống:', style: body)),
                        Text('$down', style: body.copyWith(fontWeight: FontWeight.w600, color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
              // Chi tiết chênh lệch
              if (diffItems.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chi tiết chênh lệch', style: body.copyWith(color: mainGreen, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...diffItems.map((item) => _buildDiffItem(item)).toList(),
                    ],
                  ),
                ),
              // Thông báo hoàn tất
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    SizedBox(height: 8),
                    Text(
                      'Phiên kiểm kê đã hoàn tất',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tồn kho đã được cập nhật thành công',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiffItem(Map<String, dynamic> item) {
    final diff = item['diff'] ?? 0;
    final isUp = diff > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['product_name'] ?? '', style: body.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Hệ thống: ${item['stock_system']} ${item['unit']} | Thực tế: ${item['stock_actual']} ${item['unit']}', style: body.copyWith(fontSize: 13, color: textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: isUp ? Colors.orange : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              (diff > 0 ? '+$diff' : '$diff'),
              style: body.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
    if (date is DateTime) return '${date.day}/${date.month}/${date.year}';
    return date.toString();
  }
} 