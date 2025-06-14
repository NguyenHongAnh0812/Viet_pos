import 'package:flutter/material.dart';
import '../models/inventory_session.dart';
import '../widgets/common/design_system.dart';
import '../services/inventory_item_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String sessionId;
  const InventoryDetailScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final _itemService = InventoryItemService();
  DocumentSnapshot? _sessionDoc;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final sessionDoc = await FirebaseFirestore.instance.collection('inventory_sessions').doc(widget.sessionId).get();
    _itemService.getItemsBySession(widget.sessionId).listen((items) {
      setState(() {
        _sessionDoc = sessionDoc;
        _items = items;
        _loading = false;
      });
    });
  }

  List<Map<String, dynamic>> get filteredItems {
    if (_searchText.trim().isEmpty) return _items;
    final search = _searchText.trim().toLowerCase();
    return _items.where((item) => (item['productName'] ?? '').toLowerCase().contains(search)).toList();
  }

  Future<void> _saveAsDraft() async {
    await FirebaseFirestore.instance.collection('inventory_sessions').doc(widget.sessionId).update({'status': 'in_progress'});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu nháp thành công'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _sessionDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final session = _sessionDoc!.data() as Map<String, dynamic>;
    final diffCount = _items.where((i) => (i['diff'] ?? 0) != 0).length;
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: appBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Chi tiết kiểm kê', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(space20),
              margin: const EdgeInsets.only(bottom: space20),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(session['note']?.isNotEmpty == true ? session['note'] : 'Kiểm kê kho', style: h1),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Ngày kiểm kê:', style: bodyLarge.copyWith(color: textSecondary)),
                                const SizedBox(width: 8),
                                Text((session['createdAt'] as Timestamp).toDate().toString().split(' ')[0], style: bodyLarge.copyWith(color: textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Người kiểm kê:', style: bodyLarge.copyWith(color: textSecondary)),
                                const SizedBox(width: 8),
                                Text(session['createdBy'] ?? '', style: bodyLarge.copyWith(fontWeight: FontWeight.bold, color: textPrimary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(session['status'] ?? '', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Số sản phẩm:', style: bodyLarge.copyWith(color: textSecondary)),
                              const SizedBox(width: 8),
                              Text('${_items.length}', style: bodyLarge.copyWith(color: textPrimary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Số sản phẩm lệch:', style: bodyLarge.copyWith(color: textSecondary)),
                              const SizedBox(width: 8),
                              Text('$diffCount', style: bodyLarge.copyWith(color: warningOrange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Cập nhật kho:', style: bodyLarge.copyWith(color: textSecondary)),
                              const SizedBox(width: 8),
                              Text('Chưa cập nhật', style: bodyLarge.copyWith(color: textPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  if ((session['note'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Ghi chú:', style: bodyLarge.copyWith(color: textSecondary)),
                    const SizedBox(height: 4),
                    Text(session['note'], style: bodyLarge.copyWith(color: textPrimary)),
                  ],
                ],
              ),
            ),
            // Search and action buttons
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchText = v),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm...',
                      prefixIcon: const Icon(Icons.search, color: textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      filled: true,
                      fillColor: cardBackground,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: _saveAsDraft,
                  style: secondaryButtonStyle,
                  child: const Text('Lưu nháp'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: primaryButtonStyle,
                  child: const Text('Hoàn tất kiểm kê'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: mutedBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: const [
                  Expanded(flex: 3, child: Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Số lượng hệ thống', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Số lượng thực tế', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Chênh lệch', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            // Product list
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border.all(color: borderColor),
                ),
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, i) {
                    final item = filteredItems[i];
                    final actualController = TextEditingController(text: item['actualStock'].toString());
                    final noteController = TextEditingController(text: item['note'] ?? '');
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(item['productName'] ?? '', style: bodyLarge.copyWith(color: textPrimary))),
                          Expanded(flex: 2, child: Text('${item['systemStock']}', textAlign: TextAlign.center, style: bodyLarge)),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  splashRadius: 18,
                                  onPressed: () async {
                                    final current = int.tryParse(actualController.text) ?? 0;
                                    final newValue = current > 0 ? current - 1 : 0;
                                    actualController.text = newValue.toString();
                                    final diff = newValue - (item['systemStock'] ?? 0);
                                    await _itemService.updateItem(item['id'], {'actualStock': newValue, 'diff': diff});
                                    setState(() {});
                                  },
                                ),
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller: actualController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    onChanged: (v) async {
                                      final actual = int.tryParse(v) ?? 0;
                                      final diff = actual - (item['systemStock'] ?? 0);
                                      await _itemService.updateItem(item['id'], {'actualStock': actual, 'diff': diff});
                                      setState(() {});
                                    },
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  splashRadius: 18,
                                  onPressed: () async {
                                    final current = int.tryParse(actualController.text) ?? 0;
                                    final newValue = current + 1;
                                    actualController.text = newValue.toString();
                                    final diff = newValue - (item['systemStock'] ?? 0);
                                    await _itemService.updateItem(item['id'], {'actualStock': newValue, 'diff': diff});
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(flex: 2, child: Text('${item['diff']}', textAlign: TextAlign.center, style: bodyLarge.copyWith(color: (item['diff'] ?? 0) != 0 ? warningOrange : textPrimary))),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: noteController,
                              onChanged: (v) async {
                                await _itemService.updateItem(item['id'], {'note': v});
                              },
                              decoration: InputDecoration(
                                hintText: 'Ghi chú...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 