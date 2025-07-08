import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/design_system.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/inventory_item_service.dart';
import '../../widgets/main_layout.dart';

class InventoryConfirmScreen extends StatefulWidget {
  final String sessionId;
  const InventoryConfirmScreen({super.key, required this.sessionId});

  @override
  State<InventoryConfirmScreen> createState() => _InventoryConfirmScreenState();
}

class _InventoryConfirmScreenState extends State<InventoryConfirmScreen> {
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
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(session['name'] ?? '', style: h2Mobile.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: session['status'] == 'draft' 
              ? ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance.collection('inventory_sessions').doc(widget.sessionId).update({'status': 'checked'});
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xác nhận kiểm kê')),
                      );
                      
                      // Quay về danh sách kiểm kê
                      if (mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
                        if (mainLayoutState != null) {
                          mainLayoutState.onSidebarTap(MainPage.inventory);
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi xác nhận kiểm kê: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Xác nhận kiểm kê'),
                )
              : session['status'] == 'checked' 
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            String feedback = '';
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                                      title: const Text('Phản hồi về phiên kiểm kê'),
                                      content: TextField(
                                        decoration: const InputDecoration(
                                          labelText: 'Nội dung phản hồi',
                                          border: OutlineInputBorder(),
                                        ),
                                        minLines: 2,
                                        maxLines: 5,
                                        onChanged: (value) => feedback = value,
                                      ),
                                      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: mainGreen,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          child: const Text('Xác nhận'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: mainGreen,
                                            side: BorderSide(color: mainGreen),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          child: const Text('Hủy'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                            if (confirmed == true && feedback.trim().isNotEmpty) {
                              // Lấy user hiện tại (tạm thời hardcode 'unknown', có thể lấy từ session nếu có)
                              final user = 'unknown';
                              final now = DateTime.now().toIso8601String();
                              final sessionRef = FirebaseFirestore.instance.collection('inventory_sessions').doc(widget.sessionId);
                              final sessionSnap = await sessionRef.get();
                              final data = sessionSnap.data() as Map<String, dynamic>?;
                              final List<dynamic> history = (data?['feedback_history'] as List<dynamic>?) ?? [];
                              history.add({
                                'note': feedback.trim(),
                                'user': user,
                                'time': now,
                              });
                              await sessionRef.update({
                                'status': 'draft',
                                'feedback_history': history,
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã gửi phản hồi và chuyển về phiếu tạm')),
                                );
                                Navigator.of(context).popUntil((route) => route.isFirst);
                                final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
                                if (mainLayoutState != null) {
                                  mainLayoutState.onSidebarTap(MainPage.inventory);
                                }
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: mainGreen,
                            side: BorderSide(color: mainGreen),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Phản hồi'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            String note = '';
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                                      title: const Text('Xác nhận cập nhật tồn kho'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Bạn có chắc chắn muốn cập nhật tồn kho thật cho tất cả sản phẩm?',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          const SizedBox(height: 16),
                                          TextField(
                                            decoration: const InputDecoration(
                                              labelText: 'Ghi chú (tùy chọn)',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) => note = value,
                                          ),
                                        ],
                                      ),
                                      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: mainGreen,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          child: const Text('Xác nhận'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: mainGreen,
                                            side: BorderSide(color: mainGreen),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          child: const Text('Hủy'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                            if (confirmed == true) {
                              await _updateStock(note: note);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã cập nhật tồn kho thành công')),
                                );
                                Navigator.of(context).popUntil((route) => route.isFirst);
                                final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
                                if (mainLayoutState != null) {
                                  mainLayoutState.onSidebarTap(MainPage.inventory);
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text('Cập nhật tồn kho'),
                        ),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 24),
                        SizedBox(height: 8),
                        Text(
                          'Đã cập nhật tồn kho',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Phiên kiểm kê đã hoàn tất và tồn kho đã được cập nhật',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiffItem(Map<String, dynamic> item) {
    final diff = item['diff'] ?? 0;
    final isUp = diff > 0;
    final isDown = diff < 0;
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

  Future<void> _updateStock({String? note}) async {
    for (final item in _items) {
      final productId = item['product_id'];
      final actualStock = item['stock_actual'] ?? 0;
      try {
        await FirebaseFirestore.instance.collection('products').doc(productId).update({'stock_system': actualStock});
      } catch (e) {
        debugPrint('Lỗi khi cập nhật productId=$productId: $e');
      }
    }
    await FirebaseFirestore.instance.collection('inventory_sessions').doc(widget.sessionId).update({
      'status': 'updated',
      if (note != null) 'update_note': note,
    });
  }
} 