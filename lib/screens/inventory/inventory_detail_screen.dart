import 'package:flutter/material.dart';

import '../../services/inventory_item_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/main_layout.dart';
import 'package:flutter/services.dart';
import '../../services/product_service.dart';
import '../../widgets/common/design_system.dart';
import '../../models/product.dart';
import 'inventory_confirm_screen.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String sessionId;
  const InventoryDetailScreen({super.key, required this.sessionId});

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
  Set<String> _selectedItemIds = {};

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
        'stock_invoice': product.stockInvoice ?? 0,
        'sku': product.sku ?? '',
        'barcode': product.barcode ?? '',
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
        'sku': item['sku'] ?? '',
        'barcode': item['barcode'] ?? '',
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
    final checkedCount = _selectedItemIds.length;
    return Scaffold(
      backgroundColor: appBackground,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading xanh + progress bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 32, left: 0, right: 0, bottom: 16),
                color: mainGreen,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
                            if (mainLayoutState != null) {
                              mainLayoutState.onSidebarTap(MainPage.inventory);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Kiểm kê kho',
                              style: h2Mobile.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Để cân icon back
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text('$checkedCount/$totalProducts', style: body.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: LinearProgressIndicator(
                              value: totalProducts > 0 ? checkedCount / totalProducts : 0,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              color: Colors.white,
                              minHeight: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: Container(
                  color: appBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          ...filteredItems.map((item) => _buildStyledMobileProductCard(context, item)).toList(),
                          const SizedBox(height: 80), // Để không bị che bởi footer
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Footer cố định
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Lưu tạm
                        _saveAsDraft();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: const BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text('Lưu tạm'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: checkedCount == totalProducts && totalProducts > 0 ? () {
                        // Chuyển sang màn xác nhận kiểm kê
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InventoryConfirmScreen(sessionId: widget.sessionId),
                          ),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Tiếp tục'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: mainGreen, width: 1.5)),
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

  Widget _buildStyledMobileProductCard(BuildContext context, Map<String, dynamic> item) {
    final id = item['id'] ?? item['product_id'];
    final actualController = _actualControllers[id] ??= TextEditingController(text: (item['stock_actual']?.toString() ?? ''));
    final systemStock = item['stock_system'] ?? 0;
    final unit = item['unit'] ?? '';
    final note = (item['note'] ?? '').toString();
    int actualValue = int.tryParse(actualController.text) ?? 0;
    void setActual(int v) {
      actualController.text = v.toString();
      _itemService.updateItem(id, {'stock_actual': v, 'diff': v - systemStock});
    }
    final isSelected = _selectedItemIds.contains(id);
    if (isSelected) {
      // Đã kiểm kê: chỉ còn tiêu đề, sku, mã vạch và nút check
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((item['product_name'] ?? '').toString(), style: body.copyWith(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('SKU: ${item['sku'] ?? ''}', style: body.copyWith(fontSize: 11, color: textSecondary)),
                  Text('Mã vạch: ${item['barcode'] ?? ''}', style: body.copyWith(fontSize: 11, color: textSecondary)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedItemIds.remove(id);
                });
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mainGreen,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      );
    }
    // Chưa kiểm kê: full layout
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          // Tiêu đề, sku, mã vạch và nút check
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((item['product_name'] ?? '').toString(), style: body.copyWith(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('SKU: ${item['sku'] ?? ''}', style: body.copyWith(fontSize: 11, color: textSecondary)),
                    Text('Mã vạch: ${item['barcode'] ?? ''}', style: body.copyWith(fontSize: 11, color: textSecondary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedItemIds.add(id);
                  });
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    color: Colors.white,
                  ),
                  child: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Hai cột tồn kho
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tồn hệ thống
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text('Tồn hệ thống', style: body.copyWith(fontSize: 12, color: textSecondary)),
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text('$systemStock $unit', style: body.copyWith(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
                    ),
                  ],
                ),
              ),
              // Tồn thực tế
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Text('Tồn thực tế', style: body.copyWith(fontSize: 12, color: textSecondary)),
                    ),
                    const SizedBox(height: 2),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final inputWidth = constraints.maxWidth;
                        return Container(
                          width: inputWidth,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                splashRadius: 18,
                                onPressed: actualValue > 0 ? () {
                                  setState(() {
                                    actualValue--;
                                    setActual(actualValue);
                                  });
                                } : null,
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    actualValue.toString(),
                                    style: body.copyWith(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                splashRadius: 18,
                                onPressed: () {
                                  setState(() {
                                    actualValue++;
                                    setActual(actualValue);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Ghi chú: $note', style: body.copyWith(fontSize: 11, color: Colors.grey)),
            ),
        ],
      ),
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