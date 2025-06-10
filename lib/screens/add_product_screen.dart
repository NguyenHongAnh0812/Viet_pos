import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/main_layout.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../services/product_category_service.dart';
import '../widgets/common/design_system.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final Product? product;
  final bool isEdit;
  const AddProductScreen({super.key, this.onBack, this.product, this.isEdit = false});

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
  final _importPriceController = TextEditingController();
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
  static const double _defaultProfitMargin = 20.0; // Default profit margin constant

  String? _selectedCategory;
  bool _isActive = false; // Mặc định là Không hoạt động như mẫu

  final _categoryService = ProductCategoryService();

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _commonNameController.text = p.commonName;
      _barcodeController.text = p.barcode ?? '';
      _skuController.text = p.sku ?? '';
      _unitController.text = p.unit;
      _quantityController.text = p.stock.toString();
      _importPriceController.text = p.importPrice.toString();
      _sellPriceController.text = p.salePrice.toString();
      _tagsController.text = p.tags.join(', ');
      _descriptionController.text = p.description;
      _usageController.text = p.usage;
      _ingredientsController.text = p.ingredients;
      _notesController.text = p.notes;
      _selectedCategory = p.category;
      _isActive = p.isActive;
      // Calculate profit margin from existing product
      final calculatedMargin = ((p.salePrice / p.importPrice - 1) * 100).toStringAsFixed(0);
      if (calculatedMargin != _defaultProfitMargin.toString()) {
        _profitMarginController.text = calculatedMargin;
      }
    } else {
      // Reset toàn bộ dữ liệu về mặc định khi thêm mới
      _nameController.clear();
      _commonNameController.clear();
      _barcodeController.clear();
      _skuController.clear();
      _unitController.clear();
      _quantityController.clear();
      _importPriceController.clear();
      _sellPriceController.clear();
      _tagsController.clear();
      _descriptionController.clear();
      _usageController.clear();
      _ingredientsController.clear();
      _notesController.clear();
      _tagInputController.clear();
      _profitMarginController.clear();
      _tags = [];
      _selectedCategory = null;
      _isActive = false;
      _autoCalculatePrice = true;
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
    _importPriceController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            if (isMobile) {
              return SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 1400),
                      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: widget.onBack,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Thêm sản phẩm',
                                    style: MediaQuery.of(context).size.width < 600 ? h1Mobile : h2,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.auto_fix_high),
                                tooltip: 'Điền dữ liệu mẫu',
                                onPressed: _fillSampleData,
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 0, top: 8, bottom: 0),
                            child: SizedBox(
                              height: 40,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _saveProduct,
                                      icon: const Icon(Icons.save),
                                      label: const Text('Lưu'),
                                      style: primaryButtonStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else {
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
                            child: Text('Thêm sản phẩm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.auto_fix_high),
                          tooltip: 'Điền dữ liệu mẫu',
                          onPressed: _fillSampleData,
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
                      ],
                    ),
                  ),
                ),
              );
            }
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
                      final isMobile = constraints.maxWidth < 700;
                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            designSystemCard(
                              child: _buildProductInfoSection(isMobile: true),
                            ),
                            const SizedBox(height: 16),
                            designSystemCard(
                              child: _buildPriceStockSection(isMobile: true),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: designSystemCard(
                                child: _buildProductInfoSection(isMobile: false),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  designSystemCard(
                                    child: _buildPriceSection(),
                                  ),
                                  const SizedBox(height: 16),
                                  designSystemCard(
                                    child: _buildStockSection(),
                                  ),
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

  Widget _buildProductInfoSection({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thông tin sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        DesignSystemFormField(
          label: 'Tên thương mại',
          input: TextFormField(
            controller: _commonNameController,
            decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
          ),
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Tên nội bộ',
          required: true,
          input: TextFormField(
            controller: _nameController,
            decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
            validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên nội bộ' : null,
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
                  decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
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
                    return ShopifyDropdown<String>(
                      items: categories.map((cat) => cat.name).toList(),
                      value: _selectedCategory,
                      getLabel: (v) => v ?? '',
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      hint: 'Chọn danh mục',
                      backgroundColor: mutedBackground,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Tags input đặc biệt
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
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Mô tả',
          input: TextFormField(
            controller: _descriptionController,
            decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
            minLines: 2,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Thành phần',
          input: TextFormField(
            controller: _ingredientsController,
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
            decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
            minLines: 2,
            maxLines: 4,
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

  Widget _buildPriceStockSection({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thông tin giá & kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DesignSystemFormField(
                label: 'Giá nhập',
                required: true,
                input: TextFormField(
                  controller: _importPriceController,
                  decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground, prefixIcon: Padding(padding: EdgeInsets.only(left: 8, right: 4), child: Text('₫', style: TextStyle(color: textSecondary)))),
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesignSystemFormField(
                label: 'Tồn kho',
                input: TextFormField(
                  controller: _quantityController,
                  decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Vui lòng nhập tồn kho';
                    final n = int.tryParse(val.trim());
                    if (n == null) return 'Tồn kho phải là số';
                    if (n < 0) return 'Tồn kho không được âm';
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Dòng switch và mô tả
        Row(
          children: [
            Switch(value: false, onChanged: (_) {}),
            const SizedBox(width: 8),
            const Text('Sử dụng giá bán thủ công', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(left: 44),
          child: Text('Khi bật, giá bán sẽ không tự động cập nhật theo % lợi nhuận', style: TextStyle(fontSize: 13, color: textSecondary)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DesignSystemFormField(
                label: '% Lợi nhuận',
                input: TextFormField(
                  decoration: designSystemInputDecoration(label: '% Lợi nhuận', fillColor: mutedBackground),
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesignSystemFormField(
                label: 'Giá bán',
                required: true,
                input: TextFormField(
                  controller: _sellPriceController,
                  decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground, prefixIcon: Padding(padding: EdgeInsets.only(left: 8, right: 4), child: Text('₫', style: TextStyle(color: textSecondary)))),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Vui lòng nhập giá bán';
                    final n = double.tryParse(val.trim());
                    if (n == null) return 'Giá bán phải là số';
                    if (n < 0) return 'Giá bán không được âm';
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Trạng thái
        Row(
          children: [
            const Text('Trạng thái: '),
            Switch(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            Text(_isActive ? 'Còn bán' : 'Ngừng bán', style: TextStyle(fontWeight: FontWeight.w500, color: _isActive ? Colors.blue : Colors.red)),
          ],
        ),
        const SizedBox(height: 16),
        // Ghi chú full width
        DesignSystemFormField(
          label: 'Ghi chú',
          input: TextFormField(
            controller: _notesController,
            decoration: designSystemInputDecoration(label: 'Ghi chú', fillColor: mutedBackground),
            minLines: 2,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _fillSampleData() {
    setState(() {
      _nameController.text = 'Amoxicillin 500mg';
      _commonNameController.text = 'Amoxicillin';
      _barcodeController.text = '8931234567890';
      _skuController.text = 'AMO500';
      _unitController.text = 'Viên';
      _quantityController.text = '100';
      _importPriceController.text = '25000';
      _sellPriceController.text = '35000';
      _tags = ['kháng sinh', 'phổ rộng'];
      _descriptionController.text = 'Thuốc kháng sinh phổ rộng, điều trị nhiễm khuẩn';
      _usageController.text = 'Uống 1-2 viên/lần, 2-3 lần/ngày';
      _ingredientsController.text = 'Amoxicillin trihydrate 500mg';
      _notesController.text = 'Bảo quản nơi khô ráo, tránh ánh nắng trực tiếp';
      _selectedCategory = _selectedCategory ?? 'Kháng sinh';
      _isActive = true;
    });
  }

  void _saveProduct() async {
    print('=== Starting save product ===');
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    try {
      final now = DateTime.now();
      // Get and trim all text fields
      final name = _nameController.text.trim();
      final commonName = _commonNameController.text.trim();
      final category = _selectedCategory ?? '';
      final unit = _unitController.text.trim();
      final description = _descriptionController.text.trim();
      final usage = _usageController.text.trim();
      final ingredients = _ingredientsController.text.trim();
      final notes = _notesController.text.trim();
      final stock = int.tryParse(_quantityController.text.trim());
      final importPrice = double.tryParse(_importPriceController.text.replaceAll(',', ''));
      final salePrice = double.tryParse(_sellPriceController.text.replaceAll(',', ''));

      print('=== DEBUG FIELD VALUES ===');
      print('name: "$name"');
      print('commonName: "$commonName"');
      print('category: "$category"');
      print('unit: "$unit"');
      print('description: "$description"');
      print('usage: "$usage"');
      print('ingredients: "$ingredients"');
      print('notes: "$notes"');
      print('stock: $stock');
      print('importPrice: $importPrice');
      print('salePrice: $salePrice');
      print('tags: $_tags');
      print('isActive: $_isActive');
      print('createdAt: $now');
      print('updatedAt: $now');

      // Kiểm tra từng trường và báo lỗi rõ ràng
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Tên nội bộ')));
        print('ERROR: name is empty');
        return;
      }
      if (commonName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Tên thương mại')));
        print('ERROR: commonName is empty');
        return;
      }
      if (unit.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Đơn vị tính')));
        print('ERROR: unit is empty');
        return;
      }
      if (description.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Mô tả')));
        print('ERROR: description is empty');
        return;
      }
      if (usage.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Công dụng')));
        print('ERROR: usage is empty');
        return;
      }
      if (ingredients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Thành phần')));
        print('ERROR: ingredients is empty');
        return;
      }
      if (notes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Ghi chú')));
        print('ERROR: notes is empty');
        return;
      }
      if (stock == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đúng Số lượng tồn kho')));
        print('ERROR: stock is null');
        return;
      }
      if (importPrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đúng Giá nhập')));
        print('ERROR: importPrice is null');
        return;
      }
      if (salePrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đúng Giá bán')));
        print('ERROR: salePrice is null');
        return;
      }
      if (_tags == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Tags')));
        print('ERROR: tags is null');
        return;
      }

      print('=== Form Data PASSED ===');

      print('=== Creating product object ===');
      final product = Product(
        id: widget.product?.id ?? '',
        name: name,
        commonName: commonName,
        category: category,
        barcode: _barcodeController.text.trim(),
        sku: _skuController.text.trim(),
        unit: unit,
        tags: _tags,
        description: description,
        usage: usage,
        ingredients: ingredients,
        notes: notes,
        stock: stock,
        importPrice: importPrice,
        salePrice: salePrice,
        isActive: _isActive,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );

      print('=== Product object created ===');
      print('Product map: ${product.toMap()}');

      print('=== Saving to Firestore ===');
      final ref = FirebaseFirestore.instance.collection('products');
      if (widget.isEdit && widget.product != null) {
        print('Updating existing product: ${widget.product!.id}');
        await ref.doc(widget.product!.id).update(product.toMap());
      } else {
        print('Adding new product');
        await ref.add(product.toMap());
      }

      print('=== Save successful ===');
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/product-list');
        Future.delayed(const Duration(milliseconds: 300), () {
          OverlayEntry? entry;
          entry = OverlayEntry(
            builder: (_) => DesignSystemSnackbar(
              message: 'Đã thêm thành công sản phẩm',
              icon: Icons.check_circle,
              onDismissed: () => entry?.remove(),
            ),
          );
          Overlay.of(context).insert(entry);
        });
      }
    } catch (e, stack) {
      print('=== Error saving product ===');
      print('Error: $e');
      print('Stack trace: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu sản phẩm: $e')),
        );
      }
    }
  }

  void _calculateSalePrice() {
    if (!_autoCalculatePrice) return;
    final importPrice = double.tryParse(_importPriceController.text.replaceAll(',', '')) ?? 0;
    final profitMargin = double.tryParse(_profitMarginController.text) ?? _defaultProfitMargin;
    if (importPrice > 0) {
      final salePrice = importPrice * (1 + profitMargin / 100);
      final formattedPrice = NumberFormat('#,###', 'vi_VN').format(salePrice.round());
      _sellPriceController.value = TextEditingValue(
        text: formattedPrice,
        selection: TextSelection.collapsed(offset: formattedPrice.length),
      );
    } else {
      _sellPriceController.text = '';
    }
  }

  Widget _buildPriceSection() {
    final numberFormat = NumberFormat('#,###', 'vi_VN');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DesignSystemFormField(
                label: 'Giá nhập',
                required: true,
                input: TextFormField(
                  controller: _importPriceController,
                  decoration: designSystemInputDecoration(
                    label: 'Giá nhập',
                    fillColor: mutedBackground,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(top: 5, left: 8),
                      child: Text('₫', style: TextStyle(color: textSecondary)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) {
                    _calculateSalePrice();
                  },
                  onEditingComplete: () {
                    final value = int.tryParse(_importPriceController.text.replaceAll(',', '')) ?? 0;
                    final formatted = numberFormat.format(value);
                    _importPriceController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesignSystemFormField(
                label: 'Giá bán',
                required: true,
                input: TextFormField(
                  controller: _sellPriceController,
                  decoration: designSystemInputDecoration(
                    label: 'Giá bán',
                    fillColor: mutedBackground,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(top: 5, left: 8),
                      child: Text('₫', style: TextStyle(color: textSecondary)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onEditingComplete: () {
                    final value = int.tryParse(_sellPriceController.text.replaceAll(',', '')) ?? 0;
                    final formatted = numberFormat.format(value);
                    _sellPriceController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Lợi nhuận gộp (%)',
          input: TextFormField(
            controller: _profitMarginController,
            decoration: designSystemInputDecoration(
              label: '20',
              hint: '${_defaultProfitMargin.toStringAsFixed(0)}%', // Show default as hint
              fillColor: mutedBackground,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              if (val.isNotEmpty) {
                _calculateSalePrice();
              } else {
                // If input is cleared, recalculate with default margin
                _calculateSalePrice();
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Switch(
              value: _autoCalculatePrice,
              onChanged: (value) {
                setState(() {
                  _autoCalculatePrice = value;
                  if (value) {
                    _calculateSalePrice();
                  }
                });
              },
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
    );
  }

  Widget _buildStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        DesignSystemFormField(
          label: 'Số lượng',
          input: TextFormField(
            controller: _quantityController,
            decoration: designSystemInputDecoration(label: 'Số lượng', fillColor: mutedBackground),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(height: 12),
        const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w500)),
        Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: _isActive,
              onChanged: (v) => setState(() => _isActive = true),
            ),
            const Text('Đang kinh doanh'),
            const SizedBox(width: 16),
            Radio<bool>(
              value: false,
              groupValue: _isActive,
              onChanged: (v) => setState(() => _isActive = false),
            ),
            const Text('Ngừng kinh doanh'),
          ],
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Ghi chú',
          input: TextFormField(
            controller: _notesController,
            decoration: designSystemInputDecoration(label: 'Ghi chú', fillColor: mutedBackground),
            minLines: 2,
            maxLines: 4,
          ),
        ),
      ],
    );
  }
}
