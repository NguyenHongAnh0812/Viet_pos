import 'package:flutter/material.dart';
import '../models/inventory_session.dart';
import '../widgets/common/design_system.dart';
import '../services/inventory_item_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/main_layout.dart';
import 'package:flutter/services.dart';

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
  bool _completeLoading = false;
  bool _updateStockLoading = false;
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
    // Lấy toàn bộ inventory_items của session này (đã có snapshot product info)
    final itemsSnapshot = await FirebaseFirestore.instance
        .collection('inventory_items')
        .where('sessionId', isEqualTo: widget.sessionId)
        .get();
    final itemsList = itemsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'sessionId': (data['sessionId'] ?? '').toString(),
        'productId': (data['productId'] ?? '').toString(),
        'productName': (data['productName'] ?? '').toString(),
        'systemStock': data['systemStock'] ?? 0,
        'actualStock': data['actualStock'] ?? 0,
        'diff': data['diff'] ?? 0,
        'note': (data['note'] ?? '').toString(),
      };
    }).toList();
    setState(() {
      _sessionDoc = sessionDoc;
      _items = itemsList.cast<Map<String, dynamic>>();
      _loading = false;
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

  Future<void> _syncSessionProducts() async {
    final itemsSnapshot = await FirebaseFirestore.instance
        .collection('inventory_items')
        .where('sessionId', isEqualTo: widget.sessionId)
        .get();
    final products = itemsSnapshot.docs.map((doc) => doc.data()).toList();
    await FirebaseFirestore.instance
        .collection('inventory_sessions')
        .doc(widget.sessionId)
        .update({'products': products});
  }

  Future<void> _saveAsDraft() async {
    for (final item in _items) {
      final id = (item['id'] ?? item['productId'] ?? '').toString();
      final actualController = _actualControllers[id];
      final noteController = _noteControllers[id];
      final actualStock = int.tryParse(actualController?.text ?? '') ?? 0;
      final note = (noteController?.text ?? '').toString();
      final systemStock = item['systemStock'] ?? 0;
      final diff = actualStock - systemStock;
      final docRef = FirebaseFirestore.instance.collection('inventory_items').doc(id);
      final docSnap = await docRef.get();
      final data = {
        'sessionId': (item['sessionId'] ?? widget.sessionId ?? '').toString(),
        'productId': (item['productId'] ?? id ?? '').toString(),
        'productName': (item['productName'] ?? '').toString(),
        'systemStock': systemStock,
        'actualStock': actualStock,
        'diff': diff,
        'note': note,
      };
      if (docSnap.exists) {
        await docRef.update(data);
      } else {
        await docRef.set(data);
      }
    }
    await FirebaseFirestore.instance
        .collection('inventory_sessions')
        .doc(widget.sessionId)
        .update({'status': 'đang kiểm kê'});
    await _syncSessionProducts();
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
    setState(() { _completeLoading = true; });
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
        setState(() { _completeLoading = false; });
        return;
      }
    }
    await FirebaseFirestore.instance.collection('inventory_sessions').doc(widget.sessionId).update({'status': 'Đã hoàn tất'});
    await _syncSessionProducts();
    await _fetchData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hoàn tất kiểm kê!'), backgroundColor: Colors.green),
      );
    }
    setState(() { _completeLoading = false; });
  }

  Future<void> _updateStock() async {
    setState(() { _updateStockLoading = true; });
    for (final item in _items) {
      final productId = item['productId'];
      final actualStock = int.tryParse(_actualControllers[item['id']]?.text ?? '') ?? item['actualStock'] ?? 0;
      try {
        await FirebaseFirestore.instance.collection('products').doc(productId).update({'stock': actualStock});
      } catch (e) {
        debugPrint('Lỗi khi cập nhật productId=$productId: $e');
      }
    }
    await FirebaseFirestore.instance.collection('inventory_sessions').doc(widget.sessionId).update({'status': 'Đã cập nhật kho'});
    await _syncSessionProducts();
    await _fetchData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật tồn kho thành công!'), backgroundColor: Colors.green));
      setState(() {});
    }
    setState(() { _updateStockLoading = false; });
  }

  String get displayStatus {
    final status = (_sessionDoc?.data() as Map<String, dynamic>?)?['status'] ?? '';
    if (status == 'in_progress' || status == 'đang kiểm kê') return 'Đang kiểm kê';
    if (status == 'Đã hoàn tất') return 'Đã hoàn tất';
    if (status == 'Đã cập nhật kho') return 'Đã cập nhật kho';
    return status;
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
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          children: [
            // Heading with back arrow
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              color: const Color(0xFFF7F8FA),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF222B45)),
                    onPressed: () {
                      final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
                      if (mainLayoutState != null) {
                        mainLayoutState.onSidebarTap(MainPage.inventory);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chi tiết kiểm kê',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Color(0xFF222B45),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tiêu đề và nhãn trạng thái trên 1 dòng, dãn đều 2 bên
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    session['name']?.isNotEmpty == true ? session['name'] : 'Kiểm kê kho',
                                        style: h2.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: primaryBlue),
                                    borderRadius: BorderRadius.circular(24),
                                    color: Colors.white,
                                  ),
                                  child: Text(
                                        displayStatus,
                                    style: body.copyWith(color: primaryBlue, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // 4 cột thông tin
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cột 1: Ngày kiểm kê, cập nhật kho, ghi chú
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Ngày kiểm kê', style: body.copyWith(color: textSecondary)),
                                      const SizedBox(height: 4),
                                          Text((session['createdAt'] as Timestamp).toDate().toString().split(' ')[0], style: body.copyWith(fontWeight: FontWeight.bold, color: textPrimary)),
                                      const SizedBox(height: 16),
                                          Text('Cập nhật kho', style: body.copyWith(fontWeight: FontWeight.w500, color: textPrimary)),
                                      const SizedBox(height: 4),
                                          Text(displayStatus, style: body.copyWith(fontWeight: FontWeight.w500, color: textPrimary)),
                                      const SizedBox(height: 16),
                                      Text('Ghi chú', style: body.copyWith(color: textSecondary)),
                                      const SizedBox(height: 4),
                                      Text(session['note'] ?? '', style: body.copyWith(fontWeight: FontWeight.w500, color: textPrimary)),
                                    ],
                                  ),
                                ),
                                // Cột 2: Người kiểm kê
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Người kiểm kê', style: body.copyWith(color: textSecondary)),
                                      const SizedBox(height: 4),
                                          Text(_userInfo?['name'] ?? session['createdBy'] ?? '', style: body.copyWith(fontWeight: FontWeight.bold, color: textPrimary)),
                                      if (_userInfo?['email'] != null)
                                        Text(_userInfo?['email'] ?? '', style: body.copyWith(color: textSecondary)),
                                    ],
                                  ),
                                ),
                                // Cột 3: Số sản phẩm
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Số sản phẩm', style: body.copyWith(color: textSecondary)),
                                      const SizedBox(height: 4),
                                      Text('$totalProducts', style: body.copyWith(fontWeight: FontWeight.w500, color: textPrimary)),
                                    ],
                                  ),
                                ),
                                // Cột 4: Số sản phẩm lệch
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Số sản phẩm lệch', style: body.copyWith(color: textSecondary)),
                                      const SizedBox(height: 4),
                                          Text('$diffCount', style: body.copyWith(fontWeight: FontWeight.bold, color: diffCount > 0 ? warningOrange : textSecondary)),
                                    ],
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
                                filled: true,
                                isDense: true,
                                 fillColor: Colors.transparent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (!isCompleted && !isUpdated) ...[
                            const SizedBox(width: 16),
                            ElevatedButton(
                                  onPressed: _completeLoading
                                      ? null
                                      : () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Xác nhận hoàn tất phiên kiểm kê?'),
                                              content: const Text('Sau khi hoàn tất, bạn không thể thay đổi số liệu kiểm kê.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Hủy'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Xác nhận'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            _confirmCompleteInventory();
                                          }
                                        },
                              style: primaryButtonStyle,
                              child: _completeLoading
                                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Hoàn tất kiểm kê'),
                            ),
                          ] else if (isCompleted && !isUpdated) ...[
                            ElevatedButton(
                              onPressed: _updateStockLoading ? null : _updateStock,
                              style: primaryButtonStyle,
                              child: _updateStockLoading
                                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Cập nhật tồn kho'),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Table header
              
                      // Product list
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            // Header row
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(color: borderColor, width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: Text('Tên sản phẩm', style: body.copyWith(fontWeight: FontWeight.bold, color: textSecondary))),
                                  Expanded(flex: 2, child: Text('Số lượng hệ thống', textAlign: TextAlign.center, style: body.copyWith(fontWeight: FontWeight.bold, color: textSecondary))),
                                  Expanded(flex: 2, child: Text('Số lượng thực tế', textAlign: TextAlign.center, style: body.copyWith(fontWeight: FontWeight.bold, color: textSecondary))),
                                  Expanded(flex: 2, child: Text('Chênh lệch', textAlign: TextAlign.center, style: body.copyWith(fontWeight: FontWeight.bold, color: textSecondary))),
                                  Expanded(flex: 3, child: Text('Ghi chú', style: body.copyWith(fontWeight: FontWeight.bold, color: textSecondary))),
                                ],
                              ),
                            ),
                            // Product rows
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6 - 48, // trừ chiều cao header
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: filteredItems.length,
                                itemBuilder: (context, i) {
                                  final item = filteredItems[i];
                                  final id = item['id'] ?? item['productId'];
                                      final actualController = _actualControllers[id] ??= TextEditingController(text: (item['actualStock']?.toString() ?? ''));
                                      final noteController = _noteControllers[id] ??= TextEditingController(text: (item['note']?.toString() ?? ''));
                                      final systemStock = item['systemStock'] ?? 0;
                                      final actualStock = int.tryParse(actualController.text) ?? 0;
                                      final diff = actualController.text.isEmpty ? null : actualStock - systemStock;
                                      final rowColor = actualController.text.isEmpty
                                        ? Colors.grey[100]
                                        : diff != null && diff > 0
                                          ? Colors.green[50]
                                          : diff != null && diff < 0
                                            ? Colors.orange[50]
                                            : Colors.white;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                          color: rowColor,
                                      border: Border(
                                        bottom: BorderSide(color: borderColor, width: 1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                            Expanded(flex: 3, child: Text((item['productName'] ?? '').toString(), style: body.copyWith(fontWeight: FontWeight.bold,color: textPrimary))),
                                        Expanded(flex: 2, child: Text('${item['systemStock']}', textAlign: TextAlign.center, style: body)),
                                        Expanded(
                                          flex: 2,
                                          child: (!isCompleted && !isUpdated)
                                                  ? SizedBox(
                                                      width: 90,
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
                                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                          onChanged: (v) {
                                                            setState(() {});
                                                          },
                                                          enabled: !isCompleted && !isUpdated,
                                                          decoration: InputDecoration(
                                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                            isDense: true,
                                                          ),
                                                        ),
                                                      ),
                                                )
                                              : Center(
                                                  child: Text(
                                                        (item['actualStock']?.toString() ?? '').isEmpty
                                                        ? '—'
                                                          : item['actualStock'].toString(),
                                                    textAlign: TextAlign.center,
                                                    style: body,
                                                  ),
                                                ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Center(
                                                child: actualController.text.isEmpty
                                                    ? Text('—', style: body.copyWith(color: textSecondary))
                                                    : diff != null && diff > 0
                                                        ? Text('+$diff', style: body.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold))
                                                        : diff != null && diff < 0
                                                            ? Text('$diff', style: body.copyWith(color: warningOrange, fontWeight: FontWeight.bold))
                                                            : Text('0', style: body),
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
                                                  style: body,
                                                  decoration: InputDecoration(
                                                    hintText: 'Ghi chú...',
                                                    hintStyle: body.copyWith(color: textSecondary),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: primaryBlue, width: 1.5)),
                                                    filled: true,
                                                    fillColor: Colors.transparent,
                                                    isDense: true,
                                                  ),
                                                )
                                              : Text(
                                                      (item['note'] ?? '').toString().trim().isEmpty ? '—' : item['note'],
                                                  style: body,
                                                ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
} 