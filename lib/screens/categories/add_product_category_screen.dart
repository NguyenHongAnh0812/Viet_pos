import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_category.dart';
import '../../widgets/common/design_system.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/product_category_relation_service.dart';
import '../../models/product_category_relation.dart';

class AddProductCategoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AddProductCategoryScreen({super.key, this.onBack});

  @override
  State<AddProductCategoryScreen> createState() => _AddProductCategoryScreenState();
}

class _AddProductCategoryScreenState extends State<AddProductCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _selectedParentId;
  String? _nameError;
  bool _isSaving = false;

  final ProductService _productService = ProductService();
  final ProductCategoryRelationService _relationService = ProductCategoryRelationService();
  List<Product> _allProducts = [];
  List<Product> _selectedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _productService.getProducts().first;
    setState(() {
      _allProducts = products;
    });
  }

  void _showProductPicker() async {
    final result = await showModalBottomSheet<List<Product>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final Set<String> tempSelected = Set.from(_selectedProducts.map((e) => e.id));
        TextEditingController searchController = TextEditingController();
        List<Product> filteredProducts = List.from(_allProducts);
        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterProducts(String query) {
              setModalState(() {
                filteredProducts = _allProducts.where((p) {
                  final q = query.toLowerCase();
                  return p.tradeName.toLowerCase().contains(q) ||
                         (p.sku ?? '').toLowerCase().contains(q) ||
                         (p.barcode ?? '').toLowerCase().contains(q);
                }).toList();
              });
            }
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chọn sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: mainGreen)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sản phẩm, SKU, mã vạch...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                        onChanged: filterProducts,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, i) {
                            final p = filteredProducts[i];
                            final selected = tempSelected.contains(p.id);
                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  if (selected) {
                                    tempSelected.remove(p.id);
                                  } else {
                                    tempSelected.add(p.id);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected ? Color(0xFFF0FDF4) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.tradeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text('SKU: ${p.sku ?? ''} | Tồn: ${p.stockSystem} ${p.unit}', style: const TextStyle(color: textSecondary, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      selected ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: selected ? mainGreen : Colors.grey[300],
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Hủy'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final selected = _allProducts.where((p) => tempSelected.contains(p.id)).toList();
                                Navigator.pop(context, selected);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
                              child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedProducts = result;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Tên danh mục là bắt buộc');
      return;
    }
    setState(() => _isSaving = true);
    try {
      // Lưu danh mục
      final docRef = await FirebaseFirestore.instance.collection('categories').add({
        'name': name,
        'description': _descController.text.trim(),
        if (_selectedParentId != null) 'parentId': _selectedParentId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      // Lưu liên kết sản phẩm-danh mục
      if (_selectedProducts.isNotEmpty) {
        for (final product in _selectedProducts) {
          await _relationService.addProductCategory(ProductCategoryRelation(
            id: '',
            productId: product.id,
            categoryId: docRef.id,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: mainGreen,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(
          color: Colors.white,
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: const Text(
          'Thêm danh mục',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // tăng vertical
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : widget.onBack ?? () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: const BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  minimumSize: const Size(0, 48), // tăng chiều cao
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Hủy'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  minimumSize: const Size(0, 48), // tăng chiều cao
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Lưu danh mục'),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
                // Block 1: Thông tin danh mục
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thông tin danh mục', style: bodyLarge.copyWith(color: mainGreen, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text('Tên danh mục *', style: bodyLarge.copyWith(fontWeight: FontWeight.w600, color: textPrimary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: designSystemInputDecoration(
                          hint: 'Nhập tên danh mục',
                          errorText: _nameError,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) {
                          if (_nameError != null) setState(() => _nameError = null);
                        },
                      ),
                      if (_nameError != null && _nameError!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(_nameError!, style: caption.copyWith(color: destructiveRed)),
                      ],
                      const SizedBox(height: 16),
                      Text('Mô tả', style: bodyLarge.copyWith(fontWeight: FontWeight.w600, color: textPrimary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: designSystemInputDecoration(
                          hint: 'Nhập mô tả danh mục (tùy chọn)',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Danh mục cha', style: bodyLarge.copyWith(fontWeight: FontWeight.w600, color: textPrimary)),
                      const SizedBox(height: 8),
                      _ParentCategoryDropdown(
                        selectedId: _selectedParentId,
                        onChanged: (id) => setState(() => _selectedParentId = id),
                      ),
                      const SizedBox(height: 4),
                      Text('Không bắt buộc', style: caption.copyWith(color: textSecondary)),
                    ],
                  ),
                ),
                // Khoảng cách giữa 2 block
                const SizedBox(height: 24),
                // Block 2: Danh sách sản phẩm
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Danh sách sản phẩm', style: bodyLarge.copyWith(color: mainGreen, fontWeight: FontWeight.bold))),
                          Text(' ${_selectedProducts.length} sản phẩm', style: body.copyWith(color: textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sản phẩm đã chọn:', style: TextStyle(fontWeight: FontWeight.w500)),
                          ElevatedButton.icon(
                            onPressed: _showProductPicker,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Thêm sản phẩm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: mainGreen,
                              side: const BorderSide(color: mainGreen),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedProducts.isEmpty)
                        const Text('Chưa có sản phẩm nào được chọn.'),
                      ..._selectedProducts.map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.tradeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('SKU: ${p.sku ?? ''} | Tồn: ${p.stockSystem} ${p.unit}', style: const TextStyle(color: textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: mainGreen),
                              onPressed: () {
                                setState(() {
                                  _selectedProducts.removeWhere((item) => item.id == p.id);
                                });
                              },
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentCategoryDropdown extends StatefulWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  const _ParentCategoryDropdown({required this.selectedId, required this.onChanged});

  @override
  State<_ParentCategoryDropdown> createState() => _ParentCategoryDropdownState();
}

class _ParentCategoryDropdownState extends State<_ParentCategoryDropdown> {
  List<ProductCategory> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      _categories = snapshot.docs.map((doc) => ProductCategory.fromFirestore(doc)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Lọc chỉ lấy 2 cấp đầu: root và con trực tiếp
    final rootCategories = _categories.where((cat) => cat.parentId == null || cat.parentId == '').toList();
    final level1Categories = _categories.where((cat) => rootCategories.any((root) => cat.parentId == root.id)).toList();
    final parentOptions = [
      null,
      ...rootCategories,
      ...level1Categories,
    ];
    return DesignSystemDropdownMenu<String?>(
      value: widget.selectedId,
      items: parentOptions.map((cat) {
        if (cat == null) {
          return const DropdownMenuItem<String?>(
            value: null,
            child: Text('Chọn danh mục cha (tùy chọn)'),
          );
        }
        // Nếu là level 1 thì thụt vào
        return DropdownMenuItem<String?>(
          value: cat.id,
          child: cat.level == 1
              ? Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(cat.name),
                )
              : Text(cat.name),
        );
      }).toList(),
      onChanged: widget.onChanged,
      hint: 'Chọn danh mục cha (tùy chọn)',
    );
  }
} 