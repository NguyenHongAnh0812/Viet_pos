import 'package:flutter/material.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../services/product_category_service.dart';
import '../services/product_service.dart';
import '../widgets/common/design_system.dart';

class AddProductCategoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AddProductCategoryScreen({super.key, this.onBack});

  @override
  State<AddProductCategoryScreen> createState() => _AddProductCategoryScreenState();
}

class _AddProductCategoryScreenState extends State<AddProductCategoryScreen> {
  final _categoryService = ProductCategoryService();
  final _productService = ProductService();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String searchText = '';
  List<Product> selectedProducts = [];
  bool isSaving = false;
  int _selectedTab = 0; // 0: Gán thủ công, 1: Điều kiện tự động
  bool _showSelectedPanel = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createCategory() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    if (name.isEmpty) {
      OverlayEntry? entry;
      entry = OverlayEntry(
        builder: (_) => DesignSystemSnackbar(
          message: 'Tên danh mục là bắt buộc!',
          icon: Icons.error,
          onDismissed: () => entry?.remove(),
        ),
      );
      Overlay.of(context).insert(entry);
      return;
    }
    setState(() => isSaving = true);
    try {
      // Tạo danh mục mới
      final newCat = ProductCategory(id: '', name: name, description: desc);
      await _categoryService.addCategory(newCat);
      // Gán sản phẩm vào danh mục
      for (final p in selectedProducts) {
        await _productService.updateProductCategory(p.id, name);
      }
      OverlayEntry? entry;
      entry = OverlayEntry(
        builder: (_) => DesignSystemSnackbar(
          message: 'Tạo danh mục thành công!',
          icon: Icons.check_circle,
          onDismissed: () => entry?.remove(),
        ),
      );
      Overlay.of(context).insert(entry);
      if (widget.onBack != null) widget.onBack!();
    } catch (e) {
      OverlayEntry? entry;
      entry = OverlayEntry(
        builder: (_) => DesignSystemSnackbar(
          message: 'Lỗi: $e',
          icon: Icons.error,
          onDismissed: () => entry?.remove(),
        ),
      );
      Overlay.of(context).insert(entry);
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: ListView(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack ?? () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                const Text('Tạo danh mục sản phẩm mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              ],
            ),
            const SizedBox(height: 24),
            // Thông tin danh mục
            designSystemFormCard(
              title: 'Thông tin danh mục',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nhập thông tin cơ bản cho danh mục sản phẩm', style: small.copyWith(color: textSecondary)),
                  const SizedBox(height: 20),
                  DesignSystemFormField(
                    label: 'Tên danh mục',
                    required: true,
                    input: TextField(
                      controller: _nameController,
                      decoration: designSystemInputDecoration(
                        hint: 'Nhập tên danh mục',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DesignSystemFormField(
                    label: 'Mô tả danh mục',
                    input: TextField(
                      controller: _descController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: designSystemInputDecoration(
                        hint: 'Nhập mô tả danh mục',
                      ),
                    ),
                    helperText: 'Mô tả ngắn gọn về danh mục sản phẩm này',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Sản phẩm trong danh mục
            designSystemFormCard(
              title: 'Sản phẩm trong danh mục',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chọn phương thức thêm sản phẩm vào danh mục', style: small.copyWith(color: textSecondary)),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: mutedBackground,
                      borderRadius: BorderRadius.circular(borderRadiusMedium),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? cardBackground : Colors.transparent,
                                borderRadius: BorderRadius.circular(borderRadiusMedium),
                                boxShadow: _selectedTab == 0 ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 2)] : [],
                              ),
                              alignment: Alignment.center,
                              child: Text('Gán thủ công', style: labelLarge.copyWith(color: _selectedTab == 0 ? primaryBlue : textSecondary)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? cardBackground : Colors.transparent,
                                borderRadius: BorderRadius.circular(borderRadiusMedium),
                                boxShadow: _selectedTab == 1 ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 2)] : [],
                              ),
                              alignment: Alignment.center,
                              child: Text('Điều kiện tự động', style: labelLarge.copyWith(color: _selectedTab == 1 ? primaryBlue : textSecondary)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedTab == 0) ...[
                    TextField(
                      onChanged: (v) => setState(() => searchText = v),
                      decoration: searchInputDecoration(hint: 'Tìm theo tên sản phẩm...'),
                    ),
                    const SizedBox(height: 8),
                    if (searchText.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: mutedBackground,
                          borderRadius: BorderRadius.circular(borderRadiusSmall),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text('Nhập tên sản phẩm để tìm kiếm', style: small.copyWith(color: textSecondary)),
                      ),
                    if (searchText.isNotEmpty)
                      StreamBuilder<List<Product>>(
                        stream: _productService.getProducts(),
                        builder: (context, snapshot) {
                          final products = (snapshot.data ?? []).where((p) => p.name.toLowerCase().contains(searchText.toLowerCase())).toList();
                          if (products.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Không tìm thấy sản phẩm phù hợp', style: TextStyle(color: Colors.black54)),
                            );
                          }
                          return Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: BorderRadius.circular(borderRadiusLarge),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                // Heading row
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: mutedBackground,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(borderRadiusLarge)),
                                  ),
                                  child: Row(
                                    children: const [
                                      SizedBox(width: 40, child: Text('Chọn', style: TextStyle(fontWeight: FontWeight.bold))),
                                      Expanded(child: Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.bold))),
                                      SizedBox(width: 100, child: Text('Giá bán', style: TextStyle(fontWeight: FontWeight.bold))),
                                      SizedBox(width: 80, child: Text('Số lượng', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                ...products.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final p = entry.value;
                                  return Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: selectedProducts.contains(p) ? primaryBlue.withOpacity(0.06) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(borderRadiusSmall),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              child: Center(
                                                child: SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: Checkbox(
                                                    value: selectedProducts.any((sp) => sp.id == p.id),
                                                    onChanged: (v) {
                                                      setState(() {
                                                        if (v == true && !selectedProducts.any((sp) => sp.id == p.id)) {
                                                          selectedProducts.add(p);
                                                        } else if (v == false && selectedProducts.any((sp) => sp.id == p.id)) {
                                                          selectedProducts.removeWhere((sp) => sp.id == p.id);
                                                        }
                                                      });
                                                    },
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  Text(p.commonName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 110,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text(p.salePrice.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]}."), style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  const SizedBox(width: 2),
                                                  Text('đ', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                                  const SizedBox(width: 18),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 60,
                                              child: Container(
                                                alignment: Alignment.center,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  border: Border.all(color: borderColor),
                                                  borderRadius: BorderRadius.circular(borderRadiusMedium),
                                                ),
                                                child: Text('${p.stock}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (i < products.length - 1)
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 12),
                                          height: 1,
                                          color: Colors.grey.shade200,
                                        ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                  if (selectedProducts.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text('Đã chọn ${selectedProducts.length} sản phẩm', style: const TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() => _showSelectedPanel = !_showSelectedPanel),
                              child: Row(
                                children: [
                                  Text(_showSelectedPanel ? 'Ẩn sản phẩm đã chọn' : 'Xem sản phẩm đã chọn', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 4),
                                  Icon(_showSelectedPanel ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.blue),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_showSelectedPanel && selectedProducts.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: BorderRadius.circular(borderRadiusLarge),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                  decoration: const BoxDecoration(
                                    color: mutedBackground,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadiusLarge)),
                                  ),
                                  child: Text('Sản phẩm đã chọn (${selectedProducts.length})', style: labelLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                                ),
                                const SizedBox(height: 6),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 260),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: selectedProducts.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, i) {
                                      if (i >= 3) return null;
                                      final p = selectedProducts[i];
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: borderColor),
                                          borderRadius: BorderRadius.circular(borderRadiusSmall),
                                          color: cardBackground,
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  Text(p.commonName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Text('${p.salePrice.toStringAsFixed(0)}đ', style: const TextStyle(fontWeight: FontWeight.w500)),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.transparent,
                                                          border: Border.all(color: borderColor),
                                                          borderRadius: BorderRadius.circular(borderRadiusSmall),
                                                        ),
                                                        child: Text('SL: ${p.stock}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, size: 20),
                                              onPressed: () {
                                                setState(() {
                                                  selectedProducts.removeAt(i);
                                                });
                                              },
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
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onBack ?? () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isSaving ? null : _createCategory,
                  style: primaryButtonStyle,
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Tạo danh mục'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 