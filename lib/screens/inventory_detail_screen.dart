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
  Map<String, dynamic>? _userInfo;
  final Map<String, TextEditingController> _actualControllers = {};
  final Map<String, TextEditingController> _noteControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final sessionDoc = await FirebaseFirestore.instance.collection('inventory_sessions').doc(widget.sessionId).get();
    final sessionData = sessionDoc.data() as Map<String, dynamic>;
    // Lấy user info thật nếu có createdById
    if (sessionData['createdById'] != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(sessionData['createdById']).get();
      _userInfo = userDoc.data();
    } else {
      _userInfo = null;
    }
    _itemService.getItemsBySession(widget.sessionId).listen((items) async {
      // Lấy stock thật từ bảng products cho từng sản phẩm
      final updatedItems = <Map<String, dynamic>>[];
      for (final item in items) {
        final productId = item['productId'];
        int? realStock;
        try {
          final productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
          realStock = (productDoc.data()?['stock'] as int?) ?? item['systemStock'];
        } catch (_) {
          realStock = item['systemStock'];
        }
        final newItem = Map<String, dynamic>.from(item);
        newItem['systemStock'] = realStock;
        updatedItems.add(newItem);
      }
      setState(() {
        _sessionDoc = sessionDoc;
        _items = updatedItems;
        _loading = false;
      });
    });
  }

  List<Map<String, dynamic>> get filteredItems {
    final base = displayItems;
    if (_searchText.trim().isEmpty) return base;
    final search = _searchText.trim().toLowerCase();
    return base.where((item) => (item['productName'] ?? '').toLowerCase().contains(search)).toList();
  }

  List<Map<String, dynamic>> get displayItems {
    if (isCompleted || isUpdated) {
      // Sắp xếp: diff != 0 lên đầu, đã kiểm kê không lệch ở giữa, chưa kiểm kê ở cuối
      final changed = _items.where((i) => (i['actualStock'] != null && i['actualStock'].toString().isNotEmpty && (i['diff'] ?? 0) != 0)).toList();
      final checkedNoDiff = _items.where((i) => (i['actualStock'] != null && i['actualStock'].toString().isNotEmpty && (i['diff'] ?? 0) == 0)).toList();
      final notChecked = _items.where((i) => i['actualStock'] == null || i['actualStock'].toString().isEmpty).toList();
      return [...changed, ...checkedNoDiff, ...notChecked];
    } else {
      return _items;
    }
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

  bool get isCompleted {
    final data = _sessionDoc?.data() as Map<String, dynamic>?;
    return (data?['status'] ?? '') == 'Đã hoàn tất';
  }
  bool get isUpdated {
    final data = _sessionDoc?.data() as Map<String, dynamic>?;
    return (data?['status'] ?? '') == 'Đã cập nhật kho';
  }

  Future<void> _confirmCompleteInventory() async {
    setState(() { _loading = true; });
    final notCheckedCount = _items.where((i) => i['actualStock'] == null || i['actualStock'].toString().isEmpty).length;
    if (notCheckedCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Vẫn còn sản phẩm chưa kiểm kê'),
          content: Text('Có $notCheckedCount sản phẩm chưa kiểm kê. Bạn vẫn muốn hoàn tất?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Vẫn hoàn tất')),
          ],
        ),
      );
      if (confirmed != true) {
        setState(() { _loading = false; });
        return;
      }
    }
    await FirebaseFirestore.instance.collection('inventory_sessions').doc(widget.sessionId).update({'status': 'Đã hoàn tất'});
    await _fetchData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hoàn tất kiểm kê!'), backgroundColor: Colors.green),
      );
    }
    setState(() { _loading = false; });
  }

  Future<void> _updateStock() async {
    setState(() { _loading = true; });
    for (final item in _items) {
      final productId = item['productId'];
      final actualStock = item['actualStock'] ?? 0;
      debugPrint('Cập nhật tồn kho: productId=$productId, actualStock=$actualStock');
      try {
        await FirebaseFirestore.instance.collection('products').doc(productId).update({'stock': actualStock});
        debugPrint('Đã cập nhật thành công cho productId=$productId');
      } catch (e) {
        debugPrint('Lỗi khi cập nhật productId=$productId: $e');
      }
    }
    await FirebaseFirestore.instance.collection('inventory_sessions').doc(widget.sessionId).update({'status': 'Đã cập nhật kho'});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật tồn kho thành công!'), backgroundColor: Colors.green));
      setState(() {});
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _sessionDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final session = _sessionDoc!.data() as Map<String, dynamic>;
    final diffCount = _items.where((i) => (i['diff'] ?? 0) != 0).length;
    final totalProducts = _items.length;
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
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
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
                            Text(
                              session['name']?.isNotEmpty == true ? session['name'] : 'Kiểm kê kho',
                              style: bodyLarge.copyWith(fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text('Ngày kiểm kê', style: bodyLarge.copyWith(color: textSecondary)),
                                const SizedBox(width: 8),
                                Text((session['createdAt'] as Timestamp).toDate().toString().split(' ')[0], style: bodyLarge.copyWith(fontWeight: FontWeight.w500, color: textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text('Cập nhật kho', style: bodyLarge.copyWith(color: textSecondary)),
                                const SizedBox(width: 8),
                                Text(session['status'] ?? '', style: bodyLarge.copyWith(fontWeight: FontWeight.w500, color: textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text('Ghi chú', style: bodyLarge.copyWith(color: textSecondary)),
                                const SizedBox(width: 8),
                                Text(session['note'] ?? '', style: bodyLarge.copyWith(fontWeight: FontWeight.w500, color: textPrimary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
   const SizedBox(height: 16),
                           Row(
                              children: [
                                                Text('Người kiểm kê: ', style: bodyLarge.copyWith(color: textSecondary)),
                            Text(_userInfo?['name'] ?? session['createdBy'] ?? '', style: bodyLarge.copyWith(fontWeight: FontWeight.w500, color: textPrimary)),
                              ],
                            ),
                              const SizedBox(height: 16),
                             Row(
                              children: [
                                if (_userInfo?['email'] != null)
                              Text(_userInfo?['email'] ?? '', style: bodyLarge.copyWith(color: textSecondary)),
                              ],
                            ),
                              const SizedBox(height: 16),
                             Row(
                              children: [
                                Text('Số sản phẩm: ', style: bodyLarge.copyWith(color: textSecondary)),
                            Text('$totalProducts', style: bodyLarge.copyWith(fontWeight: FontWeight.w500, color: textPrimary)),
                              ],
                            ),
                              const SizedBox(height: 16),
                Row(
                              children: [
                            Text('Số sản phẩm lệch: ', style: bodyLarge.copyWith(color: textSecondary)),
                            Text('$diffCount', style: bodyLarge.copyWith(fontWeight: FontWeight.w500, color: diffCount > 0 ? warningOrange : textSecondary)),
                              ],
                            ),
                           
                  
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.only(left: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: primaryBlue),
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white,
                          ),
                          child: Text(
                            session['status'] ?? '',
                            style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                if (!isCompleted && !isUpdated) ...[
                  OutlinedButton(
                    onPressed: _saveAsDraft,
                    style: secondaryButtonStyle,
                    child: const Text('Lưu nháp'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _confirmCompleteInventory,
                    style: primaryButtonStyle,
                    child: const Text('Hoàn tất kiểm kê'),
                  ),
                ] else if (isCompleted && !isUpdated) ...[
                  ElevatedButton(
                    onPressed: _updateStock,
                    style: primaryButtonStyle,
                    child: const Text('Cập nhật tồn kho'),
                  ),
                ]
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
                    final id = item['id'] ?? item['productId'];
                    TextEditingController actualController = _actualControllers[id] ??= TextEditingController(text: item['actualStock']?.toString() ?? '');
                    TextEditingController noteController = _noteControllers[id] ??= TextEditingController(text: item['note'] ?? '');
                    int systemStock = item['systemStock'] ?? 0;
                    int? actualStock = int.tryParse(actualController.text);
                    final isNotChecked = actualController.text.isEmpty;
                    final diff = isNotChecked ? null : (actualStock ?? 0) - systemStock;
                    Color? rowColor;
                    if (isNotChecked) {
                      rowColor = Colors.grey[100];
                    } else if (diff != null && diff > 0) {
                      rowColor = Colors.green[50];
                    } else if (diff != null && diff < 0) {
                      rowColor = Colors.orange[50];
                    } else {
                      rowColor = Colors.white;
                    }
                    return Container(
                      color: rowColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(item['productName'] ?? '', style: bodyLarge.copyWith(color: textPrimary))),
                          Expanded(flex: 2, child: Text('${item['systemStock']}', textAlign: TextAlign.center, style: bodyLarge)),
                          Expanded(
                            flex: 2,
                            child: (!isCompleted && !isUpdated)
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                        child: Focus(
                                          onFocusChange: (hasFocus) async {
                                            if (!hasFocus) {
                                              final actual = int.tryParse(actualController.text) ?? 0;
                                              final diff = actual - (item['systemStock'] ?? 0);
                                              await _itemService.updateItem(item['id'], {'actualStock': actual, 'diff': diff});
                                            }
                                          },
                                          child: TextField(
                                            controller: actualController,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            onChanged: (v) {
                                              setState(() {}); // chỉ update UI local, không gọi Firestore
                                            },
                                            enabled: !isCompleted && !isUpdated,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                            ),
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
                                  )
                                : Center(
                                    child: Text(
                                      item['actualStock'] == null || item['actualStock'].toString().isEmpty
                                          ? '—'
                                          : '${item['actualStock']}',
                                      textAlign: TextAlign.center,
                                      style: bodyLarge,
                                    ),
                                  ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Builder(
                                builder: (context) {
                                  if (isNotChecked) {
                                    return Text('—', style: bodyLarge.copyWith(color: textSecondary));
                                  } else if (diff != null && diff > 0) {
                                    return Text('+${diff}', style: bodyLarge.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold));
                                  } else if (diff != null && diff < 0) {
                                    return Text('$diff', style: bodyLarge.copyWith(color: warningOrange, fontWeight: FontWeight.bold));
                                  } else {
                                    return Text('0', style: bodyLarge);
                                  }
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: (!isCompleted && !isUpdated)
                                ? TextField(
                                    controller: noteController,
                                    onChanged: (v) async {
                                      await _itemService.updateItem(item['id'], {'note': v});
                                    },
                                    enabled: !isCompleted && !isUpdated,
                                    style: bodyLarge,
                                    decoration: InputDecoration(
                                      hintText: 'Ghi chú...',
                                      hintStyle: bodyLarge.copyWith(color: textSecondary),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: primaryBlue, width: 1.5)),
                                      filled: true,
                                      fillColor: cardBackground,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    ),
                                  )
                                : Text(
                                    (item['note'] ?? '').trim().isEmpty ? '—' : item['note'],
                                    style: bodyLarge,
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