import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/main_layout.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../services/product_category_service.dart';
import '../../widgets/common/design_system.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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
  static const double _defaultProfitMargin = 20.0;
  String? _selectedCategory;
  bool _isActive = false;
  final _categoryService = ProductCategoryService();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
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
    _tags = List<String>.from(p.tags);
    final calculatedMargin = ((p.salePrice / (p.importPrice == 0 ? 1 : p.importPrice) - 1) * 100).toStringAsFixed(0);
    if (calculatedMargin != _defaultProfitMargin.toString()) {
      _profitMarginController.text = calculatedMargin;
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

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    final updatedProduct = Product(
      id: widget.product.id,
      name: _nameController.text.trim(),
      commonName: _commonNameController.text.trim(),
      category: _selectedCategory ?? '',
      barcode: _barcodeController.text.trim(),
      sku: _skuController.text.trim(),
      unit: _unitController.text.trim(),
      tags: _tags,
      description: _descriptionController.text.trim(),
      usage: _usageController.text.trim(),
      ingredients: _ingredientsController.text.trim(),
      notes: _notesController.text.trim(),
      stock: int.tryParse(_quantityController.text.trim()) ?? 0,
      importPrice: double.tryParse(_importPriceController.text.trim()) ?? 0.0,
      salePrice: double.tryParse(_sellPriceController.text.trim()) ?? 0.0,
      isActive: _isActive,
      createdAt: widget.product.createdAt,
      updatedAt: DateTime.now(),
    );
    await FirebaseFirestore.instance.collection('products').doc(updatedProduct.id).set(updatedProduct.toMap());
    if (mounted) {
      OverlayEntry? entry;
      entry = OverlayEntry(
        builder: (_) => DesignSystemSnackbar(
          message: 'Đã lưu sản phẩm!',
          icon: Icons.check_circle,
          onDismissed: () => entry?.remove(),
        ),
      );
      Overlay.of(context).insert(entry);
    }
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
            decoration: designSystemInputDecoration(label: 'Tên thương mại', fillColor: mutedBackground),
          ),
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Tên nội bộ',
          required: true,
          input: TextFormField(
            controller: _nameController,
            decoration: designSystemInputDecoration(label: 'Tên nội bộ', fillColor: mutedBackground),
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
                  decoration: designSystemInputDecoration(label: 'Barcode', fillColor: mutedBackground),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesignSystemFormField(
                label: 'SKU',
                input: TextFormField(
                  controller: _skuController,
                  decoration: designSystemInputDecoration(label: 'SKU', fillColor: mutedBackground),
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
                  decoration: designSystemInputDecoration(label: 'Đơn vị tính', fillColor: mutedBackground),
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
                      decoration: designSystemInputDecoration(hint: 'Nhập tag mới', fillColor: mutedBackground),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty && !_tags.contains(val.trim())) {
                          setState(() => _tags.add(val.trim()));
                          _tagInputController.clear();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final val = _tagInputController.text.trim();
                      if (val.isNotEmpty && !_tags.contains(val)) {
                        setState(() => _tags.add(val));
                        _tagInputController.clear();
                      }
                    },
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
            decoration: designSystemInputDecoration(label: 'Mô tả', fillColor: mutedBackground),
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Công dụng',
          input: TextFormField(
            controller: _usageController,
            decoration: designSystemInputDecoration(label: 'Công dụng', fillColor: mutedBackground),
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Thành phần',
          input: TextFormField(
            controller: _ingredientsController,
            decoration: designSystemInputDecoration(label: 'Thành phần', fillColor: mutedBackground),
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Ghi chú',
          input: TextFormField(
            controller: _notesController,
            decoration: designSystemInputDecoration(label: 'Ghi chú', fillColor: mutedBackground),
            maxLines: 2,
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
                  label: 'Giá nhập',
                  input: TextFormField(
                    controller: _importPriceController,
                    decoration: designSystemInputDecoration(label: 'Giá nhập', fillColor: mutedBackground, prefixIcon: Padding(padding: EdgeInsets.only(left: 8, right: 4), child: Text('₫', style: TextStyle(color: textSecondary)))),
                    keyboardType: TextInputType.number,
                    onChanged: (val) { if (_autoCalculatePrice) _autoCalcSellPrice(); },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DesignSystemFormField(
                  label: 'Giá bán',
                  input: TextFormField(
                    controller: _sellPriceController,
                    decoration: designSystemInputDecoration(label: 'Giá bán', fillColor: mutedBackground, prefixIcon: Padding(padding: EdgeInsets.only(left: 8, right: 4), child: Text('₫', style: TextStyle(color: textSecondary)))),
                    keyboardType: TextInputType.number,
                    enabled: !_autoCalculatePrice,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DesignSystemFormField(
            label: 'Lợi nhuận gộp (%)',
            input: TextFormField(
              controller: _profitMarginController,
              decoration: designSystemInputDecoration(label: 'Lợi nhuận gộp (%)', fillColor: mutedBackground),
              keyboardType: TextInputType.number,
              onChanged: (val) { if (_autoCalculatePrice) _autoCalcSellPrice(); },
              enabled: _autoCalculatePrice,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Switch(
                value: _autoCalculatePrice,
                onChanged: (v) => setState(() {
                  _autoCalculatePrice = v;
                  if (v) _autoCalcSellPrice();
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
                const Text('Đang kinh doanh'),
                const SizedBox(width: 16),
                Radio<bool>(
                  value: false,
                  groupValue: _isActive,
                  onChanged: (v) => setState(() => _isActive = v ?? false),
                ),
                const Text('Ngừng kinh doanh'),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
      ),
    );
  }

  void _autoCalcSellPrice() {
    final importPrice = double.tryParse(_importPriceController.text.trim()) ?? 0.0;
    final margin = double.tryParse(_profitMarginController.text.trim()) ?? _defaultProfitMargin;
    final sellPrice = importPrice * (1 + margin / 100);
    _sellPriceController.text = sellPrice.toStringAsFixed(0);
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
                          label: const Text('Lưu'),
                          style: primaryButtonStyle,
                        ),
                      ),
                       Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton.icon(
                          onPressed: _deleteProduct,
                          icon: const Icon(Icons.delete),
                          label: const Text('Xóa'),
                          style: destructiveButtonStyle,
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