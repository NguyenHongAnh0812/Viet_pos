import 'package:flutter/material.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../services/product_category_service.dart';
import '../services/product_service.dart';
import '../widgets/common/design_system.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductField {
  salePrice,
  costPrice,
  tags,
  stockSystem
}

extension ProductFieldExtension on ProductField {
  String getDisplayText() {
    switch (this) {
      case ProductField.salePrice:
        return 'Giá bán';
      case ProductField.costPrice:
        return 'Giá nhập';
      case ProductField.tags:
        return 'Tags';
      case ProductField.stockSystem:
        return 'Tồn kho hệ thống';
    }
  }
}

enum ConditionOperator {
  equals,
  greaterThan,
  lessThan,
  between,
  contains,
  notContains
}

extension ConditionOperatorExtension on ConditionOperator {
  String getOperatorText() {
    switch (this) {
      case ConditionOperator.equals:
        return 'bằng';
      case ConditionOperator.greaterThan:
        return 'lớn hơn';
      case ConditionOperator.lessThan:
        return 'nhỏ hơn';
      case ConditionOperator.between:
        return 'trong khoảng';
      case ConditionOperator.contains:
        return 'chứa';
      case ConditionOperator.notContains:
        return 'không chứa';
    }
  }
}

class ProductCondition {
  ProductField field;
  ConditionOperator operator;
  dynamic value;
  dynamic value2; // For 'between' operator

  ProductCondition({
    required this.field,
    required this.operator,
    required this.value,
    this.value2,
  });

  String getDisplayText() {
    switch (field) {
      case ProductField.salePrice:
        return 'Giá bán';
      case ProductField.costPrice:
        return 'Giá nhập';
      case ProductField.tags:
        return 'Tags';
      case ProductField.stockSystem:
        return 'Tồn kho hệ thống';
    }
  }

  String getOperatorText() {
    switch (operator) {
      case ConditionOperator.equals:
        return 'bằng';
      case ConditionOperator.greaterThan:
        return 'lớn hơn';
      case ConditionOperator.lessThan:
        return 'nhỏ hơn';
      case ConditionOperator.between:
        return 'trong khoảng';
      case ConditionOperator.contains:
        return 'chứa';
      case ConditionOperator.notContains:
        return 'không chứa';
    }
  }

  bool evaluate(Product product) {
    switch (field) {
      case ProductField.salePrice:
        return _evaluateNumeric(product.salePrice);
      case ProductField.costPrice:
        return _evaluateNumeric(product.costPrice);
      case ProductField.stockSystem:
        return _evaluateNumeric(product.stockSystem.toDouble());
      case ProductField.tags:
        return _evaluateTags(product.tags);
    }
  }

  bool _evaluateNumeric(double productValue) {
    switch (operator) {
      case ConditionOperator.equals:
        return productValue == (double.tryParse(value.toString()) ?? 0);
      case ConditionOperator.greaterThan:
        return productValue > (double.tryParse(value.toString()) ?? 0);
      case ConditionOperator.lessThan:
        return productValue < (double.tryParse(value.toString()) ?? 0);
      case ConditionOperator.between:
        final min = double.tryParse(value.toString()) ?? 0;
        final max = double.tryParse(value2.toString()) ?? 0;
        return productValue >= min && productValue <= max;
      default:
        return false;
    }
  }

  bool _evaluateTags(List<String> productTags) {
    final tagValue = value.toString().toLowerCase();
    switch (operator) {
      case ConditionOperator.contains:
        return productTags.any((tag) => tag.toLowerCase().contains(tagValue));
      case ConditionOperator.notContains:
        return !productTags.any((tag) => tag.toLowerCase().contains(tagValue));
      default:
        return false;
    }
  }
}

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
      field: ProductField.salePrice,
      operator: ConditionOperator.equals,
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
        field: ProductField.salePrice,
        operator: ConditionOperator.equals,
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
        'is_smart': !isManualMode,
        if (!isManualMode) ...{
          'condition_type': _selectedConditionType,
          'conditions': _conditions.map((c) => {
            'field': c.field.toString(),
            'operator': c.operator.toString(),
            'value': c.value,
            'value2': c.value2,
          }).toList(),
        },
      });
      final newCategoryId = docRef.id;

      // Assign products based on mode
      if (isManualMode) {
        // Manual mode: directly assign selected products
      for (final p in selectedProducts) {
          await _productCategoryLinkService.addProductToCategory(productId: p.id, categoryId: newCategoryId);
        }
      } else {
        // Smart mode: evaluate conditions and assign matching products
        final products = await _productService.getProducts().first;
        final matchingProducts = products.where((product) {
          if (_selectedConditionType == 'all') {
            return _conditions.every((condition) => condition.evaluate(product));
          } else {
            return _conditions.any((condition) => condition.evaluate(product));
          }
        }).toList();

        // Batch assign matching products to product_category table
        final batch = FirebaseFirestore.instance.batch();
        for (final product in matchingProducts) {
          final linkRef = FirebaseFirestore.instance.collection('product_category').doc();
          batch.set(linkRef, {
            'product_id': product.id,
            'category_id': newCategoryId,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
      
      // Show success message with product count
      final message = isManualMode 
          ? 'Tạo danh mục thành công với ${selectedProducts.length} sản phẩm!'
          : 'Tạo danh mục thông minh thành công! Các sản phẩm phù hợp sẽ được tự động thêm vào danh mục.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
    return Container(
      color: appBackground,
      child: Column(
          children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: widget.onBack ?? () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Thêm danh mục',
                    style: TextStyle(
                      color: Colors.black87, 
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onBack ?? () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
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
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  flex: 11,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Info Section
                        Container(
                          padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 24),
                        // Category Type Section
                        Container(
                          padding: const EdgeInsets.all(24),
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
                              const SizedBox(height: 14),
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
                                  const SizedBox(height: 2),
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
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
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
                                const SizedBox(height: 24),
                                ..._conditions.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final condition = entry.value;
                                  return _buildConditionRow(condition, index);
                                }).toList(),
                                Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  child: OutlinedButton.icon(
                                    onPressed: _addCondition,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Thêm điều kiện'),
                                    style: secondaryButtonStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
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
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
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
                              if (isManualMode) ...[
                                Text(
                                  '${selectedProducts.length} sản phẩm được chọn thủ công',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
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
                        Expanded(
                          child: SingleChildScrollView(
                            child: isManualMode
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Block: Sản phẩm đã chọn (chỉ hiển thị nếu có sản phẩm)
                                      if (selectedProducts.isNotEmpty)
                                      Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
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
                                          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                                  )
                                : Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    child: _buildPreviewSectionStyled(),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionRow(ProductCondition condition, int index) {
    final isNumericField = condition.field == ProductField.salePrice || 
                          condition.field == ProductField.costPrice || 
                          condition.field == ProductField.stockSystem;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ShopifyDropdown<ProductField>(
              value: condition.field,
              items: ProductField.values,
              getLabel: (field) => field.getDisplayText(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _conditions[index] = ProductCondition(
                    field: value,
                    operator: value == ProductField.tags ? ConditionOperator.contains : ConditionOperator.equals,
                    value: '0',
                  );
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ShopifyDropdown<ConditionOperator>(
              value: condition.operator,
              items: isNumericField 
                ? [ConditionOperator.equals, ConditionOperator.greaterThan, ConditionOperator.lessThan, ConditionOperator.between]
                : [ConditionOperator.contains, ConditionOperator.notContains],
              getLabel: (op) => op.getOperatorText(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _conditions[index] = ProductCondition(
                    field: condition.field,
                    operator: value,
                    value: condition.value,
                    value2: condition.value2,
                  );
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          if (condition.operator == ConditionOperator.between) ...[
            // Range input for between operator
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: designSystemInputDecoration(
                        hint: 'Từ',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _conditions[index] = ProductCondition(
                            field: condition.field,
                            operator: condition.operator,
                            value: value,
                            value2: condition.value2,
                          );
                        });
                      },
                      controller: TextEditingController(text: condition.value?.toString() ?? ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: designSystemInputDecoration(
                        hint: 'Đến',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _conditions[index] = ProductCondition(
                            field: condition.field,
                            operator: condition.operator,
                            value: condition.value,
                            value2: value,
                          );
                        });
                      },
                      controller: TextEditingController(text: condition.value2?.toString() ?? ''),
                              ),
                            ),
                          ],
                        ),
            ),
          ] else ...[
            // Single value input
            Expanded(
              flex: 2,
              child: TextField(
                decoration: designSystemInputDecoration(
                  hint: isNumericField ? 'Nhập số' : 'Nhập giá trị',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: isNumericField ? TextInputType.number : TextInputType.text,
                onChanged: (value) {
                  setState(() {
                    _conditions[index] = ProductCondition(
                      field: condition.field,
                      operator: condition.operator,
                      value: value,
                    );
                  });
                },
                controller: TextEditingController(text: condition.value?.toString() ?? ''),
              ),
            ),
          ],
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _removeCondition(index),
          ),
        ],
      ),
    );
  }

  // Thay thế _buildPreviewSection bằng phiên bản style giống thủ công
  dynamic _buildPreviewSectionStyled() {
    return StreamBuilder<List<Product>>(
      stream: _productService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allProducts = snapshot.data ?? [];
        final matchingProducts = allProducts.where((product) {
          if (_selectedConditionType == 'all') {
            return _conditions.every((condition) => condition.evaluate(product));
          } else {
            return _conditions.any((condition) => condition.evaluate(product));
          }
        }).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xem trước: ${matchingProducts.length} sản phẩm phù hợp',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (matchingProducts.isEmpty)
              const Text('Không có sản phẩm phù hợp', style: TextStyle(color: Colors.grey)),
            if (matchingProducts.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                    // Header row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Expanded(
                                flex: 7,
                                child: Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textSecondary)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textSecondary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                                Container(
                            height: 1,
                            color: borderColor,
                          ),
                        ],
                      ),
                    ),
                    // Product list
                    Container(
                      constraints: const BoxConstraints(maxHeight: 350),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                        itemCount: matchingProducts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: borderColor),
                        itemBuilder: (context, index) {
                          final p = matchingProducts[index];
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
        );
      },
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