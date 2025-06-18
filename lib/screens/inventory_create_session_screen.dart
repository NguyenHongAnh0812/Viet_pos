import 'package:flutter/material.dart';
import '../widgets/common/design_system.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';
import 'inventory_detail_screen.dart';
import '../models/inventory_session.dart';
import '../services/inventory_item_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_layout.dart';

class InventoryCreateSessionScreen extends StatefulWidget {
  const InventoryCreateSessionScreen({Key? key}) : super(key: key);

  @override
  State<InventoryCreateSessionScreen> createState() => _InventoryCreateSessionScreenState();
}

class _InventoryCreateSessionScreenState extends State<InventoryCreateSessionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();

  int _selectMode = 0; // 0: all, 1: by category, 2: specific
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
        .where('status', isNotEqualTo: 'done')
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

  int getProductCountByCategory(List<Product> products, String? category) {
    if (category == null) return 0;
    return products.where((p) => p.categoryIds.contains(category)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: SingleChildScrollView(
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
                const Text('Tạo phiên kiểm kê', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: textPrimary)),
              ],
            ),
            const SizedBox(height: 24),
            // Thông tin cơ bản
            Container(
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(space20),
              margin: const EdgeInsets.only(bottom: space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin cơ bản', style: h3.copyWith(color: textPrimary)),
                  const SizedBox(height: space16),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: bodyLarge.copyWith(color: textPrimary),
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
                              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
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
                        Text('Ghi chú', style: bodyLarge.copyWith(color: textPrimary)),
                        const SizedBox(height: space8),
                        TextFormField(
                          controller: _noteController,
                          minLines: 2,
                          maxLines: 4,
                          style: bodyLarge.copyWith(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Ghi chú về phiên kiểm kê...',
                            hintStyle: bodyLarge.copyWith(color: textSecondary),
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
                              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                        ),
                        const SizedBox(height: space16),
                        Text('Ngày kiểm kê', style: bodyLarge.copyWith(color: textPrimary)),
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
                                    primary: primaryBlue,
                                    onPrimary: Colors.white,
                                    surface: cardBackground,
                                    onSurface: textPrimary,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              controller: TextEditingController(
                                text: _selectedDate != null
                                    ? 'ngày ${_selectedDate!.day} tháng ${_selectedDate!.month} năm ${_selectedDate!.year}'
                                    : '',
                              ),
                              style: bodyLarge.copyWith(color: textPrimary),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.calendar_today, color: textSecondary),
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
                                  borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              ),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(space20),
              margin: const EdgeInsets.only(bottom: space24),
              child: StreamBuilder<List<Product>>(
                stream: _productService.getProducts(),
                builder: (context, snapshot) {
                  final products = snapshot.data ?? [];
                  final categories = products.expand((p) => p.categoryIds).toSet().toList()..sort();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Danh sách sản phẩm kiểm kê', style: h3.copyWith(color: textPrimary)),
                      const SizedBox(height: space16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RadioListTile<int>(
                            value: 0,
                            groupValue: _selectMode,
                            onChanged: (v) => setState(() => _selectMode = v!),
                            title: Text('Tất cả sản phẩm (${products.length} sản phẩm)', style: bodyLarge.copyWith(color: textPrimary)),
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                          ),
                          RadioListTile<int>(
                            value: 1,
                            groupValue: _selectMode,
                            onChanged: (v) => setState(() => _selectMode = v!),
                            title: Text('Chọn theo danh mục', style: bodyLarge.copyWith(color: textPrimary)),
                            subtitle: _selectMode == 1 && categories.isNotEmpty
                                ? DropdownButton<String>(
                                    value: _selectedCategory ?? categories[0],
                                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                    onChanged: (v) => setState(() => _selectedCategory = v),
                                  )
                                : null,
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                          ),
                          RadioListTile<int>(
                            value: 2,
                            groupValue: _selectMode,
                            onChanged: (v) => setState(() => _selectMode = v!),
                            title: Text('Chọn sản phẩm cụ thể', style: bodyLarge.copyWith(color: textPrimary)),
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                          ),
                        ],
                      ),
                      if (_selectMode == 2)
                        Container(
                          height: 300,
                          margin: const EdgeInsets.only(top: space8, bottom: space8),
                          decoration: BoxDecoration(
                            color: appBackground,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Scrollbar(
                            child: ListView.builder(
                              itemCount: products.length,
                              itemBuilder: (context, i) {
                                final p = products[i];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Checkbox(
                                        value: _selectedProducts.contains(p.id),
                                        onChanged: (v) {
                                          setState(() {
                                            if (v == true) {
                                              _selectedProducts.add(p.id);
                                            } else {
                                              _selectedProducts.remove(p.id);
                                            }
                                          });
                                        },
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.tradeName, style: bodyLarge.copyWith(color: textPrimary)),
                                              if (p.internalName.isNotEmpty && p.internalName != p.tradeName)
                                                Text(p.internalName, style: bodyLarge.copyWith(color: textSecondary)),
                                            ],
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
                      const SizedBox(height: space8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: space12, horizontal: space16),
                        decoration: BoxDecoration(
                          color: appBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Tổng số sản phẩm sẽ kiểm kê: ${_selectMode == 0 ? products.length : _selectMode == 1 ? getProductCountByCategory(products, _selectedCategory) : _selectedProducts.length}', style: bodyLarge.copyWith(color: textPrimary)),
                      ),
                    ],
                  );
                },
              ),
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
                      selectedProducts = products.where((p) => p.categoryIds.contains(_selectedCategory)).toList();
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