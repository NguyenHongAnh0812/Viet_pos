import 'package:flutter/material.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../services/product_category_service.dart';
import '../services/product_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên danh mục là bắt buộc!')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo danh mục thành công!')));
      if (widget.onBack != null) widget.onBack!();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  const Text('Nhập thông tin cơ bản cho danh mục sản phẩm', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên danh mục *',
                      hintText: 'Nhập tên danh mục',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả danh mục',
                      hintText: 'Nhập mô tả danh mục',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Mô tả ngắn gọn về danh mục sản phẩm này', style: TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Sản phẩm trong danh mục
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sản phẩm trong danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  const Text('Chọn phương thức thêm sản phẩm vào danh mục', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  // Tabs
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _selectedTab == 0 ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 2)] : [],
                              ),
                              alignment: Alignment.center,
                              child: Text('Gán thủ công', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedTab == 0 ? Colors.blue : Colors.black54)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _selectedTab == 1 ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 2)] : [],
                              ),
                              alignment: Alignment.center,
                              child: Text('Điều kiện tự động', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedTab == 1 ? Colors.blue : Colors.black54)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedTab == 0) ...[
                    TextField(
                      onChanged: (v) => setState(() => searchText = v),
                      decoration: const InputDecoration(
                        hintText: 'Tìm theo tên sản phẩm...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (searchText.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Text('Nhập tên sản phẩm để tìm kiếm', style: TextStyle(color: Colors.black54)),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                // Heading row
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                                          color: selectedProducts.contains(p) ? Colors.blue.withOpacity(0.06) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
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
                                                  Text('${p.salePrice.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                                  border: Border.all(color: Colors.grey.shade400),
                                                  borderRadius: BorderRadius.circular(12),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF6F8FA),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                  ),
                                  child: Text('Sản phẩm đã chọn (${selectedProducts.length})', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                                          border: Border.all(color: Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.white,
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
                                                          border: Border.all(color: Colors.grey),
                                                          borderRadius: BorderRadius.circular(8),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3a6ff8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Tạo danh mục'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 