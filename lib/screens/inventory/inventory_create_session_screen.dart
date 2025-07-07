import 'package:flutter/material.dart';

import '../../services/product_service.dart';

import '../../services/inventory_service.dart';

import '../../services/inventory_item_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/common/design_system.dart';
import '../../models/product.dart';

class InventoryCreateSessionScreen extends StatefulWidget {
  const InventoryCreateSessionScreen({super.key});

  @override
  State<InventoryCreateSessionScreen> createState() => _InventoryCreateSessionScreenState();
}

class _InventoryCreateSessionScreenState extends State<InventoryCreateSessionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();

  final int _selectMode = 0; // 0: all, 1: by category, 2: specific
  String? _selectedCategory;
  final _productService = ProductService();
  final Set<String> _selectedProducts = {};
  final _inventoryService = InventoryService();
  final _itemService = InventoryItemService();
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkActiveInventorySession();
  }

  Future<void> _checkActiveInventorySession() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('inventory_sessions')
        .where('status', isEqualTo: 'Đang kiểm kê')
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Thông báo'),
            content: const Text('Hiện tại đã có một phiên kiểm kê đang diễn ra. Vui lòng hoàn tất trước khi tạo phiên mới.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      });
    }
  }

  int get selectedProductCount {
    if (_selectMode == 0) return _selectedProducts.length;
    if (_selectMode == 1) return _selectedProducts.length;
    return _selectedProducts.length;
  }

  int getProductCountByCategory(String category) {
    // TODO: Implement with new category relation service
    // return products.where((p) => p.categoryIds.contains(category)).length;
    return 0; // Tạm thời return 0
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading với nút back và tiêu đề
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: textPrimary),
                      onPressed: () {
                        final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
                        if (mainLayoutState != null) {
                          mainLayoutState.onSidebarTap(MainPage.inventory);
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    Text('Tạo phiên kiểm kê', style: h2Mobile),
                  ],
                ),
                const SizedBox(height: 24),
                // Thông tin cơ bản
                Container(
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: space16, vertical: space16),
                  margin: const EdgeInsets.only(bottom: space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thông tin cơ bản', style: h3Mobile.copyWith(color: textPrimary)),
                      const SizedBox(height: space8),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              style: bodyMobile.copyWith(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Tên phiên kiểm kê *',
                                hintText: 'Nhập tên phiên kiểm kê...',
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
                                  borderSide: const BorderSide(color: mainGreen, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tên phiên kiểm kê';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: space16),
                            Text('Ghi chú', style: bodyMobile.copyWith(color: textPrimary)),
                            const SizedBox(height: space8),
                            TextFormField(
                              controller: _noteController,
                              minLines: 2,
                              maxLines: 4,
                              style: bodyMobile.copyWith(color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Ghi chú về phiên kiểm kê...',
                                hintStyle: bodyMobile.copyWith(color: textSecondary),
                                filled: true,
                                fillColor: appBackground,
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
                                  borderSide: const BorderSide(color: mainGreen, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              ),
                            ),
                            const SizedBox(height: space16),
                            Text('Ngày kiểm kê', style: bodyMobile.copyWith(color: textPrimary)),
                            const SizedBox(height: space8),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) => Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: mainGreen,
                                        onPrimary: Colors.white,
                                        surface: cardBackground,
                                        onSurface: textPrimary,
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDate != null
                                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                          : 'Chọn ngày',
                                      style: bodyMobile.copyWith(color: textPrimary),
                                    ),
                                    const Icon(Icons.calendar_today, color: textSecondary, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Danh sách sản phẩm kiểm kê
                Container(
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: space16, vertical: space16),
                  margin: const EdgeInsets.only(bottom: space12),
                  child: _ProductSelectBlock(),
                ),
                // Nút hành động
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: secondaryButtonStyle,
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: space16),
                    ElevatedButton(
                      onPressed: _saving ? null : () async {
                        if (!_formKey.currentState!.validate()) {
                          setState(() => _saving = false);
                          return;
                        }
                        setState(() => _saving = true);
                        // Tạo phiên kiểm kê
                        final products = await _productService.getProducts().first;
                        List<Product> selectedProducts;
                        if (_selectMode == 0) {
                          selectedProducts = products;
                        } else if (_selectMode == 1) {
                          selectedProducts = products.where((p) =>
                          // TODO: Implement with new category relation service
                          // p.categoryIds.contains(_selectedCategory)).toList();
                          true).toList(); // Tạm thời select all products
                        } else {
                          selectedProducts = products.where((p) => _selectedProducts.contains(p.id)).toList();
                        }
                        final now = DateTime.now();
                        final user = FirebaseAuth.instance.currentUser;
                        String? userName;
                        if (user != null) {
                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                          userName = userDoc.data()?['name'] ?? user.email;
                        }
                        final sessionData = {
                          'name': _nameController.text.trim(),
                          'created_at': now,
                          'created_by': userName ?? 'Không rõ',
                          'created_by_id': user?.uid,
                          'note': _noteController.text,
                          'status': 'Đang kiểm kê',
                        };
                        final sessionRef = await FirebaseFirestore.instance.collection('inventory_sessions').add(sessionData);
                        final sessionId = sessionRef.id;
                        // Tạo các inventory_items
                        for (final p in selectedProducts) {
                          await _itemService.addItem({
                            'session_id': sessionId,
                            'product_id': p.id,
                            'product_name': p.tradeName,
                            'stock_system': p.stockSystem,
                            'stock_actual': p.stockSystem,
                            'diff': 0,
                            'note': '',
                          });
                        }
                        setState(() => _saving = false);
                        if (!mounted) return;
                        final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
                        if (mainLayoutState != null) {
                          mainLayoutState.openInventoryDetail(sessionId);
                        }
                      },
                      style: primaryButtonStyle,
                      child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Tạo và bắt đầu kiểm kê'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductSelectBlock extends StatefulWidget {
  @override
  State<_ProductSelectBlock> createState() => _ProductSelectBlockState();
}

class _ProductSelectBlockState extends State<_ProductSelectBlock> {
  int _expanded = 0; // 0: none, 1: all, 2: by category, 3: specific

  @override
  Widget build(BuildContext context) {
    // TODO: Lấy số lượng sản phẩm thực tế
    final int totalProducts = 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Danh sách sản phẩm kiểm kê', style: h3.copyWith(color: textPrimary)),
        const SizedBox(height: space8),
        // Tất cả sản phẩm
        GestureDetector(
          onTap: () => setState(() => _expanded = _expanded == 1 ? 0 : 1),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _expanded == 1 ? mainGreen : borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tất cả sản phẩm', style: bodyLarge.copyWith(color: textPrimary)),
                Text('($totalProducts sản phẩm)', style: bodyLarge.copyWith(color: textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Chọn theo danh mục
        GestureDetector(
          onTap: () => setState(() => _expanded = _expanded == 2 ? 0 : 2),
          child: Container(
            decoration: BoxDecoration(
              color: _expanded == 2 ? const Color(0xFFF6FFFA) : Colors.white,
              border: Border.all(color: _expanded == 2 ? mainGreen : borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Chọn theo danh mục', style: bodyLarge.copyWith(color: textPrimary)),
                Icon(_expanded == 2 ? Icons.expand_less : Icons.expand_more, color: textSecondary),
              ],
            ),
          ),
        ),
        if (_expanded == 2)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FFFA),
              border: Border.all(color: mainGreen, width: 1.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODO: Tree category, mock data
                _CategoryCheckbox(label: 'Thuốc kháng sinh', count: 25, children: [
                  _CategoryCheckbox(label: 'Kháng sinh đường uống', count: 15),
                  _CategoryCheckbox(label: 'Kháng sinh tiêm', count: 10),
                ]),
                _CategoryCheckbox(label: 'Vaccine', count: 18, children: [
                  _CategoryCheckbox(label: 'Vaccine chó mèo', count: 12),
                  _CategoryCheckbox(label: 'Vaccine gia súc', count: 6),
                ]),
                _CategoryCheckbox(label: 'Vitamin', count: 30),
                _CategoryCheckbox(label: 'Thức ăn', count: 45),
              ],
            ),
          ),
        // Chọn sản phẩm cụ thể
        GestureDetector(
          onTap: () => setState(() => _expanded = _expanded == 3 ? 0 : 3),
          child: Container(
            decoration: BoxDecoration(
              color: _expanded == 3 ? const Color(0xFFF6FFFA) : Colors.white,
              border: Border.all(color: _expanded == 3 ? mainGreen : borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            margin: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Chọn sản phẩm cụ thể', style: bodyLarge.copyWith(color: textPrimary)),
                Icon(_expanded == 3 ? Icons.expand_less : Icons.expand_more, color: textSecondary),
              ],
            ),
          ),
        ),
        if (_expanded == 3)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FFFA),
              border: Border.all(color: mainGreen, width: 1.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.qr_code_scanner, color: mainGreen),
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoryCheckbox extends StatelessWidget {
  final String label;
  final int count;
  final List<_CategoryCheckbox>? children;
  const _CategoryCheckbox({required this.label, required this.count, this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(value: false, onChanged: (_) {}),
              Text(label, style: bodyLarge.copyWith(color: textPrimary)),
              const SizedBox(width: 6),
              Text('($count sản phẩm)', style: bodySmall.copyWith(color: textSecondary)),
            ],
          ),
          if (children != null)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(children: children!),
            ),
        ],
      ),
    );
  }
} 