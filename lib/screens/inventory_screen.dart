import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../models/inventory_session.dart';
import '../services/product_category_service.dart';
import '../models/product_category.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'inventory_history_screen.dart';
import '../widgets/common/design_system.dart';
import 'inventory_create_session_screen.dart';

class InventoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onViewHistory;
  const InventoryScreen({super.key, this.onBack, this.onViewHistory});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  // TODO: Replace with real data/models
  List<Map<String, dynamic>> _products = [
    {'name': 'Amoxicillin 250mg', 'commonName': 'Amoxicillin', 'systemQty': 120, 'actualQty': null, 'checked': false},
    {'name': 'Enrofloxacin 50mg', 'commonName': 'Enrofloxacin', 'systemQty': 5, 'actualQty': null, 'checked': false},
    {'name': 'Meloxicam 1.5mg', 'commonName': 'Meloxicam', 'systemQty': 80, 'actualQty': null, 'checked': false},
    {'name': 'Miconazole Cream 2%', 'commonName': 'Miconazole', 'systemQty': 3, 'actualQty': null, 'checked': false},
    {'name': 'Vitamin B Complex', 'commonName': 'B Complex', 'systemQty': 45, 'actualQty': null, 'checked': false},
  ];
  bool _saving = false;
  bool _showHistory = false;
  bool _showFilter = false;
  String? _selectedCategory;
  String _selectedStatus = 'Tất cả trạng thái';
  final List<String> _categoryOptions = ['Tất cả danh mục', 'Kháng sinh', 'Vitamin', 'Khác']; // TODO: lấy từ service thực tế
  final List<String> _statusOptions = ['Tất cả trạng thái', 'Chưa kiểm kê', 'Đã kiểm kê', 'Lệch số lượng'];
  final _inventoryService = InventoryService();
  final _categoryService = ProductCategoryService();
  final _productService = ProductService();
  List<Map<String, dynamic>> _scannedProducts = [];
  Map<String, String> _actualQtyMap = {};
  // Thêm biến để bật/tắt tính năng đồng bộ số lượng thực tế
  bool _syncStock = false;
  Map<String, TextEditingController> _qtyControllers = {};
  // Thêm biến để theo dõi trạng thái đã lưu
  Map<String, bool> _savedProducts = {};

  final List<Map<String, dynamic>> demoSessions = [
    {
      'name': 'Kiểm kê tháng 12/2024',
      'desc': 'Kiểm kê cuối năm',
      'date': '1/12/2024',
      'status': 'Đã cập nhật kho',
      'statusColor': successGreen,
      'badge': BadgeVariant.secondary,
      'productCount': 150,
      'mismatchCount': 12,
      'updated': true,
    },
    {
      'name': 'Kiểm kê thuốc kháng sinh',
      'desc': 'Kiểm kê danh mục kháng sinh',
      'date': '15/11/2024',
      'status': 'Đã hoàn tất',
      'statusColor': warningOrange,
      'badge': BadgeVariant.warning,
      'productCount': 45,
      'mismatchCount': 3,
      'updated': false,
    },
    {
      'name': 'Kiểm kê vaccine',
      'desc': 'Kiểm kê vaccine thú y',
      'date': '20/11/2024',
      'status': 'Đang kiểm kê',
      'statusColor': primaryBlue,
      'badge': BadgeVariant.defaultVariant,
      'productCount': 28,
      'mismatchCount': 0,
      'updated': false,
    },
    {
      'name': 'Kiểm kê kho mới',
      'desc': 'Phiên kiểm kê mới tạo',
      'date': '5/12/2024',
      'status': 'Nháp',
      'statusColor': textSecondary,
      'badge': BadgeVariant.outline,
      'productCount': 0,
      'mismatchCount': 0,
      'updated': false,
    },
  ];

  List<Map<String, dynamic>> get filteredSessions {
    final search = _searchController.text.trim().toLowerCase();
    return demoSessions.where((session) {
      final matchesStatus = _selectedStatus == 'Tất cả trạng thái' || session['status'] == _selectedStatus;
      final matchesSearch = search.isEmpty ||
        session['name'].toString().toLowerCase().contains(search) ||
        session['desc'].toString().toLowerCase().contains(search);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Kiểm kê kho', style: h1),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InventoryCreateSessionScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo phiên kiểm kê'),
                  style: primaryButtonStyle,
                ),
              ],
            ),
            const SizedBox(height: space24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: bodyLarge.copyWith(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm phiên kiểm kê...',
                      hintStyle: bodyLarge.copyWith(color: textSecondary),
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
                const SizedBox(width: space16),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'Tất cả trạng thái', child: Text('Tất cả trạng thái')),
                      DropdownMenuItem(value: 'Nháp', child: Text('Nháp')),
                      DropdownMenuItem(value: 'Đang kiểm kê', child: Text('Đang kiểm kê')),
                      DropdownMenuItem(value: 'Đã hoàn tất', child: Text('Đã hoàn tất')),
                      DropdownMenuItem(value: 'Đã cập nhật kho', child: Text('Đã cập nhật kho')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedStatus = v);
                    },
                    style: bodyLarge.copyWith(color: textPrimary),
                    decoration: InputDecoration(
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      filled: true,
                      fillColor: cardBackground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: space24),
            Expanded(
              child: ListView.separated(
                itemCount: filteredSessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: space16),
                itemBuilder: (context, i) {
                  final session = filteredSessions[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(space20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(session['name'], style: h3.copyWith(color: textPrimary)),
                                  const SizedBox(width: space8),
                                  DesignSystemBadge(
                                    text: session['status'],
                                    variant: session['badge'],
                                  ),
                                ],
                              ),
                              const SizedBox(height: space4),
                              Text(session['desc'], style: bodyLarge.copyWith(color: textSecondary)),
                              const SizedBox(height: space8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: textSecondary),
                                  const SizedBox(width: space4),
                                  Text(session['date'], style: bodyLarge.copyWith(color: textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text('Số sản phẩm: ', style: bodyLarge.copyWith(color: textSecondary)),
                                Text('${session['productCount']}', style: bodyLarge.copyWith(color: textPrimary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: space4),
                            Row(
                              children: [
                                Text('Lệch: ', style: bodyLarge.copyWith(color: textSecondary)),
                                Text(
                                  '${session['mismatchCount']}',
                                  style: bodyLarge.copyWith(
                                    color: (session['mismatchCount'] ?? 0) > 0 ? warningOrange : textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: space4),
                            Row(
                              children: [
                                Text('Cập nhật kho: ', style: bodyLarge.copyWith(color: textSecondary)),
                                session['updated']
                                  ? const Icon(Icons.check_circle, color: successGreen, size: 20)
                                  : Text('—', style: h3.copyWith(color: textSecondary)),
                              ],
                            ),
                          ],
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
    );
  }

  Widget _buildManualTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có sản phẩm nào để kiểm kê',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code_scanner_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có sản phẩm nào được quét',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(p['commonName'], style: const TextStyle(fontSize: 13, color: Colors.black54)),
                if (p['actualQty'] == null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Chưa kiểm kê', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500, fontSize: 12)),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Text('${p['systemQty']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          SizedBox(
            width: 140,
            child: TextFormField(
              initialValue: p['actualQty']?.toString() ?? '',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
              onChanged: (v) {
                setState(() {
                  p['actualQty'] = int.tryParse(v);
                  p['checked'] = v.isNotEmpty;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return StreamBuilder<List<InventorySession>>(
      stream: _inventoryService.getSessionsByMonth(DateTime.now()),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return const Text('Chưa có lịch sử kiểm kê tháng này.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sessions.map((s) => ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text('${s.createdAt.day.toString().padLeft(2, '0')}/${s.createdAt.month.toString().padLeft(2, '0')}/${s.createdAt.year} - ${s.createdBy}'),
            subtitle: Text('${s.products.length} sản phẩm, ${s.products.where((p) => p.diff != 0).length} sản phẩm lệch số lượng'),
            trailing: TextButton(
              onPressed: () => _showSessionDetail(context, s),
              child: const Text('Xem chi tiết'),
            ),
          )).toList(),
        );
      },
    );
  }

  Future<void> _saveInventorySession() async {
    setState(() => _saving = true);
    final now = DateTime.now();
    // Lấy danh sách sản phẩm thực tế
    final products = await _productService.getProducts().first;
    final sessionProducts = <InventoryProduct>[];
    for (final p in products) {
      final actualStr = _actualQtyMap[p.id];
      final actualQty = int.tryParse(actualStr ?? '') ?? 0;
      sessionProducts.add(InventoryProduct(
        productId: p.id,
        name: p.name,
        systemQty: p.stock,
        actualQty: actualQty,
        diff: actualQty - p.stock,
      ));
      // Nếu _syncStock là true, cập nhật số lượng thực tế vào Firestore
      if (_syncStock && actualStr != null && actualStr.isNotEmpty) {
        await _productService.updateProduct(p.id, p.copyWith(stock: actualQty));
      }
    }
    final session = InventorySession(
      id: '',
      createdAt: now,
      createdBy: 'Chủ cửa hàng', // TODO: lấy user thực tế nếu có auth
      note: _noteController.text.trim(),
      products: sessionProducts,
      status: 'done',
    );
    await _inventoryService.addSession(session);
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu phiên kiểm kê!')));
  }

  void _showSessionDetail(BuildContext context, InventorySession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Phiên kiểm kê ${session.createdAt.day.toString().padLeft(2, '0')}/${session.createdAt.month.toString().padLeft(2, '0')}/${session.createdAt.year}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Người thực hiện: ${session.createdBy}'),
              Text('Ghi chú: ${session.note}'),
              const SizedBox(height: 8),
              const Text('Sản phẩm kiểm kê:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...session.products.map((p) => Row(
                children: [
                  Expanded(child: Text(p.name)),
                  Text('HT: ${p.systemQty}', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(width: 8),
                  Text('TT: ${p.actualQty}', style: const TextStyle(color: Colors.blue)),
                  const SizedBox(width: 8),
                  if (p.diff != 0)
                    Text('Lệch: ${p.diff > 0 ? '+' : ''}${p.diff}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  void _onFindBarcode() async {
    final code = _barcodeController.text.trim();
    if (code.isEmpty) return;
    // TODO: Tìm sản phẩm theo barcode từ Firestore
    // Hiện popup nhập số lượng, sau đó thêm vào _scannedProducts
    // Demo: thêm sản phẩm giả
    final demo = {
      'name': 'Demo Product',
      'commonName': 'Demo',
      'actualQty': 1,
    };
    final qty = await showDialog<int>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: '1');
        return AlertDialog(
          title: const Text('Nhập số lượng thực tế'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Số lượng'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, int.tryParse(controller.text) ?? 1),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
    if (qty != null) {
      setState(() {
        _scannedProducts.add({...demo, 'actualQty': qty});
        _barcodeController.clear();
      });
    }
  }

  Future<void> _saveProductQuantity(String productId, int newQuantity) async {
    try {
      // Lấy thông tin sản phẩm hiện tại
      final products = await _productService.getProducts().first;
      final product = products.firstWhere((p) => p.id == productId);
      
      // Tạo bản sao của sản phẩm với số lượng mới và cập nhật updatedAt
      final updatedProduct = product.copyWith(
        stock: newQuantity,
        updatedAt: DateTime.now(),
      );
      
      // Cập nhật sản phẩm
      await _productService.updateProduct(productId, updatedProduct);
      
      setState(() {
        // Cập nhật UI sau khi lưu thành công
        _actualQtyMap[productId] = '$newQuantity';
        _savedProducts[productId] = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật số lượng thành công!')),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật số lượng: $e')),
      );
    }
  }

  void syncQtyController(String key, String value) {
    if (!_qtyControllers.containsKey(key) || _qtyControllers[key] == null) {
      _qtyControllers[key] = TextEditingController(text: value);
    } else if (_qtyControllers[key]!.text != value) {
      _qtyControllers[key]!.text = value;
      _qtyControllers[key]!.selection = TextSelection.collapsed(offset: value.length);
    }
  }
} 