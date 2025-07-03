import 'package:flutter/material.dart';
import '../../models/inventory_session.dart';
import '../../widgets/common/design_system.dart';
import '../../services/inventory_item_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/main_layout.dart';
import 'package:flutter/services.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String sessionId;
  const InventoryDetailScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final _itemService = InventoryItemService();
  final _productService = ProductService();
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
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final sessionDoc = await FirebaseFirestore.instance.collection('inventory_sessions').doc(widget.sessionId).get();
    final sessionData = sessionDoc.data() as Map<String, dynamic>;
    // Lấy user info thật nếu có created_by_id
    if (sessionData['created_by_id'] != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(sessionData['created_by_id']).get();
      _userInfo = userDoc.data();
    } else {
      _userInfo = null;
    }
    // Lấy toàn bộ sản phẩm
    final products = await _productService.getProducts().first;
    _products = products;
    // Lấy toàn bộ inventory_items của session này (đã có snapshot product info)
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
        'session_id': (data['session_id'] ?? '').toString(),
        'product_id': productId,
        'product_name': (data['product_name'] ?? '').toString(),
        'stock_system': data['stock_system'] ?? 0,
        'stock_actual': data['stock_actual'] ?? 0,
        'diff': data['diff'] ?? 0,
        'note': (data['note'] ?? '').toString(),
        'stock_invoice': product?.stockInvoice ?? 0,
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
    return base.where((item) => (item['product_name'] ?? '').toLowerCase().contains(search)).toList();
  }

  List<Map<String, dynamic>> get displayItems {
    if (isCompleted || isUpdated) {
      // Sắp xếp: diff != 0 lên đầu, đã kiểm kê không lệch ở giữa, chưa kiểm kê ở cuối
      final changed = _items.where((i) => (i['stock_actual'] != null && i['stock_actual'].toString().isNotEmpty && (i['diff'] ?? 0) != 0)).toList();
      final checkedNoDiff = _items.where((i) => (i['stock_actual'] != null && i['stock_actual'].toString().isNotEmpty && (i['diff'] ?? 0) == 0)).toList();
      final notChecked = _items.where((i) => i['stock_actual'] == null || i['stock_actual'].toString().isEmpty).toList();
      return [...changed, ...checkedNoDiff, ...notChecked];
    } else {
      return _items;
    }
  }

  Future<void> _syncSessionProducts() async {
    final itemsSnapshot = await FirebaseFirestore.instance
        .collection('inventory_items')
        .where('session_id', isEqualTo: widget.sessionId)
        .get();
    final products = itemsSnapshot.docs.map((doc) => doc.data()).toList();
    await FirebaseFirestore.instance
        .collection('inventory_sessions')
        .doc(widget.sessionId)
        .update({'products': products});
  }

  Future<void> _saveAsDraft() async {
    for (final item in _items) {
      final id = (item['id'] ?? item['product_id'] ?? '').toString();
      final actualController = _actualControllers[id];
      final noteController = _noteControllers[id];
      final actualStock = int.tryParse(actualController?.text ?? '') ?? 0;
      final note = (noteController?.text ?? '').toString();
      final systemStock = item['stock_system'] ?? 0;
      final diff = actualStock - systemStock;
      final docRef = FirebaseFirestore.instance.collection('inventory_items').doc(id);
      final docSnap = await docRef.get();
      final data = {
        'session_id': (item['session_id'] ?? widget.sessionId ?? '').toString(),
        'product_id': (item['product_id'] ?? id ?? '').toString(),
        'product_name': (item['product_name'] ?? '').toString(),
        'stock_system': systemStock,
        'stock_actual': actualStock,
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
    final notCheckedCount = _items.where((i) => i['stock_actual'] == null || i['stock_actual'].toString().isEmpty).length;
    if (notCheckedCount > 0) {
      final contentWidget = Text(
        notCheckedCount > 0
          ? 'Có $notCheckedCount sản phẩm chưa kiểm kê. Bạn vẫn muốn hoàn tất?'
          : 'Sau khi hoàn tất, bạn không thể thay đổi số liệu kiểm kê.',
        style: body,
      );
      final confirmed = await showDesignSystemDialog<bool>(
        context: context,
        title: 'Xác nhận hoàn tất phiên kiểm kê',
        content: contentWidget,
        icon: Icons.check_circle,
        iconColor: Colors.green,
          actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: primaryButtonStyle,
            child: const Text('Xác nhận'),
          ),
          ],
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
      final productId = item['product_id'];
      final actualStock = int.tryParse(_actualControllers[item['id']]?.text ?? '') ?? item['stock_actual'] ?? 0;
      try {
        await FirebaseFirestore.instance.collection('products').doc(productId).update({'stock_system': actualStock});
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
    final isMobile = MediaQuery.of(context).size.width < 700;
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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
                            padding: isMobile ? const EdgeInsets.symmetric(horizontal: 15, vertical: 12) : const EdgeInsets.all(24),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isMobile
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              session['name']?.isNotEmpty == true ? session['name'] : 'Kiểm kê kho',
                                              style: h2.copyWith(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 18),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: primaryBlue),
                                              borderRadius: BorderRadius.circular(8),
                                              color: Colors.white,
                                            ),
                                            child: Text(
                                              displayStatus,
                                              style: body.copyWith(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _infoRowMobile('Ngày kiểm kê', (() {
                                        final createdAt = session['created_at'];
                                        if (createdAt is Timestamp) {
                                          return createdAt.toDate().toString().split(' ')[0];
                                        } else if (createdAt is DateTime) {
                                          return createdAt.toString().split(' ')[0];
                                        } else if (createdAt != null) {
                                          return DateTime.tryParse(createdAt.toString())?.toString().split(' ')[0] ?? '';
                                        } else {
                                          return '';
                                        }
                                      })()),
                                      _infoRowMobile('Cập nhật kho', displayStatus),
                                      _infoRowMobile('Người kiểm kê', _userInfo?['name'] ?? session['created_by'] ?? ''),
                                      if (_userInfo?['email'] != null)
                                        _infoRowMobile('Email', _userInfo?['email'] ?? ''),
                                      _infoRowMobile('Số sản phẩm', '$totalProducts'),
                                      _infoRowMobile('Số sản phẩm lệch', '$diffCount', color: diffCount > 0 ? warningOrange : textSecondary),
                                      if ((session['note'] ?? '').toString().isNotEmpty)
                                        _infoRowMobile('Ghi chú', session['note'] ?? ''),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Ngày kiểm kê', style: body.copyWith(color: textSecondary)),
                                            const SizedBox(height: 4),
                                            (() {
                                              final createdAt = session['created_at'];
                                              if (createdAt is Timestamp) {
                                                return Text(createdAt.toDate().toString().split(' ')[0], style: body.copyWith(fontWeight: FontWeight.bold, color: textPrimary));
                                              } else if (createdAt is DateTime) {
                                                return Text(createdAt.toString().split(' ')[0], style: body.copyWith(fontWeight: FontWeight.bold, color: textPrimary));
                                              } else if (createdAt != null) {
                                                return Text(DateTime.tryParse(createdAt.toString())?.toString().split(' ')[0] ?? '', style: body.copyWith(fontWeight: FontWeight.bold, color: textPrimary));
                                              } else {
                                                return Text('', style: body);
                                              }
                                            })(),
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
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Người kiểm kê', style: body.copyWith(color: textSecondary)),
                                            const SizedBox(height: 4),
                                            Text(_userInfo?['name'] ?? session['created_by'] ?? '', style: body.copyWith(fontWeight: FontWeight.bold, color: textPrimary)),
                                            if (_userInfo?['email'] != null)
                                              Text(_userInfo?['email'] ?? '', style: body.copyWith(color: textSecondary)),
                                          ],
                                        ),
                                      ),
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
                                              final confirmed = await showDesignSystemDialog<bool>(
                                                context: context,
                                                title: 'Xác nhận hoàn tất phiên kiểm kê',
                                                content: Text('Sau khi hoàn tất, bạn không thể thay đổi số liệu kiểm kê.', style: body),
                                                icon: Icons.check_circle,
                                                iconColor: Colors.green,
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('Hủy'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                    style: primaryButtonStyle,
                                                      child: const Text('Xác nhận'),
                                                    ),
                                                  ],
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
                          isMobile
                            ? Column(
                                children: [
                                  for (final item in filteredItems)
                                    _buildMobileProductCard(context, item),
                                ],
                              )
                            : _buildProductTable(context, isMobile),
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

  Widget _buildProductTable(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: isMobile ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8) : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Tên sản phẩm', style: body.copyWith(fontWeight: FontWeight.bold, color: textSecondary, fontSize: isMobile ? 13 : 15))),
                Expanded(flex: 2, child: Text('Số lượng hệ thống', textAlign: TextAlign.center, style: body.copyWith(fontWeight: FontWeight.bold, color: textSecondary, fontSize: isMobile ? 13 : 15))),
                Expanded(flex: 2, child: Text('Số lượng thực tế', textAlign: TextAlign.center, style: body.copyWith(fontWeight: FontWeight.bold, color: textSecondary, fontSize: isMobile ? 13 : 15))),
                Expanded(flex: 2, child: Text('Tồn kho hóa đơn', textAlign: TextAlign.center, style: body.copyWith(fontWeight: FontWeight.bold, color: textSecondary, fontSize: isMobile ? 13 : 15))),
                Expanded(flex: 2, child: Text('Chênh lệch', textAlign: TextAlign.center, style: body.copyWith(fontWeight: FontWeight.bold, color: textSecondary, fontSize: isMobile ? 13 : 15))),
                Expanded(flex: 3, child: Text('Ghi chú', style: body.copyWith(fontWeight: FontWeight.bold, color: textSecondary, fontSize: isMobile ? 13 : 15))),
              ],
            ),
          ),
          // Product rows
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6 - 48,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: filteredItems.length,
              itemBuilder: (context, i) {
                final item = filteredItems[i];
                final id = item['id'] ?? item['product_id'];
                final actualController = _actualControllers[id] ??= TextEditingController(text: (item['stock_actual']?.toString() ?? ''));
                final noteController = _noteControllers[id] ??= TextEditingController(text: (item['note']?.toString() ?? ''));
                final systemStock = item['stock_system'] ?? 0;
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
                  padding: isMobile ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6) : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: rowColor,
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text((item['product_name'] ?? '').toString(), style: body.copyWith(fontWeight: FontWeight.bold, color: textPrimary, fontSize: isMobile ? 13 : 15))),
                      Expanded(flex: 2, child: Text('${item['stock_system']}', textAlign: TextAlign.center, style: body.copyWith(fontSize: isMobile ? 13 : 15))),
                      Expanded(
                        flex: 2,
                        child: (!isCompleted && !isUpdated)
                            ? SizedBox(
                                width: isMobile ? 60 : 90,
                                child: Focus(
                                  onFocusChange: (hasFocus) async {
                                    if (!hasFocus) {
                                      final actual = int.tryParse(actualController.text) ?? 0;
                                      final diff = actual - (item['stock_system'] ?? 0);
                                      await _itemService.updateItem(item['id'], {'stock_actual': actual, 'diff': diff});
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
                                    style: body.copyWith(fontSize: isMobile ? 13 : 15),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  (item['stock_actual']?.toString() ?? '').isEmpty
                                      ? '—'
                                      : item['stock_actual'].toString(),
                                  textAlign: TextAlign.center,
                                  style: body.copyWith(fontSize: isMobile ? 13 : 15),
                                ),
                              ),
                      ),
                      Expanded(flex: 2, child: Text('${item['stock_invoice']}', textAlign: TextAlign.center, style: body.copyWith(fontSize: isMobile ? 13 : 15))),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: actualController.text.isEmpty
                              ? Text('—', style: body.copyWith(color: textSecondary, fontSize: isMobile ? 13 : 15))
                              : diff != null && diff > 0
                                  ? Text('+$diff', style: body.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15))
                                  : diff != null && diff < 0
                                      ? Text('$diff', style: body.copyWith(color: warningOrange, fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15))
                                      : Text('0', style: body.copyWith(fontSize: isMobile ? 13 : 15)),
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
                                style: body.copyWith(fontSize: isMobile ? 13 : 15),
                                decoration: InputDecoration(
                                  hintText: 'Ghi chú...',
                                  hintStyle: body.copyWith(color: textSecondary, fontSize: isMobile ? 13 : 15),
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
                                style: body.copyWith(fontSize: isMobile ? 13 : 15),
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
    );
  }

  Widget _buildMobileProductCard(BuildContext context, Map<String, dynamic> item) {
    final id = item['id'] ?? item['product_id'];
    final actualController = _actualControllers[id] ??= TextEditingController(text: (item['stock_actual']?.toString() ?? ''));
    final noteController = _noteControllers[id] ??= TextEditingController(text: (item['note']?.toString() ?? ''));
    final systemStock = item['stock_system'] ?? 0;
    final actualStock = int.tryParse(actualController.text) ?? 0;
    final diff = actualController.text.isEmpty ? null : actualStock - systemStock;
    final rowColor = actualController.text.isEmpty
      ? Colors.grey[100]
      : diff != null && diff > 0
        ? Colors.green[50]
        : diff != null && diff < 0
          ? Colors.orange[50]
          : Colors.white;
    final borderColor = diff != null && diff > 0
      ? Colors.green
      : diff != null && diff < 0
        ? warningOrange
        : Colors.grey[300];
    // State mở/đóng ô ghi chú cho từng item
    final showNote = ValueNotifier(false);
    return ValueListenableBuilder(
      valueListenable: showNote,
      builder: (context, bool isNoteOpen, _) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: rowColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor ?? Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((item['product_name'] ?? '').toString(), style: body.copyWith(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 15)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: Text('Hệ thống: $systemStock', style: body.copyWith(color: textSecondary, fontSize: 13))),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('Tồn hóa đơn: ${item['stock_invoice']}', style: body.copyWith(color: textSecondary, fontSize: 13)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chênh lệch:', style: body.copyWith(fontSize: 12, color: textSecondary)),
                        const SizedBox(height: 2),
                        diff == null
                          ? Text('—', style: body.copyWith(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 15))
                          : diff > 0
                            ? Text('+$diff', style: body.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 15))
                            : diff < 0
                              ? Text('$diff', style: body.copyWith(color: warningOrange, fontWeight: FontWeight.bold, fontSize: 15))
                              : Text('0', style: body.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Số lượng thực tế', style: body.copyWith(fontSize: 12, color: Colors.green)),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon mở/đóng ghi chú
                            IconButton(
                              icon: Icon(
                                (isNoteOpen || (noteController.text.isNotEmpty)) ? Icons.edit_note : Icons.edit_note_outlined,
                                color: (isNoteOpen || (noteController.text.isNotEmpty)) ? primaryBlue : textSecondary,
                              ),
                              tooltip: isNoteOpen ? 'Ẩn ghi chú' : 'Thêm ghi chú',
                              onPressed: () => showNote.value = !isNoteOpen,
                            ),
                            SizedBox(
                              width: 90,
                              child: (!isCompleted && !isUpdated)
                                  ? TextField(
                                      controller: actualController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: (v) {
                                        setState(() {});
                                      },
                                      enabled: !isCompleted && !isUpdated,
                                      style: body.copyWith(fontSize: 15),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: borderColor ?? Colors.green, width: 2),
                                        ),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      ),
                                    )
                                  : Text((item['stock_actual']?.toString() ?? '').isEmpty ? '—' : item['stock_actual'].toString(), style: body.copyWith(fontSize: 15)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Ô ghi chú chỉ hiển thị khi mở hoặc đã có text
              if (isNoteOpen || noteController.text.isNotEmpty)
                (!isCompleted && !isUpdated)
                    ? TextField(
                        controller: noteController,
                        onChanged: (v) async {
                          await _itemService.updateItem(item['id'], {'note': v});
                        },
                        enabled: !isCompleted && !isUpdated,
                        style: body.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Ghi chú',
                          hintText: 'Ghi chú...',
                          hintStyle: body.copyWith(color: textSecondary, fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor ?? Colors.grey)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryBlue, width: 1.5)),
                          filled: true,
                          fillColor: Colors.transparent,
                          isDense: true,
                        ),
                      )
                    : Text('Ghi chú: ${(item['note'] ?? '').toString().trim().isEmpty ? '—' : item['note']}', style: body.copyWith(fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRowMobile(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: body.copyWith(color: textSecondary, fontSize: 13))),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: body.copyWith(color: color ?? textPrimary, fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
} 