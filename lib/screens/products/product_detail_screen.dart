import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/product_category_service.dart';

import 'package:flutter/services.dart';
import '../../models/company.dart';
import '../../services/company_service.dart';
import '../../services/product_company_service.dart';
import '../../widgets/custom/multi_select_dropdown.dart';
import '../../widgets/custom/category_dropdown.dart';
import '../../widgets/common/design_system.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final VoidCallback? onBack;
  final VoidCallback? onDelete;
  const ProductDetailScreen({super.key, required this.product, this.onBack, this.onDelete});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commonNameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _skuController = TextEditingController();
  final _unitController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _tagsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _usageController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _notesController = TextEditingController();
  List<String> _tags = [];
  final _tagInputController = TextEditingController();
  final _profitMarginController = TextEditingController();
  bool _autoCalculatePrice = true;
  static const double _defaultProfitMargin = 20.0;
  String? _selectedCategory;
  bool _isActive = false;
  final _categoryService = ProductCategoryService();
  final _companyService = CompanyService();
  final _productCompanyService = ProductCompanyService();
  List<String> _selectedCategories = [];
  List<String> _selectedCompanyIds = [];
  List<Company> _allCompanies = [];
  bool _companiesLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadCompanies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commonNameController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    _usageController.dispose();
    _ingredientsController.dispose();
    _notesController.dispose();
    _tagInputController.dispose();
    _profitMarginController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final p = widget.product;
    _nameController.text = p.internalName;
    _commonNameController.text = p.tradeName;
    _barcodeController.text = p.barcode ?? '';
    _skuController.text = p.sku ?? '';
    _unitController.text = p.unit;
    _quantityController.text = p.stockSystem.toString();
          _costPriceController.text = formatCurrency(p.costPrice);
      _sellPriceController.text = formatCurrency(p.salePrice);
    _descriptionController.text = p.description;
    _usageController.text = p.usage;
    _ingredientsController.text = p.ingredients;
    _notesController.text = p.notes;
    _tags = List.from(p.tags);
    _selectedCategories = []; // Tạm thời empty list
    _isActive = p.status == 'active';
    _profitMarginController.text = _defaultProfitMargin.toStringAsFixed(0);
  }

  Future<void> _loadCompanies() async {
    setState(() => _companiesLoading = true);
    final companies = await _companyService.getCompanies().first;
    final companyIds = await _productCompanyService.getCompanyIdsForProduct(widget.product.id);
    
    if (mounted) {
      setState(() {
        _allCompanies = companies;
        _selectedCompanyIds = companyIds;
        _companiesLoading = false;
      });
    }
  }

  void _deleteProduct() async {
    final confirm = await showDesignSystemDialog<bool>(
      context: context,
      title: 'Xóa sản phẩm',
      content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: ghostBorderButtonStyle,
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructiveButtonStyle,
          child: const Text('Xóa'),
        ),
      ],
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('products').doc(widget.product.id).delete();
      if (mounted) {
        OverlayEntry? entry;
        entry = OverlayEntry(
          builder: (_) => DesignSystemSnackbar(
            message: 'Đã xóa sản phẩm!',
            icon: Icons.check_circle,
            onDismissed: () => entry?.remove(),
          ),
        );
        Overlay.of(context).insert(entry);
        await Future.delayed(const Duration(milliseconds: 600));
        if (widget.onBack != null) widget.onBack!();
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Xử lý giá nhập và giá bán
      final costPriceStr = _costPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final salePriceStr = _sellPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      debugPrint('Debug - Before saving:');
      debugPrint('Cost price string: ${_costPriceController.text}');
      debugPrint('Cost price cleaned: $costPriceStr');
      debugPrint('Sale price string: ${_sellPriceController.text}');
      debugPrint('Sale price cleaned: $salePriceStr');
      
      final costPrice = double.tryParse(costPriceStr) ?? 0.0;
      final salePrice = double.tryParse(salePriceStr) ?? 0.0;
      
      // Tính gross profit
      final grossProfit = costPrice > 0 ? ((salePrice / costPrice - 1) * 100) : 0.0;
      
      debugPrint('Debug - Parsed values:');
      debugPrint('Cost price: $costPrice');
      debugPrint('Sale price: $salePrice');
      debugPrint('Gross profit: $grossProfit%');
      
      final productData = {
        'internal_name': _nameController.text.trim(),
        'trade_name': _commonNameController.text.trim(),
        'barcode': _barcodeController.text.trim(),
        'sku': _skuController.text.trim(),
        'unit': _unitController.text.trim(),
        'stock_system': int.tryParse(_quantityController.text) ?? 0,
        'cost_price': costPrice,
        'sale_price': salePrice,
        'gross_profit': grossProfit,
        'tags': _tags,
        'description': _descriptionController.text.trim(),
        'usage': _usageController.text.trim(),
        'ingredients': _ingredientsController.text.trim(),
        'notes': _notesController.text.trim(),
        'category_ids': _selectedCategories,
        'status': _isActive ? 'active' : 'inactive',
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Sử dụng normalizeProductData để đảm bảo dữ liệu đúng format
      final normalizedData = Product.normalizeProductData(productData);

      debugPrint('Debug - Final data to save:');
      debugPrint('Cost price in data: ${normalizedData['cost_price']}');
      debugPrint('Sale price in data: ${normalizedData['sale_price']}');

      debugPrint('--- LOG GIÁ TRỊ CÁC TRƯỜNG TRƯỚC KHI LƯU ---');
      debugPrint('internal_name: \'${_nameController.text}\'');
      debugPrint('trade_name: \'${_commonNameController.text}\'');
      debugPrint('cost_price: \'${_costPriceController.text}\'');
      debugPrint('sale_price: \'${_sellPriceController.text}\'');
      debugPrint('profit_margin: \'${_profitMarginController.text}\'');
      debugPrint('unit: \'${_unitController.text}\'');
      debugPrint('stock_system: \'${_quantityController.text}\'');
      debugPrint('tags: $_tags');
      debugPrint('description: \'${_descriptionController.text}\'');
      debugPrint('usage: \'${_usageController.text}\'');
      debugPrint('ingredients: \'${_ingredientsController.text}\'');
      debugPrint('notes: \'${_notesController.text}\'');
      debugPrint('category_ids: $_selectedCategories');
      debugPrint('company_ids: $_selectedCompanyIds');
      debugPrint('status: ${_isActive ? 'active' : 'inactive'}');
      debugPrint('--- END LOG ---');

      // Lưu thông tin sản phẩm
      await FirebaseFirestore.instance.collection('products').doc(widget.product.id).update(normalizedData);
      
      // Cập nhật mối quan hệ Product-Company trong bảng trung gian
      await _productCompanyService.updateProductCompanies(widget.product.id, _selectedCompanyIds);
      
      // Format lại giá sau khi lưu
      _costPriceController.text = formatCurrency(costPrice);
      _sellPriceController.text = formatCurrency(salePrice);
      
      if (mounted) {
        OverlayEntry? entry;
        entry = OverlayEntry(
          builder: (_) => DesignSystemSnackbar(
            message: 'Đã cập nhật sản phẩm thành công',
            icon: Icons.check_circle,
            onDismissed: () => entry?.remove(),
          ),
        );
        Overlay.of(context).insert(entry);
      }
    } catch (e) {
      debugPrint('Debug - Error saving product: $e');
      if (mounted) {
        OverlayEntry? entry;
        entry = OverlayEntry(
          builder: (_) => DesignSystemSnackbar(
            message: 'Lỗi: $e',
            icon: Icons.error,
            onDismissed: () => entry?.remove(),
          ),
        );
        Overlay.of(context).insert(entry);
      }
    }
  }

  Widget _buildProductInfoSection({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thông tin sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        DesignSystemFormField(
          label: 'Tên thương mại *',
          input: TextFormField(
            controller: _commonNameController,
            style: const TextStyle(fontSize: 14),
            decoration: designSystemInputDecoration(
              label: '',
              fillColor: mutedBackground,
              hint: 'Nhập tên thương mại của sản phẩm',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên thương mại';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Tên nội bộ',
          input: TextFormField(
            controller: _nameController,
            style: const TextStyle(fontSize: 14),
            decoration: designSystemInputDecoration(
              label: '',
              fillColor: mutedBackground,
              hint: 'Nhập tên nội bộ (không bắt buộc)',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DesignSystemFormField(
                label: 'Barcode',
                input: TextFormField(
                  controller: _barcodeController,
                  style: const TextStyle(fontSize: 14),
                  decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesignSystemFormField(
                label: 'SKU',
                input: TextFormField(
                  controller: _skuController,
                  style: const TextStyle(fontSize: 14),
                  decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DesignSystemFormField(
                label: 'Đơn vị tính',
                input: TextFormField(
                  controller: _unitController,
                  style: const TextStyle(fontSize: 14),
                  decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground, hint: 'Nhập đơn vị tính'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesignSystemFormField(
                label: 'Danh mục',
                required: true,
                input: CategoryDropdownButton(
                  selectedCategoryIds: _selectedCategories,
                  onChanged: (categories) {
                    setState(() {
                      _selectedCategories = categories;
                    });
                  },
                  hint: 'Chọn danh mục',
                  isMultiSelect: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Company',
          input: _companiesLoading 
            ? const Center(child: CircularProgressIndicator())
            : MultiSelectDropdown<String>(
                label: 'Company',
                items: _allCompanies.map((c) => MultiSelectItem(value: c.id, label: c.name)).toList(),
                initialSelectedValues: _selectedCompanyIds,
                onSelectionChanged: (values) {
                  setState(() {
                    _selectedCompanyIds = values;
                  });
                },
                hint: 'Chọn công ty',
              ),
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Thành phần',
          input: TextFormField(
            controller: _ingredientsController,
            style: const TextStyle(fontSize: 14),
            decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
            minLines: 2,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Công dụng',
          input: TextFormField(
            controller: _usageController,
            style: const TextStyle(fontSize: 14),
            decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
            minLines: 2,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Mô tả',
          input: TextFormField(
            controller: _descriptionController,
            style: const TextStyle(fontSize: 14),
            decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
            minLines: 2,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Tags',
          input: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 16, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(tag, style: TextStyle(color: textPrimary)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _tags.remove(tag)),
                        child: const Icon(Icons.close, size: 16, color: textSecondary),
                      ),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagInputController,
                      decoration: designSystemInputDecoration(hint: '', fillColor: mutedBackground),
                      onSubmitted: (val) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ghostBorderButtonStyle,
                    onPressed: _addTag,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addTag() {
    final tag = _tagInputController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagInputController.clear();
      });
    }
  }

  Widget _buildPriceSection() {
    return designSystemCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DesignSystemFormField(
                  label: 'Đơn giá nhập',
                  input: TextFormField(
                    style: const TextStyle(fontSize: 14),
                    controller: _costPriceController,
                    decoration: designSystemInputDecoration(
                      label: '',
                      fillColor: mutedBackground,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(top: 8, right: 2),
                        child: Text('₫', style: TextStyle(color: textSecondary)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      debugPrint('Debug - Raw input value: $val');
                      
                      // Xóa tất cả dấu phẩy và chấm, chỉ giữ lại số
                      final cleanValue = val.replaceAll(RegExp(r'[^0-9]'), '');
                      debugPrint('Debug - Cleaned value: $cleanValue');
                      
                      final value = int.tryParse(cleanValue) ?? 0;
                      debugPrint('Debug - Parsed value: $value');
                      
                      final formatted = formatCurrency(value.toDouble());
                      debugPrint('Debug - Formatted value: $formatted');
                      
                      if (val != formatted) {
                        _costPriceController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                      _calculateSalePrice();
                    },
                    onEditingComplete: () {
                      final cleanValue = _costPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
                      final value = int.tryParse(cleanValue) ?? 0;
                      final formatted = formatCurrency(value.toDouble());
                      _costPriceController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DesignSystemFormField(
                  label: 'Giá bán',
                  input: TextFormField(
                    style: const TextStyle(fontSize: 14),
                    controller: _sellPriceController,
                    decoration: designSystemInputDecoration(
                      label: '',
                      fillColor: mutedBackground,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(top: 8, right: 2),
                        child: Text('₫', style: TextStyle(color: textSecondary)),
                      ),
                    ),
                    enabled: !_autoCalculatePrice,
                    onChanged: (val) {
                      if (!_autoCalculatePrice) {
                        debugPrint('Debug - Raw sale price input: $val');
                        
                        final cleanValue = val.replaceAll(RegExp(r'[^0-9]'), '');
                        debugPrint('Debug - Cleaned sale price: $cleanValue');
                        
                        final value = int.tryParse(cleanValue) ?? 0;
                        debugPrint('Debug - Parsed sale price: $value');
                        
                        final formatted = formatCurrency(value.toDouble());
                        debugPrint('Debug - Formatted sale price: $formatted');
                        
                        if (val != formatted) {
                          _sellPriceController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      }
                    },
                    onEditingComplete: () {
                      if (!_autoCalculatePrice) {
                        final cleanValue = _sellPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
                        final value = int.tryParse(cleanValue) ?? 0;
                        final formatted = formatCurrency(value.toDouble());
                        _sellPriceController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DesignSystemFormField(
            label: 'Lợi nhuận gộp (%)',
            input: TextFormField(
              style: const TextStyle(fontSize: 14),
              controller: _profitMarginController,
              decoration: designSystemInputDecoration(
                label: '',
                fillColor: mutedBackground,
                hint: _autoCalculatePrice ? '20' : '',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              enabled: _autoCalculatePrice,
              onChanged: (val) {
                if (val.isNotEmpty) {
                  _calculateSalePrice();
                } else {
                  _calculateSalePrice();
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Switch(
                value: _autoCalculatePrice,
                onChanged: (v) => setState(() {
                  _autoCalculatePrice = v;
                  if (v) _calculateSalePrice();
                }),
              ),
              const SizedBox(width: 8),
              const Text('Tính giá tự động', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Khi bật, giá bán sẽ tự động tính theo giá nhập và % lợi nhuận',
                child: Icon(Icons.info_outline, size: 18, color: textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _calculateSalePrice() {
    if (!_autoCalculatePrice) return;
    
    // Xóa tất cả dấu phẩy và chấm, chỉ giữ lại số
    final costPriceStr = _costPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    debugPrint('Debug - Cost price string after cleaning: $costPriceStr');
    
    final costPrice = double.tryParse(costPriceStr) ?? 0.0;
    debugPrint('Debug - Cost price parsed: $costPrice');
    
    final profitMargin = double.tryParse(_profitMarginController.text) ?? _defaultProfitMargin;
    debugPrint('Debug - Profit margin: $profitMargin');
    
    if (costPrice > 0) {
      final salePrice = costPrice * (1 + profitMargin / 100);
      debugPrint('Debug - Calculated sale price: $salePrice');
      
      final formattedPrice = formatCurrency(salePrice);
      debugPrint('Debug - Formatted sale price: $formattedPrice');
      
      _sellPriceController.value = TextEditingValue(
        text: formattedPrice,
        selection: TextSelection.collapsed(offset: formattedPrice.length),
      );
    } else {
      _sellPriceController.text = '';
    }
  }

  Widget _buildStockSection() {
    return designSystemCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 20),
          DesignSystemFormField(
            label: 'Số lượng',
            input: TextFormField(
               style: const TextStyle(fontSize: 14),
              controller: _quantityController,
              decoration: designSystemInputDecoration(label: 'Số lượng', fillColor: mutedBackground),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 20),
          DesignSystemFormField(
            label: 'Trạng thái',
            input: Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _isActive,
                  onChanged: (v) => setState(() => _isActive = v ?? true),
                ),
                const Text('Còn bán'),
                const SizedBox(width: 16),
                Radio<bool>(
                  value: false,
                  groupValue: _isActive,
                  onChanged: (v) => setState(() => _isActive = v ?? false),
                ),
                const Text('Ngừng bán'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DesignSystemFormField(
            label: 'Ghi chú',
            input: TextFormField(
               style: const TextStyle(fontSize: 14),
              controller: _notesController,
              decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
              minLines: 2,
              maxLines: 4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            return SafeArea(
              bottom: false,
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 1200),
                  padding: const EdgeInsets.only(top: 0, left: 16, right: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: widget.onBack,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: Text(
                                    'Chi tiết sản phẩm',
                                    style: MediaQuery.of(context).size.width < 600 ? h1Mobile : h2,
                                  ),
                        ),
                      ),
                     
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton.icon(
                          onPressed: _saveProduct,
                          icon: const Icon(Icons.save),
                          label: const Text('Lưu thay đổi'),
                          style: primaryButtonStyle,
                        ),
                      ),
                       Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            debugPrint('=== TEST: Kiểm tra dữ liệu hiện tại ===');
                            debugPrint('Selected categories: $_selectedCategories');
                            debugPrint('Tags: $_tags');
                            debugPrint('Cost price: ${_costPriceController.text}');
                            debugPrint('Sale price: ${_sellPriceController.text}');
                            debugPrint('=== END TEST ===');
                          },
                          icon: const Icon(Icons.bug_report),
                          label: const Text('Test Data'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 900;
                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            designSystemCard(
                              child: _buildProductInfoSection(isMobile: true),
                            ),
                            const SizedBox(height: 16),
                            _buildPriceSection(),
                            const SizedBox(height: 16),
                            _buildStockSection(),
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: designSystemCard(
                                child: _buildProductInfoSection(isMobile: false),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildPriceSection(),
                                  const SizedBox(height: 16),
                                  _buildStockSection(),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShopifyMultiSelectDropdown extends StatefulWidget {
  final List<String> items;
  final List<String> selectedValues;
  final String hint;
  final ValueChanged<List<String>> onChanged;

  const ShopifyMultiSelectDropdown({
    super.key,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
    this.hint = 'Chọn danh mục',
  });

  @override
  State<ShopifyMultiSelectDropdown> createState() => _ShopifyMultiSelectDropdownState();
}

class _ShopifyMultiSelectDropdownState extends State<ShopifyMultiSelectDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  void _showOverlay() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    List<String> tempSelected = List.from(widget.selectedValues);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (context, setStateOverlay) => Container(
                    constraints: BoxConstraints(
                      maxHeight: 260,
                      minWidth: size.width,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...widget.items.map((item) => CheckboxListTile(
                          value: tempSelected.contains(item),
                          title: Text(item),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (checked) {
                            setStateOverlay(() {
                              if (checked == true) {
                                tempSelected.add(item);
                              } else {
                                tempSelected.remove(item);
                              }
                            });
                          },
                        )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _removeOverlay,
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                widget.onChanged(tempSelected);
                                _removeOverlay();
                              },
                              child: const Text('Xác nhận'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    String label;
    if (widget.selectedValues.isEmpty) {
      label = widget.hint;
    } else if (widget.selectedValues.length == 1) {
      label = '1 danh mục đã chọn';
    } else {
      label = '${widget.selectedValues.length} danh mục đã chọn';
    }

    return SizedBox(
      height: 40,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: _isOpen ? _removeOverlay : _showOverlay,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: body.copyWith(
                      color: widget.selectedValues.isEmpty ? textMuted : textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 