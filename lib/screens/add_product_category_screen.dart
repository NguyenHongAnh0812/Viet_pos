import 'package:flutter/material.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../services/product_category_service.dart';
import '../services/product_service.dart';
import '../widgets/common/design_system.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductCategoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AddProductCategoryScreen({super.key, this.onBack});

  @override
  State<AddProductCategoryScreen> createState() => _AddProductCategoryScreenState();
}

class _AddProductCategoryScreenState extends State<AddProductCategoryScreen> {
  final _categoryService = ProductCategoryService();
  final _productService = ProductService();
  final _productCategoryLinkService = ProductCategoryLinkService();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();
  String searchText = '';
  List<Product> selectedProducts = [];
  bool isSaving = false;
  bool isManualMode = true; // true: Thủ công, false: Thông minh
  String? _selectedParentId;
  String? _nameError;
  
  // Condition state
  String _selectedConditionType = 'all'; // 'all' or 'any'
  List<ProductCondition> _conditions = [];

  @override
  void initState() {
    super.initState();
    _conditions.add(ProductCondition(
      field: 'sale_price',
      operator: 'equals',
      value: '0',
    ));

    // Add listener for name validation
    _nameController.addListener(_validateName);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateName);
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _validateName() {
    final name = _nameController.text.trim();
    setState(() {
      if (name.isEmpty) {
        _nameError = 'Tên danh mục là bắt buộc';
      } else if (name.length < 2) {
        _nameError = 'Tên danh mục phải có ít nhất 2 ký tự';
      } else {
        _nameError = null;
      }
    });
  }

  void _addCondition() {
    setState(() {
      _conditions.add(ProductCondition(
        field: 'sale_price',
        operator: 'equals',
        value: '0',
      ));
    });
  }

  void _removeCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
    });
  }

  Future<void> _createCategory() async {
    _validateName();
    final name = _nameController.text.trim();
    if (_nameError != null) {
      // Focus the name field if error
      FocusScope.of(context).requestFocus(FocusNode());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_nameError!)),
      );
      return;
    }
    setState(() => isSaving = true);
    try {
      // Create new category and get its ID
      final docRef = await FirebaseFirestore.instance.collection('categories').add({
        'name': name,
        'description': _descController.text.trim(),
        if (_selectedParentId != null) 'parentId': _selectedParentId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      final newCategoryId = docRef.id;

      // Assign products if in manual mode (add to product_category link table)
      if (isManualMode) {
        for (final p in selectedProducts) {
          await _productCategoryLinkService.addProductToCategory(productId: p.id, categoryId: newCategoryId);
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo danh mục thành công!')),
      );
      if (widget.onBack != null) widget.onBack!();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: const Text(
          'Thêm danh mục',
          style: TextStyle(color: Colors.black87, fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: widget.onBack ?? () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: isSaving || _nameError != null ? null : _createCategory,
              style: primaryButtonStyle,
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu'),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column
          Expanded(
            flex: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Info Section
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin danh mục',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tên danh mục',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: designSystemInputDecoration(
                              hint: 'Nhập tên danh mục',
                              errorText: _nameError,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mô tả',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: designSystemInputDecoration(
                              hint: 'Nhập mô tả cho danh mục',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Danh mục cha',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<List<ProductCategory>>(
                            stream: _categoryService.getCategories(),
                            builder: (context, snapshot) {
                              final categories = (snapshot.data ?? []).where((c) => c.parentId == null).toList();
                              final parentOptions = [null, ...categories];
                              return ShopifyDropdown<String?>(
                                items: parentOptions.map((c) => c?.id).toList(),
                                value: _selectedParentId,
                                getLabel: (id) {
                                  if (id == null) return 'Chọn danh mục cha';
                                  final cat = categories.firstWhere(
                                    (c) => c.id == id,
                                    orElse: () => ProductCategory(id: '', name: '', description: ''),
                                  );
                                  return cat.name.isNotEmpty ? cat.name : '(Không xác định)';
                                },
                                onChanged: (val) => setState(() => _selectedParentId = val),
                                hint: 'Chọn danh mục cha',
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Category Type Section
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Loại danh mục',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Column(
                        children: [
                          RadioListTile<bool>(
                            title: const Text(
                              'Thủ công',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: const Text(
                              'Thêm từng sản phẩm vào danh mục này.',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: true,
                            groupValue: isManualMode,
                            onChanged: (value) {
                              setState(() => isManualMode = value!);
                            },
                          ),
                          const SizedBox(height: 8),
                          RadioListTile<bool>(
                            title: const Text(
                              'Thông minh',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: const Text(
                              'Các sản phẩm hiện tại và tương lai phù hợp với các điều kiện bạn đặt sẽ tự động được thêm vào danh mục này.',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: false,
                            groupValue: isManualMode,
                            onChanged: (value) {
                              setState(() => isManualMode = value!);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isManualMode) ...[
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Điều kiện',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Sản phẩm phải phù hợp:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Radio<String>(
                              value: 'all',
                              groupValue: _selectedConditionType,
                              onChanged: (value) {
                                setState(() => _selectedConditionType = value!);
                              },
                            ),
                            const Text(
                              'Tất cả các điều kiện',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Radio<String>(
                              value: 'any',
                              groupValue: _selectedConditionType,
                              onChanged: (value) {
                                setState(() => _selectedConditionType = value!);
                              },
                            ),
                            const Text(
                              'Bất kỳ điều kiện nào',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ..._conditions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final condition = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ShopifyDropdown<String>(
                                    value: condition.field,
                                    items: const ['sale_price', 'stock_system', 'name'],
                                    getLabel: (value) {
                                      switch (value) {
                                        case 'sale_price':
                                          return 'Giá bán';
                                        case 'stock_system':
                                          return 'Số lượng';
                                        case 'name':
                                          return 'Tên sản phẩm';
                                        default:
                                          return value;
                                      }
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _conditions[index] = condition.copyWith(field: value);
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ShopifyDropdown<String>(
                                    value: condition.operator,
                                    items: const ['equals', 'greater_than', 'less_than', 'contains'],
                                    getLabel: (value) {
                                      switch (value) {
                                        case 'equals':
                                          return 'bằng';
                                        case 'greater_than':
                                          return 'lớn hơn';
                                        case 'less_than':
                                          return 'nhỏ hơn';
                                        case 'contains':
                                          return 'chứa';
                                        default:
                                          return value;
                                      }
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _conditions[index] = condition.copyWith(operator: value);
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: designSystemInputDecoration(
                                      hint: 'Giá trị',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _conditions[index] = condition.copyWith(value: value);
                                      });
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => _removeCondition(index),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFF7F9FC),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _addCondition,
                            icon: const Icon(Icons.add, color: textPrimary),
                            label: const Text(
                              'Thêm điều kiện',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Right column
          Container(
            width: 1,
            height: double.infinity,
            color: borderColor,
          ),
          Expanded(
            flex: 9,
            child: Container(
              height: double.infinity,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sản phẩm trong danh mục',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedProducts.length} sản phẩm được chọn thủ công',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (isManualMode) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            decoration: searchInputDecoration(
                              hint: 'Tìm kiếm sản phẩm để thêm...',
                            ),
                            onChanged: (v) => setState(() => searchText = v),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isManualMode)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [              
                            // Block: Sản phẩm đã chọn (chỉ hiển thị nếu có sản phẩm)
                            if (selectedProducts.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                                      child: Text(
                                        'Sản phẩm đã chọn (${selectedProducts.length})',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textPrimary),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        children: const [
                                          Expanded(
                                            flex: 7,
                                            child: Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textSecondary)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textSecondary)),
                                          ),
                                          SizedBox(width: 32),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: selectedProducts.length,
                                      separatorBuilder: (context, index) => const Divider(height: 1, color: borderColor),
                                      itemBuilder: (context, index) {
                                        final p = selectedProducts[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 7,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(p.internalName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                                    Text(p.tradeName, style: const TextStyle(fontSize: 13, color: textSecondary)),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(p.stockSystem.toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close, size: 20),
                                                splashRadius: 20,
                                                onPressed: () {
                                                  setState(() {
                                                    selectedProducts.remove(p);
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
                            // Block: Kết quả tìm kiếm (chỉ hiển thị khi có searchText)
                            if (searchText.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                                      child: const Text(
                                        'Kết quả tìm kiếm',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textPrimary),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    StreamBuilder<List<Product>>(
                                      stream: _productService.getProducts(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        final products = (snapshot.data ?? [])
                                            .where((p) => p.internalName.toLowerCase().contains(searchText.toLowerCase()) && !selectedProducts.contains(p))
                                            .toList();
                                        if (products.isEmpty) {
                                          return const Center(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(vertical: 32),
                                              child: Text('Không tìm thấy sản phẩm phù hợp', style: TextStyle(color: Colors.grey)),
                                            ),
                                          );
                                        }
                                        return ListView.separated(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: products.length,
                                          separatorBuilder: (context, index) => const Divider(height: 1, color: borderColor),
                                          itemBuilder: (context, index) {
                                            final product = products[index];
                                            return InkWell(
                                              onTap: () {
                                                setState(() {
                                                  selectedProducts.add(product);
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      flex: 7,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(product.internalName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                                          Text(product.tradeName, style: const TextStyle(fontSize: 13, color: textSecondary)),
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(top: 2),
                                                        child: Text(product.stockSystem.toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
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
}

class ProductCondition {
  final String field;
  final String operator;
  final String value;

  ProductCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  ProductCondition copyWith({
    String? field,
    String? operator,
    String? value,
  }) {
    return ProductCondition(
      field: field ?? this.field,
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final bool showRemove;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  const _ProductRow({
    required this.product,
    this.showRemove = false,
    this.onRemove,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.internalName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(product.tradeName, style: const TextStyle(fontSize: 13, color: textSecondary)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(product.stockSystem.toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            if (showRemove)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                splashRadius: 20,
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
} 