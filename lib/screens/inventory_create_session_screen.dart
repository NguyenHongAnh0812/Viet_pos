import 'package:flutter/material.dart';
import '../widgets/common/design_system.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';
import 'inventory_detail_screen.dart';
import '../models/inventory_session.dart';
import '../services/inventory_item_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  int getTotalSelected(List<Product> products) {
    if (_selectMode == 0) return products.length;
    if (_selectMode == 1) return products.where((p) => p.category == _selectedCategory).length;
    return _selectedProducts.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: appBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Tạo phiên kiểm kê', style: h1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Text('Tên phiên kiểm kê *', style: bodyLarge.copyWith(color: textPrimary)),
                  const SizedBox(height: space8),
                  TextField(
                    controller: _nameController,
                    style: bodyLarge.copyWith(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Nhập tên phiên kiểm kê...',
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: space16),
                  Text('Ghi chú', style: bodyLarge.copyWith(color: textPrimary)),
                  const SizedBox(height: space8),
                  TextField(
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
                  final categories = products.map((p) => p.category).toSet().toList();
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
                          ),
                          RadioListTile<int>(
                            value: 2,
                            groupValue: _selectMode,
                            onChanged: (v) => setState(() => _selectMode = v!),
                            title: Text('Chọn sản phẩm cụ thể', style: bodyLarge.copyWith(color: textPrimary)),
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
                                return CheckboxListTile(
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
                                  title: Text(p.name, style: bodyLarge.copyWith(color: textPrimary)),
                                  subtitle: p.commonName.isNotEmpty ? Text(p.commonName, style: bodyLarge.copyWith(color: textSecondary)) : null,
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
                        child: Text('Tổng số sản phẩm sẽ kiểm kê: ${getTotalSelected(products)}', style: bodyLarge.copyWith(color: textPrimary)),
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
                    setState(() => _saving = true);
                    // Tạo phiên kiểm kê
                    final products = await _productService.getProducts().first;
                    List<Product> selectedProducts;
                    if (_selectMode == 0) {
                      selectedProducts = products;
                    } else if (_selectMode == 1) {
                      selectedProducts = products.where((p) => p.category == _selectedCategory).toList();
                    } else {
                      selectedProducts = products.where((p) => _selectedProducts.contains(p.id)).toList();
                    }
                    final now = DateTime.now();
                    final sessionData = {
                      'createdAt': now,
                      'createdBy': 'Nguyễn Văn An', // TODO: lấy user thực tế
                      'note': _noteController.text,
                      'status': 'Đang kiểm kê',
                    };
                    final sessionRef = await FirebaseFirestore.instance.collection('inventory_sessions').add(sessionData);
                    final sessionId = sessionRef.id;
                    // Tạo các inventory_items
                    for (final p in selectedProducts) {
                      await _itemService.addItem({
                        'sessionId': sessionId,
                        'productId': p.id,
                        'productName': p.commonName,
                        'systemStock': p.stock,
                        'actualStock': p.stock,
                        'diff': 0,
                        'note': '',
                      });
                    }
                    setState(() => _saving = false);
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InventoryDetailScreen(sessionId: sessionId),
                      ),
                    );
                  },
                  style: primaryButtonStyle,
                  child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Tạo và bắt đầu kiểm kê'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 