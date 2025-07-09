import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_category.dart';
import '../../widgets/common/design_system.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/product_category_service.dart';
import '../../services/product_category_relation_service.dart';
import '../../models/product_category_relation.dart';

class EditProductCategoryScreen extends StatefulWidget {
  final ProductCategory category;
  final VoidCallback? onBack;
  const EditProductCategoryScreen({super.key, required this.category, this.onBack});

  @override
  State<EditProductCategoryScreen> createState() => _EditProductCategoryScreenState();
}

class _EditProductCategoryScreenState extends State<EditProductCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _selectedParentId;
  String? _nameError;
  bool _isSaving = false;

  final ProductService _productService = ProductService();
  final ProductCategoryService _categoryService = ProductCategoryService();
  final ProductCategoryRelationService _relationService = ProductCategoryRelationService();
  List<Product> _allProducts = [];
  List<Product> _selectedProducts = [];
  List<ProductCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Fill dữ liệu từ category hiện tại
    _nameController.text = widget.category.name;
    _descController.text = widget.category.description;
    _selectedParentId = widget.category.parentId;

    // Load danh sách categories cho dropdown
    await _loadCategories();

    // Load danh sách sản phẩm
    final products = await _productService.getProducts().first;
    setState(() {
      _allProducts = products;
    });

    // Load sản phẩm đã được liên kết với category này
    await _loadLinkedProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        _categories = snapshot.docs.map((doc) => ProductCategory.fromFirestore(doc)).toList();
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadLinkedProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('product_categories')
          .where('category_id', isEqualTo: widget.category.id)
          .get();
      
      final productIds = snapshot.docs.map((doc) => doc.data()['product_id']).toList();
      final linkedProducts = _allProducts.where((p) => productIds.contains(p.id)).toList();
      
      setState(() {
        _selectedProducts = linkedProducts;
      });
    } catch (e) {
      print('Error loading linked products: $e');
    }
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
      // Cập nhật category
      final updatedCategory = widget.category.copyWith(
        name: name,
        description: _descController.text.trim(),
        parentId: _selectedParentId,
      );
      
      await _categoryService.updateCategorySimple(updatedCategory);
      
      // Cập nhật liên kết sản phẩm-danh mục
      await _updateProductCategoryRelations();
      
      showSuccessSnackBar(context, 'Cập nhật danh mục thành công');
      Navigator.of(context).pop(true); // CHỈ trả về true khi lưu thành công
    } catch (e) {
      showErrorSnackBar(context, 'Lỗi: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _updateProductCategoryRelations() async {
    // Xóa tất cả liên kết cũ
    await _relationService.deleteProductCategoryByCategoryId(widget.category.id);
    
    // Thêm liên kết mới
    if (_selectedProducts.isNotEmpty) {
      for (final product in _selectedProducts) {
        await _relationService.addProductCategory(ProductCategoryRelation(
          id: '',
          productId: product.id,
          categoryId: widget.category.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }
  }

  // Sắp xếp categories theo cây thư mục
  List<ProductCategory> _buildCategoryTree(List<ProductCategory> categories) {
    final Map<String?, List<ProductCategory>> categoryTree = {};
    
    // Nhóm categories theo parentId
    for (var category in categories) {
      final parentId = category.parentId;
      categoryTree.putIfAbsent(parentId, () => []).add(category);
    }
    
    // Sắp xếp từng nhóm theo tên
    categoryTree.forEach((key, value) {
      value.sort((a, b) => a.name.compareTo(b.name));
    });
    
    // Tạo danh sách phẳng theo thứ tự cây
    List<ProductCategory> result = [];
    void addCategories(String? parentId, int level) {
      final children = categoryTree[parentId] ?? [];
      for (var child in children) {
        // Cập nhật level nếu chưa có
        if (child.level == null) {
          child = child.copyWith(level: level);
        }
        result.add(child);
        // Đệ quy cho các con
        addCategories(child.id, level + 1);
      }
    }
    
    addCategories(null, 0);
    return result;
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
          onPressed: widget.onBack ?? () => Navigator.pop(context), // KHÔNG trả về true
        ),
        title: Text(
          'Sửa danh mục',
          style: h3.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : widget.onBack ?? () => Navigator.pop(context), // KHÔNG trả về true
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: const BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  minimumSize: const Size(0, 48),
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
                  minimumSize: const Size(0, 48),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Lưu thay đổi'),
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
                    _ParentCategorySelector(
                      selectedId: _selectedParentId,
                      onChanged: (id) => setState(() => _selectedParentId = id),
                      categories: _categories,
                      excludeCategoryId: widget.category.id, // Không cho phép chọn chính nó làm parent
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

class _ParentCategorySelector extends StatefulWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final List<ProductCategory> categories;
  final String? excludeCategoryId; // Không cho phép chọn category này làm parent
  const _ParentCategorySelector({
    required this.selectedId, 
    required this.onChanged, 
    required this.categories,
    this.excludeCategoryId,
  });

  @override
  State<_ParentCategorySelector> createState() => _ParentCategorySelectorState();
}

class _ParentCategorySelectorState extends State<_ParentCategorySelector> {
  void _showCategoryPicker() async {
    // Lọc bỏ category cần exclude và các con của nó
    final filteredCategories = widget.categories.where((cat) {
      if (cat.id == widget.excludeCategoryId) return false;
      // Kiểm tra xem có phải là con của category bị exclude không
      if (widget.excludeCategoryId != null) {
        final excludeCategory = widget.categories.firstWhere(
          (c) => c.id == widget.excludeCategoryId,
          orElse: () => ProductCategory(id: '', name: ''),
        );
        if (excludeCategory.path != null && cat.path != null) {
          if (cat.path!.startsWith(excludeCategory.path!)) return false;
        }
      }
      return true;
    }).toList();
    
    final sortedCategories = _buildCategoryTree(filteredCategories);
    
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.category, color: mainGreen, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chọn danh mục cha',
                      style: h3.copyWith(color: textPrimary),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: textSecondary),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Option "Không chọn"
                  InkWell(
                    onTap: () => Navigator.pop(context, null),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: widget.selectedId == null ? mainGreen.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: widget.selectedId == null ? mainGreen : textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Không chọn danh mục cha',
                            style: bodyLarge.copyWith(
                              color: widget.selectedId == null ? mainGreen : textPrimary,
                              fontWeight: widget.selectedId == null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Categories list
                  ...sortedCategories.map((cat) {
                    final level = cat.level ?? 0;
                    final isSelected = widget.selectedId == cat.id;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        onTap: () => Navigator.pop(context, cat.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.only(
                            left: 16 + (level * 20),
                            right: 16,
                            top: 10,
                            bottom: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? mainGreen.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Icon theo level
                              Icon(
                                level == 0 ? Icons.category : Icons.subdirectory_arrow_right,
                                color: isSelected ? mainGreen : (level == 0 ? textPrimary : textSecondary),
                                size: level == 0 ? 18 : 14,
                              ),
                              const SizedBox(width: 12),
                              // Text với style theo level
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: bodyLarge.copyWith(
                                    color: isSelected ? mainGreen : (level == 0 ? textPrimary : textSecondary),
                                    fontWeight: level == 0 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: mainGreen, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    
    if (result != null) {
      widget.onChanged(result);
    }
  }

  // Sắp xếp categories theo cây thư mục
  List<ProductCategory> _buildCategoryTree(List<ProductCategory> categories) {
    final Map<String?, List<ProductCategory>> categoryTree = {};
    
    // Nhóm categories theo parentId
    for (var category in categories) {
      final parentId = category.parentId;
      categoryTree.putIfAbsent(parentId, () => []).add(category);
    }
    
    // Sắp xếp từng nhóm theo tên
    categoryTree.forEach((key, value) {
      value.sort((a, b) => a.name.compareTo(b.name));
    });
    
    // Tạo danh sách phẳng theo thứ tự cây
    List<ProductCategory> result = [];
    void addCategories(String? parentId, int level) {
      final children = categoryTree[parentId] ?? [];
      for (var child in children) {
        // Cập nhật level nếu chưa có
        if (child.level == null) {
          child = child.copyWith(level: level);
        }
        result.add(child);
        // Đệ quy cho các con
        addCategories(child.id, level + 1);
      }
    }
    
    addCategories(null, 0);
    return result;
  }

  String _getSelectedCategoryName() {
    if (widget.selectedId == null) return 'Chọn danh mục cha (tùy chọn)';
    final selected = widget.categories.firstWhere(
      (cat) => cat.id == widget.selectedId,
      orElse: () => ProductCategory(id: '', name: 'Không tìm thấy'),
    );
    return selected.name;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showCategoryPicker,
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      child: Container(
        height: inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: inputPadding, vertical: 8),
        decoration: BoxDecoration(
          color: cardBackground,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _getSelectedCategoryName(),
                style: body.copyWith(
                  color: widget.selectedId == null ? textSecondary : textPrimary,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: textSecondary),
          ],
        ),
      ),
    );
  }
} 