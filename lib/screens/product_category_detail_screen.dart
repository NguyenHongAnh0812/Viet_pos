import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../services/product_category_service.dart';
import '../services/product_service.dart';
import '../widgets/common/design_system.dart';

// --- Enums and Classes copied from add_product_category_screen.dart ---
enum ProductField { salePrice, costPrice, tags, stockSystem }

extension ProductFieldExtension on ProductField {
  String getDisplayText() {
    switch (this) {
      case ProductField.salePrice: return 'Giá bán';
      case ProductField.costPrice: return 'Giá nhập';
      case ProductField.tags: return 'Tags';
      case ProductField.stockSystem: return 'Tồn kho hệ thống';
    }
  }
}

enum ConditionOperator { equals, greaterThan, lessThan, between, contains, notContains }

extension ConditionOperatorExtension on ConditionOperator {
  String getOperatorText() {
    switch (this) {
      case ConditionOperator.equals: return 'bằng';
      case ConditionOperator.greaterThan: return 'lớn hơn';
      case ConditionOperator.lessThan: return 'nhỏ hơn';
      case ConditionOperator.between: return 'trong khoảng';
      case ConditionOperator.contains: return 'chứa';
      case ConditionOperator.notContains: return 'không chứa';
    }
  }
}

class ProductCondition {
  ProductField field;
  ConditionOperator operator;
  dynamic value;
  dynamic value2;

  ProductCondition({ required this.field, required this.operator, required this.value, this.value2 });

  factory ProductCondition.fromMap(Map<String, dynamic> map) {
    return ProductCondition(
      field: ProductField.values.firstWhere((e) => e.toString() == map['field'], orElse: () => ProductField.salePrice),
      operator: ConditionOperator.values.firstWhere((e) => e.toString() == map['operator'], orElse: () => ConditionOperator.equals),
      value: map['value'],
      value2: map['value2'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'field': field.toString(),
      'operator': operator.toString(),
      'value': value,
      'value2': value2,
    };
  }
  
  bool evaluate(Product product) {
    switch (field) {
      case ProductField.salePrice: return _evaluateNumeric(product.salePrice);
      case ProductField.costPrice: return _evaluateNumeric(product.costPrice);
      case ProductField.stockSystem: return _evaluateNumeric(product.stockSystem.toDouble());
      case ProductField.tags: return _evaluateTags(product.tags);
    }
  }

  bool _evaluateNumeric(double productValue) {
    switch (operator) {
      case ConditionOperator.equals: return productValue == (double.tryParse(value.toString()) ?? 0);
      case ConditionOperator.greaterThan: return productValue > (double.tryParse(value.toString()) ?? 0);
      case ConditionOperator.lessThan: return productValue < (double.tryParse(value.toString()) ?? 0);
      case ConditionOperator.between:
        final min = double.tryParse(value.toString()) ?? 0;
        final max = double.tryParse(value2.toString()) ?? 0;
        return productValue >= min && productValue <= max;
      default: return false;
    }
  }

  bool _evaluateTags(List<String> productTags) {
    final tagValue = value.toString().toLowerCase();
    switch (operator) {
      case ConditionOperator.contains: return productTags.any((tag) => tag.toLowerCase().contains(tagValue));
      case ConditionOperator.notContains: return !productTags.any((tag) => tag.toLowerCase().contains(tagValue));
      default: return false;
    }
  }
}

// --- ProductCategoryDetailScreen ---
class ProductCategoryDetailScreen extends StatefulWidget {
  final ProductCategory category;
  final VoidCallback? onBack;

  const ProductCategoryDetailScreen({super.key, required this.category, this.onBack});

  @override
  _ProductCategoryDetailScreenState createState() => _ProductCategoryDetailScreenState();
}

class _ProductCategoryDetailScreenState extends State<ProductCategoryDetailScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _searchController;
  
  // State variables
  bool isSaving = false;
  String? _nameError;
  String? _selectedParentId;
  late bool isManualMode;
  String searchText = '';
  List<Product> selectedProducts = [];
  List<ProductCondition> _conditions = [];
  late String _selectedConditionType;

  // Services
  final _categoryService = ProductCategoryService();
  final _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _descController = TextEditingController(text: widget.category.description);
    _searchController = TextEditingController();

    isManualMode = widget.category.isSmart == false;
    _selectedParentId = widget.category.parentId;
    _selectedConditionType = widget.category.conditionType ?? 'all';
    _conditions = widget.category.conditions?.map((c) => ProductCondition.fromMap(c)).toList() ?? [];

    if (_conditions.isEmpty && !isManualMode) {
      _addCondition();
    }

    if (isManualMode) {
      _loadSelectedProducts();
    }
    _nameController.addListener(_validateName);
  }
  
  Future<void> _loadSelectedProducts() async {
    final productIds = await _productService.getProductIdsByCategory(widget.category.id);
    if (productIds.isNotEmpty) {
      final products = await _productService.getProductsByIds(productIds);
      setState(() {
        selectedProducts = products;
      });
    }
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

  Future<void> _updateCategory() async {
    _validateName();
    if (_nameError != null) return;

    setState(() => isSaving = true);
    try {
      await _categoryService.updateCategory(
        widget.category.id,
        _nameController.text.trim(),
        _descController.text.trim(),
        _selectedParentId,
        !isManualMode,
        isManualMode ? [] : _conditions,
        _selectedConditionType,
        isManualMode ? selectedProducts.map((p) => p.id).toList() : null,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật danh mục thành công!')),
      );
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _deleteCategory() async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa danh mục "${widget.category.name}" không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await _categoryService.deleteCategory(widget.category.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa danh mục thành công.')),
        );
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          // Pop until the first route which is the category list screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa danh mục: $e')),
        );
      }
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
                    'Chi tiết danh mục',
                    style: TextStyle(
                      color: Colors.black87, 
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _deleteCategory,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Xóa danh mục'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isSaving || _nameError != null ? null : _updateCategory,
                  style: primaryButtonStyle,
                  child: isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                              ),
                              const SizedBox(height: 24),
                              // Name field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tên danh mục', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _nameController,
                                    decoration: designSystemInputDecoration(hint: 'Nhập tên danh mục', errorText: _nameError),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Description field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Mô tả', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _descController,
                                    minLines: 3,
                                    maxLines: 5,
                                    decoration: designSystemInputDecoration(hint: 'Nhập mô tả cho danh mục'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Parent Category
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Danh mục cha', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                                  const SizedBox(height: 8),
                                  StreamBuilder<List<ProductCategory>>(
                                    stream: _categoryService.getCategories(),
                                    builder: (context, snapshot) {
                                      final categories = (snapshot.data ?? []).where((c) => c.id != widget.category.id && c.parentId == null).toList();
                                      final parentOptions = [null, ...categories];
                                      return ShopifyDropdown<String?>(
                                        items: parentOptions.map((c) => c?.id).toList(),
                                        value: _selectedParentId,
                                        getLabel: (id) {
                                          if (id == null) return 'Chọn danh mục cha';
                                          final cat = categories.firstWhere((c) => c.id == id, orElse: () => ProductCategory(id: '', name: ''));
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
                              const Text('Loại danh mục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                              const SizedBox(height: 14),
                              Column(
                                children: [
                                  RadioListTile<bool>(
                                    title: const Text('Thủ công', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                                    subtitle: const Text('Thêm từng sản phẩm vào danh mục này.', style: TextStyle(fontSize: 13)),
                                    value: true,
                                    groupValue: isManualMode,
                                    onChanged: (value) => setState(() => isManualMode = value!),
                                  ),
                                  const SizedBox(height: 2),
                                  RadioListTile<bool>(
                                    title: const Text('Thông minh', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                                    subtitle: const Text('Các sản phẩm hiện tại và tương lai phù hợp với các điều kiện bạn đặt sẽ tự động được thêm vào danh mục này.', style: TextStyle(fontSize: 13)),
                                    value: false,
                                    groupValue: isManualMode,
                                    onChanged: (value) => setState(() => isManualMode = value!),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isManualMode) ...[
                          const SizedBox(height: 24),
                          _buildConditionsSection(),
                        ],
                        const SizedBox(height: 24),
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
                              const Text('Sản phẩm trong danh mục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              if (isManualMode) ...[
                                Text('${selectedProducts.length} sản phẩm được chọn thủ công', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _searchController,
                                  decoration: searchInputDecoration(hint: 'Tìm kiếm sản phẩm để thêm...'),
                                  onChanged: (v) => setState(() => searchText = v),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: isManualMode
                                ? _buildManualProductSelection()
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

  // --- UI Builder methods ---
  Widget _buildConditionsSection() {
    return Container(
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
          const Text('Điều kiện', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: textPrimary)),
          const SizedBox(height: 18),
          const Text('Sản phẩm phải phù hợp:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Radio<String>(value: 'all', groupValue: _selectedConditionType, onChanged: (v) => setState(() => _selectedConditionType = v!)),
              const Text('Tất cả các điều kiện', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: textPrimary)),
              const SizedBox(width: 24),
              Radio<String>(value: 'any', groupValue: _selectedConditionType, onChanged: (v) => setState(() => _selectedConditionType = v!)),
              const Text('Bất kỳ điều kiện nào', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 24),
          ..._conditions.asMap().entries.map((entry) => _buildConditionRow(entry.value, entry.key)),
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
    );
  }
  
  Widget _buildManualProductSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedProducts.isNotEmpty)
          _buildSelectedProductsList(),
        if (searchText.isNotEmpty)
          _buildSearchResultsList(),
      ],
    );
  }

  Widget _buildSelectedProductsList() {
    return Container(
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
            child: Text('Sản phẩm đã chọn (${selectedProducts.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textPrimary)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                Expanded(flex: 7, child: Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textSecondary))),
                Expanded(flex: 2, child: Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textSecondary))),
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
              return _ProductRow(
                product: p,
                showRemove: true,
                onRemove: () => setState(() => selectedProducts.remove(p)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Text('Kết quả tìm kiếm', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textPrimary)),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Product>>(
            stream: _productService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final products = (snapshot.data ?? []).where((p) => p.internalName.toLowerCase().contains(searchText.toLowerCase()) && !selectedProducts.any((sp) => sp.id == p.id)).toList();
              if (products.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Text('Không tìm thấy sản phẩm phù hợp', style: TextStyle(color: Colors.grey))));
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: borderColor),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _ProductRow(
                    product: product,
                    onTap: () => setState(() {
                      selectedProducts.add(product);
                      _searchController.clear();
                      searchText = '';
                    }),
                  );
                },
              );
            },
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
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: designSystemInputDecoration(hint: 'Từ', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() => _conditions[index].value = value);
                      },
                      controller: TextEditingController(text: condition.value?.toString() ?? ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: designSystemInputDecoration(hint: 'Đến', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                         setState(() => _conditions[index].value2 = value);
                      },
                      controller: TextEditingController(text: condition.value2?.toString() ?? ''),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              flex: 2,
              child: TextField(
                decoration: designSystemInputDecoration(hint: isNumericField ? 'Nhập số' : 'Nhập giá trị', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                keyboardType: isNumericField ? TextInputType.number : TextInputType.text,
                onChanged: (value) {
                  setState(() => _conditions[index].value = value);
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

  Widget _buildPreviewSectionStyled() {
    return StreamBuilder<List<Product>>(
      stream: _productService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final allProducts = snapshot.data ?? [];
        final matchingProducts = allProducts.where((product) {
          if (_conditions.isEmpty) return false;
          if (_selectedConditionType == 'all') {
            return _conditions.every((condition) => condition.evaluate(product));
          } else {
            return _conditions.any((condition) => condition.evaluate(product));
          }
        }).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xem trước: ${matchingProducts.length} sản phẩm phù hợp', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 12),
            if (matchingProducts.isEmpty) const Text('Không có sản phẩm phù hợp', style: TextStyle(color: Colors.grey)),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Expanded(flex: 7, child: Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textSecondary))),
                              Expanded(flex: 2, child: Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textSecondary))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(height: 1, color: borderColor),
                        ],
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 350),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: matchingProducts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: borderColor),
                        itemBuilder: (context, index) {
                          final p = matchingProducts[index];
                          return _ProductRow(product: p);
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

// Re-usable product row widget
class _ProductRow extends StatelessWidget {
  final Product product;
  final bool showRemove;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  const _ProductRow({ required this.product, this.showRemove = false, this.onRemove, this.onTap });

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