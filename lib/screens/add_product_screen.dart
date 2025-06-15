import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/main_layout.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../services/product_category_service.dart';
import '../widgets/common/design_system.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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
                      color: cardBackground,
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
              color: cardBackground,
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

  List<String> _selectedCategories = [];
  bool _isActive = false; // Mặc định là Không hoạt động như mẫu
  String? _lastCreatedProductId; // Thêm biến để lưu ID sản phẩm vừa tạo
  bool _isCheckingDuplicate = false; // Thêm biến để kiểm tra trạng thái đang check trùng

  final _categoryService = ProductCategoryService();

  List<String> _distributors = [];
  String? _selectedDistributor;

  @override
  void initState() {
    super.initState();
    _fetchDistributors();
    final numberFormat = NumberFormat('#,###', 'vi_VN');
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _commonNameController.text = widget.product!.commonName;
      _barcodeController.text = widget.product!.barcode ?? '';
      _skuController.text = widget.product!.sku ?? '';
      _unitController.text = widget.product!.unit;
      _quantityController.text = widget.product!.stock.toString();
      _importPriceController.text = numberFormat.format(widget.product!.importPrice.round());
      _sellPriceController.text = numberFormat.format(widget.product!.salePrice.round());
      _tagsController.text = widget.product!.tags.join(', ');
      _descriptionController.text = widget.product!.description;
      _usageController.text = widget.product!.usage;
      _ingredientsController.text = widget.product!.ingredients;
      _notesController.text = widget.product!.notes;
      final cat = widget.product!.category;
      if (cat is List) {
        _selectedCategories = (cat as List).map((e) => e.toString()).toList();
      } else if (cat is Iterable && cat is! String) {
        _selectedCategories = (cat as Iterable).map((e) => e.toString()).toList();
      } else if (cat is String && cat.isNotEmpty) {
        _selectedCategories = [cat];
      } else {
        _selectedCategories = [];
      }
      _isActive = widget.product!.isActive;
      _tags = List<String>.from(widget.product!.tags);
      final calculatedMargin = ((widget.product!.salePrice / (widget.product!.importPrice == 0 ? 1 : widget.product!.importPrice) - 1) * 100).toStringAsFixed(0);
      if (calculatedMargin != _defaultProfitMargin.toString()) {
        _profitMarginController.text = calculatedMargin;
      } else {
        _profitMarginController.text = _defaultProfitMargin.toStringAsFixed(0);
      }
    } else {
      _profitMarginController.text = _defaultProfitMargin.toStringAsFixed(0);
    }
  }

  void _fetchDistributors() async {
    final snapshot = await FirebaseFirestore.instance.collection('distributors').get();
    setState(() {
      _distributors = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
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
                                    widget.isEdit ? 'Chỉnh sửa sản phẩm' : 'Thêm sản phẩm mới',
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
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _saveProduct,
                                        icon: _isCheckingDuplicate 
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.save),
                                        label: Text(_isCheckingDuplicate ? 'Đang kiểm tra...' : 'Lưu'),
                                        style: primaryButtonStyle,
                                      ),
                                    ),
                                    if (_lastCreatedProductId != null) // Chỉ hiện nút Tạo mới khi đã có sản phẩm
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _resetForm,
                                          icon: const Icon(Icons.add),
                                          label: const Text('Tạo mới'),
                                          style: secondaryButtonStyle,
                                        ),
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
                            child: Text(widget.isEdit ? 'Chỉnh sửa sản phẩm' : 'Thêm sản phẩm mới', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.auto_fix_high),
                          tooltip: 'Điền dữ liệu mẫu',
                          onPressed: _fillSampleData,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saveProduct,
                              icon: _isCheckingDuplicate 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                              label: Text(_isCheckingDuplicate ? 'Đang kiểm tra...' : 'Lưu'),
                              style: primaryButtonStyle,
                            ),
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

  Widget _buildProductInfoSection({bool isMobile = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin sản phẩm', style: h3),
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
                    return ShopifyMultiSelectDropdown(
                      items: categories.map((cat) => cat.name).toList(),
                      selectedValues: _selectedCategories,
                      onChanged: (selected) => setState(() => _selectedCategories = selected),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DesignSystemFormField(
          label: 'Nhà phân phối',
          input: DropdownButtonFormField<String>(
            value: _selectedDistributor,
            items: _distributors.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => _selectedDistributor = v),
            decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
            hint: const Text('Chọn nhà phân phối'),
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
                   style: const TextStyle(fontSize: 14),
                  controller: _importPriceController,
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
                    print('Debug - Raw input value: $val');
                    
                    // Xóa tất cả dấu phẩy và chấm, chỉ giữ lại số
                    final cleanValue = val.replaceAll(RegExp(r'[^\d]'), '');
                    print('Debug - Cleaned value: $cleanValue');
                    
                    final numberFormat = NumberFormat('#,###', 'vi_VN');
                    final value = int.tryParse(cleanValue) ?? 0;
                    print('Debug - Parsed value: $value');
                    
                    final formatted = numberFormat.format(value);
                    print('Debug - Formatted value: $formatted');
                    
                    if (val != formatted) {
                      _importPriceController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                    _calculateSalePrice();
                  },
                  onEditingComplete: () {
                    final cleanValue = _importPriceController.text.replaceAll(RegExp(r'[^\d]'), '');
                    final numberFormat = NumberFormat('#,###', 'vi_VN');
                    final value = int.tryParse(cleanValue) ?? 0;
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
                label: 'Tồn kho',
                input: TextFormField(
                   style: const TextStyle(fontSize: 14),
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
            ),
            const SizedBox(width: 12),
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
                      print('Debug - Raw sale price input: $val');
                      
                      final cleanValue = val.replaceAll(RegExp(r'[^\d]'), '');
                      print('Debug - Cleaned sale price: $cleanValue');
                      
                      final numberFormat = NumberFormat('#,###', 'vi_VN');
                      final value = int.tryParse(cleanValue) ?? 0;
                      print('Debug - Parsed sale price: $value');
                      
                      final formatted = numberFormat.format(value);
                      print('Debug - Formatted sale price: $formatted');
                      
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
                      final cleanValue = _sellPriceController.text.replaceAll(RegExp(r'[^\d]'), '');
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
             style: const TextStyle(fontSize: 14),
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
      final numberFormat = NumberFormat('#,###', 'vi_VN');
      _nameController.text = 'Amoxicillin 500mg';
      _commonNameController.text = 'Amoxicillin';
      _barcodeController.text = '8931234567890';
      _skuController.text = 'AMO500';
      _unitController.text = 'Viên';
      _quantityController.text = '100';
      _importPriceController.text = numberFormat.format(25000);
      _sellPriceController.text = numberFormat.format(35000);
      _tags = ['kháng sinh', 'phổ rộng'];
      _descriptionController.text = 'Thuốc kháng sinh phổ rộng, điều trị nhiễm khuẩn';
      _usageController.text = 'Uống 1-2 viên/lần, 2-3 lần/ngày';
      _ingredientsController.text = 'Amoxicillin trihydrate 500mg';
      _notesController.text = 'Bảo quản nơi khô ráo, tránh ánh nắng trực tiếp';
      _selectedCategories == null;
      _isActive = true;
      _profitMarginController.text = _defaultProfitMargin.toStringAsFixed(0);
    });
  }

  void _calculateSalePrice() {
    if (!_autoCalculatePrice) return;
    
    // Xóa tất cả dấu phẩy và chấm, chỉ giữ lại số
    final importPriceStr = _importPriceController.text.replaceAll(RegExp(r'[^\d]'), '');
    print('Debug - Import price string after cleaning: $importPriceStr');
    
    final importPrice = double.tryParse(importPriceStr) ?? 0;
    print('Debug - Import price parsed: $importPrice');
    
    final profitMargin = double.tryParse(_profitMarginController.text) ?? _defaultProfitMargin;
    print('Debug - Profit margin: $profitMargin');
    
    if (importPrice > 0) {
      final salePrice = importPrice * (1 + profitMargin / 100);
      print('Debug - Calculated sale price: $salePrice');
      
      final formattedPrice = NumberFormat('#,###', 'vi_VN').format(salePrice.round());
      print('Debug - Formatted sale price: $formattedPrice');
      
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
      final productName = _nameController.text.trim();
      final commonName = _commonNameController.text.trim();
      
      // Kiểm tra trùng tên nếu đang tạo mới
      if (_lastCreatedProductId == null) {
        setState(() => _isCheckingDuplicate = true);
        final isDuplicate = await _checkDuplicateProduct(commonName);
        setState(() => _isCheckingDuplicate = false);
        
        if (isDuplicate) {
          // Hiển thị dialog xác nhận
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sản phẩm trùng tên'),
              content: const Text('Đã tồn tại sản phẩm với tên thương mại này. Bạn có muốn tạo sản phẩm mới không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: primaryButtonStyle,
                  child: const Text('Tạo mới'),
                ),
              ],
            ),
          );
          
          if (shouldContinue != true) return;
        }
      }

      // Xử lý giá nhập và giá bán
      final importPriceStr = _importPriceController.text.replaceAll(RegExp(r'[^\d]'), '');
      final salePriceStr = _sellPriceController.text.replaceAll(RegExp(r'[^\d]'), '');
      
      print('Debug - Before saving:');
      print('Import price string: ${_importPriceController.text}');
      print('Import price cleaned: $importPriceStr');
      print('Sale price string: ${_sellPriceController.text}');
      print('Sale price cleaned: $salePriceStr');
      
      final importPrice = double.tryParse(importPriceStr) ?? 0.0;
      final salePrice = double.tryParse(salePriceStr) ?? 0.0;
      
      print('Debug - Parsed values:');
      print('Import price: $importPrice');
      print('Sale price: $salePrice');

      final productData = {
        'name': productName,
        'commonName': commonName,
        'barcode': _barcodeController.text.trim(),
        'sku': _skuController.text.trim(),
        'unit': _unitController.text.trim(),
        'stock': int.tryParse(_quantityController.text) ?? 0,
        'importPrice': importPrice,
        'salePrice': salePrice,
        'tags': _tags,
        'description': _descriptionController.text.trim(),
        'usage': _usageController.text.trim(),
        'ingredients': _ingredientsController.text.trim(),
        'notes': _notesController.text.trim(),
        'category': _selectedCategories,
        'isActive': _isActive,
        'distributor': _selectedDistributor,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('Debug - Final data to save:');
      print('Import price in data: ${productData['importPrice']}');
      print('Sale price in data: ${productData['salePrice']}');

      if (_lastCreatedProductId != null) {
        await FirebaseFirestore.instance.collection('products').doc(_lastCreatedProductId).update(productData);
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
      } else {
        final docRef = await FirebaseFirestore.instance.collection('products').add({
          ...productData,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _lastCreatedProductId = docRef.id;
        if (mounted) {
          OverlayEntry? entry;
          entry = OverlayEntry(
            builder: (_) => DesignSystemSnackbar(
              message: 'Đã thêm sản phẩm thành công',
              icon: Icons.check_circle,
              onDismissed: () => entry?.remove(),
            ),
          );
          Overlay.of(context).insert(entry);
        }
      }
    } catch (e) {
      print('Debug - Error saving product: $e');
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

  Widget _buildPriceSection() {
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
                input: TextFormField(
                  style: const TextStyle(fontSize: 14),
                  controller: _importPriceController,
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
                    print('Debug - Raw input value: $val');
                    
                    // Xóa tất cả dấu phẩy và chấm, chỉ giữ lại số
                    final cleanValue = val.replaceAll(RegExp(r'[^\d]'), '');
                    print('Debug - Cleaned value: $cleanValue');
                    
                    final numberFormat = NumberFormat('#,###', 'vi_VN');
                    final value = int.tryParse(cleanValue) ?? 0;
                    print('Debug - Parsed value: $value');
                    
                    final formatted = numberFormat.format(value);
                    print('Debug - Formatted value: $formatted');
                    
                    if (val != formatted) {
                      _importPriceController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                    _calculateSalePrice();
                  },
                  onEditingComplete: () {
                    final cleanValue = _importPriceController.text.replaceAll(RegExp(r'[^\d]'), '');
                    final numberFormat = NumberFormat('#,###', 'vi_VN');
                    final value = int.tryParse(cleanValue) ?? 0;
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
                      print('Debug - Raw sale price input: $val');
                      
                      final cleanValue = val.replaceAll(RegExp(r'[^\d]'), '');
                      print('Debug - Cleaned sale price: $cleanValue');
                      
                      final numberFormat = NumberFormat('#,###', 'vi_VN');
                      final value = int.tryParse(cleanValue) ?? 0;
                      print('Debug - Parsed sale price: $value');
                      
                      final formatted = numberFormat.format(value);
                      print('Debug - Formatted sale price: $formatted');
                      
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
                      final cleanValue = _sellPriceController.text.replaceAll(RegExp(r'[^\d]'), '');
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
        const SizedBox(height: 24),
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
        const SizedBox(width: 12),
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
             style: const TextStyle(fontSize: 14),
            controller: _quantityController,
            decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
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
             style: const TextStyle(fontSize: 14),
            controller: _notesController,
            decoration: designSystemInputDecoration(label: '', fillColor: mutedBackground),
            minLines: 2,
            maxLines: 4,
          ),
        ),
      ],
    );
  }

  Future<bool> _checkDuplicateProduct(String commonName) async {
    if (commonName.isEmpty) return false;
    
    final query = await FirebaseFirestore.instance
        .collection('products')
        .where('commonName', isEqualTo: commonName)
        .get();
    
    return query.docs.isNotEmpty;
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _commonNameController.clear();
      _barcodeController.clear();
      _skuController.clear();
      _unitController.clear();
      _quantityController.clear();
      _importPriceController.clear();
      _sellPriceController.clear();
      _tagsController.clear();
      _descriptionController.text = '';
      _usageController.text = '';
      _ingredientsController.text = '';
      _notesController.text = '';
      _tagInputController.clear();
      _profitMarginController.clear();
      _tags = [];
      _selectedCategories = [];
      _isActive = false;
      _autoCalculatePrice = true;
      _selectedDistributor = null;
      _lastCreatedProductId = null; // Reset ID sản phẩm vừa tạo
      _profitMarginController.text = _defaultProfitMargin.toStringAsFixed(0);
    });
  }
}
