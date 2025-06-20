import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_category.dart';
import '../../services/product_category_service.dart';
import '../../widgets/common/design_system.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../models/company.dart';
import '../../services/company_service.dart';
import '../../widgets/custom/multi_select_dropdown.dart';

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AddProductScreen({super.key, this.onBack});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
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
  final _profitMarginController = TextEditingController();
  List<String> _tags = [];
  List<String> _selectedCategories = [];
  List<String> _selectedSupplierIds = [];
  List<Company> _allCompanies = [];
  bool _isActive = true;
  bool _autoCalculatePrice = true;
  static const double _defaultProfitMargin = 20.0;
  final _categoryService = ProductCategoryService();
  final _companyService = CompanyService();
  bool _companiesLoading = true;

  @override
  void initState() {
    super.initState();
    _profitMarginController.text = _defaultProfitMargin.toStringAsFixed(0);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _companiesLoading = true);
    final companies = await _companyService.getCompanies().first;
    if (mounted) {
      setState(() {
        _allCompanies = companies;
        _companiesLoading = false;
      });
    }
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
    _profitMarginController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _calculateSalePrice() {
    if (!_autoCalculatePrice) return;
    final costPriceStr = _costPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final costPrice = double.tryParse(costPriceStr) ?? 0.0;
    final profitMargin = double.tryParse(_profitMarginController.text) ?? _defaultProfitMargin;
    if (costPrice > 0) {
      final salePrice = costPrice * (1 + profitMargin / 100);
      final formattedPrice = NumberFormat('#,###', 'vi_VN').format(salePrice.round());
      _sellPriceController.value = TextEditingValue(
        text: formattedPrice,
        selection: TextSelection.collapsed(offset: formattedPrice.length),
      );
    } else {
      _sellPriceController.text = '';
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final costPriceStr = _costPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final salePriceStr = _sellPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final costPrice = double.tryParse(costPriceStr) ?? 0.0;
      final salePrice = double.tryParse(salePriceStr) ?? 0.0;
      final rawData = {
        'internal_name': _nameController.text.trim(),
        'trade_name': _commonNameController.text.trim(),
        'barcode': _barcodeController.text.trim(),
        'sku': _skuController.text.trim(),
        'unit': _unitController.text.trim(),
        'stock_system': int.tryParse(_quantityController.text) ?? 0,
        'cost_price': costPrice,
        'sale_price': salePrice,
        'tags': _tags,
        'description': _descriptionController.text.trim(),
        'usage': _usageController.text.trim(),
        'ingredients': _ingredientsController.text.trim(),
        'notes': _notesController.text.trim(),
        'category_ids': _selectedCategories,
        'supplier_ids': _selectedSupplierIds,
        'status': _isActive ? 'active' : 'inactive',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      final productData = Product.normalizeProductData(rawData);
      await FirebaseFirestore.instance.collection('products').add(productData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm sản phẩm mới!')));
        if (widget.onBack != null) widget.onBack!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _fillSampleData() {
    setState(() {
      _commonNameController.text = 'Pro-cell';
      _nameController.text = 'PC-001';
      _barcodeController.text = '8938505970012';
      _skuController.text = 'SKU-001';
      _unitController.text = 'Hộp';
      _ingredientsController.text = 'Thành phần mẫu';
      _usageController.text = 'Công dụng mẫu';
      _descriptionController.text = 'Mô tả sản phẩm mẫu';
      _tags = ['kháng sinh', 'vitamin'];
      _tagsController.clear();
      
      // Format giá mẫu với định dạng Việt Nam
      final numberFormat = NumberFormat('#,###', 'vi_VN');
      _costPriceController.text = numberFormat.format(100000);
      _sellPriceController.text = numberFormat.format(120000);
      
      _profitMarginController.text = '20';
      _quantityController.text = '50';
      _isActive = true;
      _notesController.text = 'Ghi chú sản phẩm mẫu';
      _selectedSupplierIds = _allCompanies.isNotEmpty ? [_allCompanies.first.id] : [];
    });
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
                input: StreamBuilder<List<ProductCategory>>(
                  stream: _categoryService.getCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      value: _selectedCategories.isNotEmpty ? _selectedCategories.first : null,
                      items: categories.map((cat) => DropdownMenuItem(value: cat.name, child: Text(cat.name))).toList(),
                      onChanged: (v) => setState(() => _selectedCategories = v != null ? [v] : []),
                      decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
                      hint: const Text('Chọn danh mục'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Nhà cung cấp',
          input: _companiesLoading 
            ? const Center(child: CircularProgressIndicator())
            : MultiSelectDropdown<String>(
                label: 'Nhà cung cấp',
                items: _allCompanies.map((c) => MultiSelectItem(value: c.id, label: c.name)).toList(),
                initialSelectedValues: _selectedSupplierIds,
                onSelectionChanged: (values) {
                  setState(() {
                    _selectedSupplierIds = values;
                  });
                },
                hint: 'Chọn nhà cung cấp',
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
                    color: Colors.transparent,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(16),
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
                      controller: _tagsController,
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
                      // Xóa tất cả dấu phẩy và chấm, chỉ giữ lại số
                      final cleanValue = val.replaceAll(RegExp(r'[^0-9]'), '');
                      
                      final numberFormat = NumberFormat('#,###', 'vi_VN');
                      final value = int.tryParse(cleanValue) ?? 0;
                      
                      final formatted = numberFormat.format(value);
                      
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
                      final numberFormat = NumberFormat('#,###', 'vi_VN');
                      final value = int.tryParse(cleanValue) ?? 0;
                      final formatted = numberFormat.format(value);
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
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      if (!_autoCalculatePrice) {
                        // Xóa tất cả dấu phẩy và chấm, chỉ giữ lại số
                        final cleanValue = val.replaceAll(RegExp(r'[^0-9]'), '');
                        
                        final numberFormat = NumberFormat('#,###', 'vi_VN');
                        final value = int.tryParse(cleanValue) ?? 0;
                        
                        final formatted = numberFormat.format(value);
                        
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
                        final numberFormat = NumberFormat('#,###', 'vi_VN');
                        final value = int.tryParse(cleanValue) ?? 0;
                        final formatted = numberFormat.format(value);
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: _autoCalculatePrice,
              onChanged: (val) => _calculateSalePrice(),
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
                message: 'Tự động tính giá bán dựa trên giá nhập và lợi nhuận',
                child: Icon(Icons.info_outline, size: 18, color: textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  constraints: const BoxConstraints(maxWidth: 1400),
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
                            'Thêm sản phẩm mới',
                            style: MediaQuery.of(context).size.width < 600 ? h1Mobile : h2,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton.icon(
                          onPressed: _saveProduct,
                          icon: const Icon(Icons.save),
                          label: const Text('Lưu'),
                          style: primaryButtonStyle,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: OutlinedButton.icon(
                          onPressed: _fillSampleData,
                          icon: const Icon(Icons.bolt),
                          label: const Text('Dữ liệu mẫu'),
                          style: secondaryButtonStyle,
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
              constraints: const BoxConstraints(maxWidth: 1400),
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