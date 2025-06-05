import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../models/inventory_session.dart';
import '../services/product_category_service.dart';
import '../models/product_category.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'inventory_history_screen.dart';

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
  String? _selectedStatus;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 4),
                const Text('Kiểm kê kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
                const Spacer(),

              ],
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _tabIndex == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text('Kiểm kê thủ công', style: TextStyle(fontWeight: FontWeight.bold, color: _tabIndex == 0 ? Colors.blue : Colors.black54)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _tabIndex == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text('Quét mã vạch', style: TextStyle(fontWeight: FontWeight.bold, color: _tabIndex == 1 ? Colors.blue : Colors.black54)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_tabIndex == 0) _buildManualTab(),
            if (_tabIndex == 1) _buildBarcodeTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTab() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên sản phẩm, barcode...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  tooltip: 'Lọc',
                  onPressed: () => setState(() => _showFilter = !_showFilter),
                ),
              ],
            ),
            if (_showFilter)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Danh mục sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          StreamBuilder<List<ProductCategory>>(
                            stream: _categoryService.getCategories(),
                            builder: (context, snapshot) {
                              final cats = snapshot.data ?? [];
                              final options = ['Tất cả danh mục', ...cats.map((c) => c.name)];
                              return DropdownButtonFormField<String>(
                                value: _selectedCategory ?? options[0],
                                items: options.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (v) => setState(() => _selectedCategory = v),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Trạng thái kiểm kê', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedStatus ?? _statusOptions[0],
                            items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _selectedStatus = v),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => setState(() => _showFilter = false),
                          child: const Text('Áp dụng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = _categoryOptions[0];
                              _selectedStatus = _statusOptions[0];
                            });
                          },
                          child: const Text('Xóa bộ lọc'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            StreamBuilder<List<Product>>(
              stream: _productService.getProducts(),
              builder: (context, snapshot) {
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Không có sản phẩm nào trong hệ thống.', style: TextStyle(color: Colors.black54)),
                  );
                }
                final isMobile = MediaQuery.of(context).size.width < 600;
                if (isMobile) {
                  // MOBILE LAYOUT
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...products.map((p) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tiêu đề 1 dòng
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (p.commonName != null && p.commonName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2, bottom: 8),
                                child: Text(p.commonName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                              ),
                            Row(
                              children: [
                                // Khu vực 1: Hệ thống
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Hệ thống', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                      Text('${p.stock}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ),
                                // Khu vực 2: Bộ đếm
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 18),
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onPressed: _actualQtyMap[p.id] != null && int.tryParse(_actualQtyMap[p.id]!) == p.stock
                                            ? null
                                            : () {
                                                int currentQty = int.tryParse(_actualQtyMap[p.id] ?? '${p.stock}') ?? p.stock;
                                                if (currentQty > 0) {
                                                  currentQty--;
                                                  setState(() {
                                                    _actualQtyMap[p.id] = '$currentQty';
                                                  });
                                                }
                                              },
                                        ),
                                        SizedBox(
                                          width: 40,
                                          child: TextFormField(
                                            controller: _qtyControllers.containsKey(p.id) ? _qtyControllers[p.id]! : TextEditingController(text: _actualQtyMap[p.id] ?? '${p.stock}'),
                                            enabled: !(_actualQtyMap[p.id] != null && int.tryParse(_actualQtyMap[p.id]!) == p.stock),
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            onChanged: (v) {
                                              setState(() {
                                                _actualQtyMap[p.id] = v;
                                              });
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 18),
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onPressed: _actualQtyMap[p.id] != null && int.tryParse(_actualQtyMap[p.id]!) == p.stock
                                            ? null
                                            : () {
                                                int currentQty = int.tryParse(_actualQtyMap[p.id] ?? '${p.stock}') ?? p.stock;
                                                currentQty++;
                                                setState(() {
                                                  _actualQtyMap[p.id] = '$currentQty';
                                                });
                                              },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Khu vực 3: Nút Lưu
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _actualQtyMap[p.id] != null && int.tryParse(_actualQtyMap[p.id]!) == p.stock
                                      ? ElevatedButton(
                                          onPressed: null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          child: const Text('Đã lưu'),
                                        )
                                      : ElevatedButton(
                                          onPressed: () {
                                            final actualQty = int.tryParse(_actualQtyMap[p.id] ?? '${p.stock}') ?? p.stock;
                                            if (actualQty != p.stock) {
                                              _saveProductQuantity(p.id, actualQty);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          child: const Text('Lưu'),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                    ],
                  );
                }
                // DESKTOP LAYOUT (giữ nguyên)
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danh sách sản phẩm cần kiểm kê (${products.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 13),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Text('Hệ thống', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                Expanded(flex: 2, child: Text('Thực tế', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                Expanded(flex: 1, child: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ...products.map((p) => Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              if ((_actualQtyMap[p.id]?.isNotEmpty ?? false))
                                                const Padding(
                                                  padding: EdgeInsets.only(left: 6),
                                                  child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                                                ),
                                            ],
                                          ),
                                          Text(p.commonName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                          Text(
                                            p.updatedAt != null
                                              ? 'Lần cuối cập nhật: ${p.updatedAt.toString().substring(0, 16).replaceAll('T', ' ')}'
                                              : 'Chưa cập nhật',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text('${p.stock}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Container(
                                          width: 120,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: const BorderRadius.only(
                                                    topLeft: Radius.circular(6),
                                                    bottomLeft: Radius.circular(6),
                                                  )
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(Icons.remove, size: 16, color: Colors.black),
                                                  splashColor: Colors.transparent,
                                                  highlightColor: Colors.transparent,
                                                  padding: const EdgeInsets.all(0),
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                  onPressed: _actualQtyMap[p.id] != null && int.tryParse(_actualQtyMap[p.id]!) == p.stock
                                                    ? null
                                                    : () {
                                                        int currentQty = int.tryParse(_actualQtyMap[p.id] ?? '${p.stock}') ?? p.stock;
                                                        if (currentQty > 0) {
                                                          currentQty--;
                                                          setState(() {
                                                            _actualQtyMap[p.id] = '$currentQty';
                                                          });
                                                        }
                                                      },
                                                ),
                                              ),
                                              Container(
                                                width: 48,
                                                height: 36,
                                                alignment: Alignment.center,
                                                color: Colors.grey[100],
                                                child: TextFormField(
                                                  controller: _qtyControllers.containsKey(p.id) ? _qtyControllers[p.id]! : TextEditingController(text: _actualQtyMap[p.id] ?? '${p.stock}'),
                                                  enabled: !(_actualQtyMap[p.id] != null && int.tryParse(_actualQtyMap[p.id]!) == p.stock),
                                                  keyboardType: TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                                  decoration: const InputDecoration(
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.zero,
                                                  ),
                                                  onChanged: (v) {
                                                    setState(() {
                                                      _actualQtyMap[p.id] = v;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: const BorderRadius.only(
                                                    topRight: Radius.circular(6),
                                                    bottomRight: Radius.circular(6),
                                                  )
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(Icons.add, size: 16, color: Colors.black),
                                                  splashColor: Colors.transparent,
                                                  highlightColor: Colors.transparent,
                                                  padding: const EdgeInsets.all(0),
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                  onPressed: _actualQtyMap[p.id] != null && int.tryParse(_actualQtyMap[p.id]!) == p.stock
                                                    ? null
                                                    : () {
                                                        int currentQty = int.tryParse(_actualQtyMap[p.id] ?? '${p.stock}') ?? p.stock;
                                                        currentQty++;
                                                        setState(() {
                                                          _actualQtyMap[p.id] = '$currentQty';
                                                        });
                                                      },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: _actualQtyMap[p.id] != null && int.tryParse(_actualQtyMap[p.id]!) == p.stock
                                          ? ElevatedButton(
                                              onPressed: null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              child: const Text('Đã lưu'),
                                            )
                                          : ElevatedButton(
                                              onPressed: () {
                                                final actualQty = int.tryParse(_actualQtyMap[p.id] ?? '${p.stock}') ?? p.stock;
                                                if (actualQty != p.stock) {
                                                  _saveProductQuantity(p.id, actualQty);
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              child: const Text('Lưu'),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                            ],
                          )),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Lịch sử kiểm kê'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: widget.onViewHistory,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _saveInventorySession,
                  icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                  label: const Text('Lưu phiên kiểm kê'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
            if (_showHistory) ...[
              const SizedBox(height: 24),
              _buildHistoryPanel(),
            ],
          ],
        ),
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
            width: 100,
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

  Widget _buildBarcodeTab() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã vạch...',
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _onFindBarcode(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _onFindBarcode,
                child: const Text('Tìm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Sản phẩm đã quét (${_scannedProducts.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(
            child: _scannedProducts.isEmpty
                ? Center(
                    child: Text('Chưa có sản phẩm nào được quét', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                  )
                : ListView.separated(
                    itemCount: _scannedProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = _scannedProducts[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(p['commonName'], style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                ],
                              ),
                            ),
                            Text('SL: ${p['actualQty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Row(
            children: [
               ElevatedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Lịch sử kiểm kê'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: widget.onViewHistory,
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveInventorySession,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                label: const Text('Lưu phiên kiểm kê'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          if (_showHistory) ...[
            const SizedBox(height: 24),
            _buildHistoryPanel(),
          ],
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
      
      // Tạo bản sao của sản phẩm với số lượng mới
      final updatedProduct = product.copyWith(stock: newQuantity);
      
      // Cập nhật sản phẩm
      await _productService.updateProduct(productId, updatedProduct);
      
      setState(() {
        // Cập nhật UI sau khi lưu thành công
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
} 