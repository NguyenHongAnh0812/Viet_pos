import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/product_category_service.dart';

import 'package:flutter/services.dart';

import '../../models/company.dart';
import '../../services/company_service.dart';
import '../../services/product_company_service.dart';
import '../../widgets/custom/multi_select_dropdown.dart';
import '../../widgets/custom/category_dropdown.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;
import 'package:collection/collection.dart';
import '../../widgets/common/design_system.dart';
import '../../models/product_category.dart';
import '../../models/product.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  final VoidCallback? onBack;
  const EditProductScreen({super.key, required this.product, this.onBack});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> with TickerProviderStateMixin {
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
  final _originController = TextEditingController();
  final _discontinueReasonController = TextEditingController();
  final _contraindicationController = TextEditingController();
  final _directionController = TextEditingController();
  final _withdrawalTimeController = TextEditingController();
  List<String> _tags = [];
  List<ProductCategory> _selectedCategories = [];
  List<String> _selectedCompanyIds = [];
  List<Company> _allCompanies = [];
  bool _isActive = true;
  // 1. State cho auto tính giá và lợi nhuận gộp
  bool _autoCalculatePrice = true;
  double _profitMargin = 20.0;
  static const double _defaultProfitMargin = 20.0;
  final _categoryService = ProductCategoryService();
  final _companyService = CompanyService();
  final _productCompanyService = ProductCompanyService();
  bool _companiesLoading = true;
  bool _isSaving = false;
  final List<File> _productImageFiles = [];
  List<String> _productImageUrls = [];
  final List<Uint8List> _webImageBytesList = [];
  int _mainImageIndex = 0;
  final ImagePicker _picker = ImagePicker();
  DateTime? _mfgDate;
  DateTime? _expDate;
  List<ProductCategory> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _profitMarginController.text = _defaultProfitMargin.toStringAsFixed(0);
    _autoCalculatePrice = true;
    _profitMargin = double.tryParse(_profitMarginController.text) ?? 20.0;
    _loadCompanies();
    _loadCategories();
    _fillProductData();
  }

  void _fillProductData() {
    final product = widget.product;
    
    // Fill basic information
    _nameController.text = product.tradeName;
    _commonNameController.text = product.internalName;
    _barcodeController.text = product.barcode ?? '';
    _skuController.text = product.sku ?? '';
    _unitController.text = product.unit;
    _quantityController.text = product.stockSystem.toString();
    _costPriceController.text = formatCurrency(product.costPrice);
    _sellPriceController.text = formatCurrency(product.salePrice);
    _descriptionController.text = product.description;
    _usageController.text = product.usage;
    _ingredientsController.text = product.ingredients;
    _notesController.text = product.notes;
    _contraindicationController.text = product.contraindication;
    _directionController.text = product.direction;
    _withdrawalTimeController.text = product.withdrawalTime;
    
    // Fill tags
    _tags = List<String>.from(product.tags);
    
    // Fill status
    _isActive = product.status == 'active';
    
    // Fill existing images
    _productImageUrls = List<String>.from(product.images ?? []);
    
    // Calculate profit margin
    if (product.costPrice > 0 && product.salePrice > 0) {
      final profitMargin = ((product.salePrice - product.costPrice) / product.costPrice * 100);
      _profitMarginController.text = profitMargin.toStringAsFixed(0);
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
    _originController.dispose();
    _discontinueReasonController.dispose();
    _contraindicationController.dispose();
    _directionController.dispose();
    _withdrawalTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    setState(() => _companiesLoading = true);
    final companies = await _companyService.getCompanies().first;
    if (mounted) {
      setState(() {
        _allCompanies = companies;
        _companiesLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryService.getCategories().first;
    if (mounted) {
      setState(() {
        _allCategories = _buildCategoryTree(categories);
        // Load selected categories for this product
        _loadSelectedCategories();
      });
    }
  }

  void _loadSelectedCategories() {
    // TODO: Load selected categories based on product.categoryIds
    // This will be implemented when category relation is available
  }

  // Hàm build tree phân cấp, trả về list đã sort theo cấp, mỗi item có level
  List<ProductCategory> _buildCategoryTree(List<ProductCategory> all) {
    Map<String, List<ProductCategory>> childrenMap = {};
    for (final cat in all) {
      final parent = cat.parentId ?? '';
      childrenMap.putIfAbsent(parent, () => []).add(cat);
    }
    List<ProductCategory> result = [];
    void addChildren(String? parentId, int level) {
      for (final cat in (childrenMap[parentId ?? ''] ?? [])) {
        result.add(cat.copyWith(level: level));
        addChildren(cat.id, level + 1);
      }
    }
    addChildren(null, 0);
    return result;
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

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _calculateSalePrice() {
    if (!_autoCalculatePrice) return;
    final costPriceStr = _costPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final costPrice = double.tryParse(costPriceStr) ?? 0.0;
    final salePrice = costPrice * (1 + _profitMargin / 100);
    final formattedPrice = formatCurrency(salePrice);
    _sellPriceController.value = TextEditingValue(
      text: formattedPrice,
      selection: TextSelection.collapsed(offset: formattedPrice.length),
    );
  }

  Future<void> _pickMultiImageFromGallery() async {
    if (kIsWeb) {
      // final input = html.FileUploadInputElement()..accept = 'image/*'..multiple = true;
      // input.click();
      // input.onChange.listen((event) {
      //   final files = input.files;
      //   if (files != null && files.isNotEmpty) {
      //     int remain = 5 - _webImageBytesList.length;
      //     if (files.length > remain) {
      //       _showPopupNotification('Chỉ được chọn tối đa 5 ảnh', Icons.error_outline);
      //     }
      //     for (final file in files.take(remain)) {
      //       final reader = html.FileReader();
      //       reader.readAsArrayBuffer(file);
      //       reader.onLoadEnd.listen((event) {
      //         if (reader.result != null) {
      //           setState(() {
      //             _webImageBytesList.add(reader.result as Uint8List);
      //           });
      //         }
      //       });
      //     }
      //   }
    } else {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        int remain = 5 - _productImageFiles.length;
        if (images.length > remain) {
          _showPopupNotification('Chỉ được chọn tối đa 5 ảnh', Icons.error_outline);
        }
        setState(() {
          for (final image in images.take(remain)) {
            _productImageFiles.add(File(image.path));
          }
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _productImageFiles.length) {
        _productImageFiles.removeAt(index);
      } else {
        final urlIndex = index - _productImageFiles.length;
        if (urlIndex < _productImageUrls.length) {
          _productImageUrls.removeAt(urlIndex);
        }
      }
      if (_mainImageIndex >= _productImageFiles.length + _productImageUrls.length) {
        _mainImageIndex = 0;
      }
    });
  }

  void _setMainImage(int index) {
    setState(() {
      _mainImageIndex = index;
    });
  }

  Future<List<String>> _uploadImages() async {
    final List<String> uploadedUrls = [];
    
    // Upload new files
    for (int i = 0; i < _productImageFiles.length; i++) {
      final file = _productImageFiles[i];
      final fileName = 'product_images/${widget.product.id}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      uploadedUrls.add(downloadUrl);
    }

    // Upload web images
    for (int i = 0; i < _webImageBytesList.length; i++) {
      final bytes = _webImageBytesList[i];
      final fileName = 'product_images/${widget.product.id}_${DateTime.now().millisecondsSinceEpoch}_web_$i.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      uploadedUrls.add(downloadUrl);
    }

    return uploadedUrls;
  }

  double _parseCurrency(String text) {
    // Remove currency symbol and commas, then parse as double
    final cleanText = text.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanText) ?? 0.0;
  }

  void _showPopupNotification(String message, IconData icon) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => DesignSystemSnackbar(
        message: message,
        icon: icon,
        onDismissed: () => entry?.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Upload new images
      // final newImageUrls = await _uploadImages();
      // final allImageUrls = [..._productImageUrls, ...newImageUrls];
      final allImageUrls = [..._productImageUrls];

      // Prepare product data
      final productData = {
        'trade_name': _nameController.text.trim(),
        'internal_name': _commonNameController.text.trim(),
        'barcode': _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        'sku': _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        'unit': _unitController.text.trim(),
        'stock_system': int.tryParse(_quantityController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        'cost_price': _parseCurrency(_costPriceController.text),
        'sale_price': _parseCurrency(_sellPriceController.text),
        'gross_profit': _parseCurrency(_sellPriceController.text) - _parseCurrency(_costPriceController.text),
        'auto_price': _autoCalculatePrice,
        'tags': _tags,
        'description': _descriptionController.text.trim(),
        'usage': _usageController.text.trim(),
        'ingredients': _ingredientsController.text.trim(),
        'notes': _notesController.text.trim(),
        if (_originController.text.trim().isNotEmpty)
          'origin': _originController.text.trim(),
        'contraindication': _contraindicationController.text.trim(),
        'direction': _directionController.text.trim(),
        'withdrawal_time': _withdrawalTimeController.text.trim(),
        'status': _isActive ? 'active' : 'inactive',
        if (!_isActive && _discontinueReasonController.text.trim().isNotEmpty)
          'discontinue_reason': _discontinueReasonController.text.trim(),
        'images': allImageUrls,
        'mainImageIndex': _mainImageIndex,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Update product in Firestore
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update(productData);

      if (mounted) {
        _showPopupNotification('Cập nhật sản phẩm thành công!', Icons.check_circle);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showPopupNotification('Lỗi khi cập nhật sản phẩm: $e', Icons.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // 1. Sửa _buildFormField để input 1 dòng luôn height 40px
  Widget _buildFormField({
    required String label,
    TextEditingController? controller,
    Widget? child,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
    Function(String)? onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        const SizedBox(height: space8),
        if (child != null)
          child
        else
          SizedBox(
            height: (maxLines == 1 && minLines == 1) ? inputHeight : null,
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              minLines: minLines,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadiusMedium)),
                contentPadding: EdgeInsets.symmetric(horizontal: inputPadding, vertical: minLines > 1 ? 12 : 0),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) {
                // Format tiền cho trường Giá nhập
                if (label.contains('Giá nhập') && controller != null) {
                  String numbers = val.replaceAll(RegExp(r'[^0-9]'), '');
                  if (numbers.isEmpty) {
                    controller.text = '';
                  } else {
                    double value = double.tryParse(numbers) ?? 0;
                    String formatted = formatCurrency(value);
                    int newOffset = formatted.length;
                    controller.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: newOffset),
                    );
                  }
                  if (onChanged != null) onChanged(val);
                  if (_autoCalculatePrice) _calculateSalePrice();
                } else {
                  if (onChanged != null) onChanged(val);
                }
              },
              validator: (value) {
                if (label.contains('*') && (value == null || value.trim().isEmpty)) {
                  return 'Vui lòng nhập $label';
                }
                return null;
              },
              enabled: enabled,
            ),
          ),
      ],
    );
  }

  Widget _buildProductImageBlock() {
    final hasImage = _productImageFiles.isNotEmpty || _productImageUrls.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Ảnh sản phẩm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
            const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        if (!hasImage)
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
                // Custom dashed border can be added with a custom painter if needed
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Product', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        if (hasImage)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _productImageFiles.length + _productImageUrls.length,
            itemBuilder: (context, index) {
              final isMain = index == _mainImageIndex;
              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isMain ? mainGreen : Colors.grey[300]!,
                        width: isMain ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: index < _productImageFiles.length
                          ? Image.file(_productImageFiles[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                          : Image.network(_productImageUrls[index - _productImageFiles.length], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMain)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: mainGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Chính', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        IconButton(
                          onPressed: () => _removeImage(index),
                          icon: const Icon(Icons.close, color: Colors.red, size: 16),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMain)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: IconButton(
                        onPressed: () => _setMainImage(index),
                        icon: const Icon(Icons.star_border, color: Colors.orange, size: 16),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickMultiImageFromGallery,
              icon: const Icon(Icons.upload, size: 20),
              label: const Text('Tải ảnh'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {/* TODO: implement camera picker */},
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('Chụp ảnh'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final isTablet = MediaQuery.of(context).size.width > 768;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: mainGreen,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text(
                        'Sửa sản phẩm',
                        style: h2Mobile.copyWith(color: Colors.white),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32 : 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: isDesktop
                            ? _buildDesktopLayout()
                            : _buildMobileLayout(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 64), // Để chừa chỗ cho footer
            ],
          ),
          // Footer nút Hủy/Lưu cố định
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: const BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text(_isSaving ? 'Đang lưu...' : 'Lưu sản phẩm'),
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

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cột 7: Ảnh sản phẩm, Thông tin cơ bản, Thông tin y tế
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh sản phẩm lên đầu - Tạm thời ẩn, sẽ phát triển sau
              // SectionCard(
              //   padding: const EdgeInsets.all(16),
              //   child: _buildProductImageBlock(),
              // ),
              // Thông tin cơ bản
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin cơ bản', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
                    const SizedBox(height: space16),
                    _buildFormField(label: 'Tên thương mại *', controller: _commonNameController),
                    const SizedBox(height: space12),
                    _buildFormField(label: 'Tên nội bộ', controller: _nameController),
                    const SizedBox(height: space12),
                    _buildFormField(label: 'Mô tả', controller: _descriptionController, minLines: 4, maxLines: 6),
                    Row(
                      children: [
                        const SizedBox(height: space12),
                        Expanded(child: _buildFormField(label: 'Barcode', controller: _barcodeController)),
                        const SizedBox(width: space12),
                        Expanded(child: _buildFormField(label: 'SKU', controller: _skuController)),
                        const SizedBox(width: space12),
                        Expanded(child: _buildFormField(label: 'Đơn vị tính', controller: _unitController)),
                      ],
                    ),
                  ],
                ),
              ),
              // Thông tin y tế
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin y tế', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
                    const SizedBox(height: space16),
                    _buildFormField(label: 'Thành phần', controller: _ingredientsController, minLines: 4, maxLines: 6),
                    const SizedBox(height: space12),
                    _buildFormField(label: 'Chỉ định', controller: _usageController, minLines: 4, maxLines: 6),
                    const SizedBox(height: space12),
                    _buildFormField(label: 'Chống chỉ định', controller: _contraindicationController, maxLines: 2),
                    const SizedBox(height: space12),
                    _buildFormField(label: 'Cách dùng', controller: _directionController, maxLines: 2),
                    const SizedBox(height: space12),
                    _buildFormField(label: 'Thời gian ngưng sử dụng', controller: _withdrawalTimeController, maxLines: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: space32),
        // Cột 3: Trạng thái, Danh mục + Nhà cung cấp, Giá, Tồn kho, Tags
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trạng thái
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trạng thái', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
                    const SizedBox(height: space16),
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _isActive,
                          onChanged: (v) => setState(() => _isActive = v ?? true),
                          activeColor: mainGreen,
                        ),
                        const Text('Đang kinh doanh'),
                        const SizedBox(width: space16),
                        Radio<bool>(
                          value: false,
                          groupValue: _isActive,
                          onChanged: (v) => setState(() => _isActive = v ?? false),
                          activeColor: mainGreen,
                        ),
                        const Text('Ngừng kinh doanh'),
                      ],
                    ),
                    if (!_isActive) ...[
                      const SizedBox(height: space12),
                      _buildFormField(label: 'Lý do ngừng kinh doanh', controller: _discontinueReasonController),
                    ],
                  ],
                ),
              ),
              // Danh mục + Nhà cung cấp
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danh mục & Nhà cung cấp', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
                    const SizedBox(height: space16),
                    _buildFormField(
                      label: 'Danh mục',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SizedBox(
                          height: 40,
                          child: MultiSelectDropdown<ProductCategory>(
                            label: 'Danh mục',
                            items: _allCategories.map((c) => MultiSelectItem<ProductCategory>(value: c, label: c.name)).toList(),
                            initialSelectedValues: _selectedCategories,
                            onSelectionChanged: (values) { setState(() { _selectedCategories = values; }); },
                            hint: 'Chọn danh mục',
                            isTreeMode: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: space12),
                    _buildFormField(label: 'Nhà cung cấp', child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SizedBox(
                        height: 40,
                        child: MultiSelectDropdown<String>(
                          label: 'Company',
                          items: _allCompanies.map((c) => MultiSelectItem(value: c.id, label: c.name)).toList(),
                          initialSelectedValues: _selectedCompanyIds,
                          onSelectionChanged: (values) { setState(() { _selectedCompanyIds = values; }); },
                          hint: 'Chọn nhà cung cấp',
                        ),
                      ),
                    )),
                    if (_selectedCompanyIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedCompanyIds.map((id) {
                            final company = _allCompanies.firstWhereOrNull((c) => c.id == id);
                            return company == null ? const SizedBox() : Chip(
                              label: Text(company.name, style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600, fontSize: 14)),
                              backgroundColor: const Color(0xFFD1FADF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF22C55E)),
                              onDeleted: () => setState(() {
                                _selectedCompanyIds = List.from(_selectedCompanyIds)..remove(id);
                              }),
                              labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              // Giá
              SectionCard(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giá', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
                    const SizedBox(height: space12),
                    Row(
                      children: [
                        Expanded(child: _buildFormField(label: 'Giá nhập', controller: _costPriceController, keyboardType: TextInputType.number)),
                        const SizedBox(width: space12),
                        Expanded(child: _buildFormField(label: 'Giá bán', controller: _sellPriceController, keyboardType: TextInputType.number)),
                      ],
                    ),
                  ],
                ),
              ),
              // Tồn kho
              SectionCard(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Tồn kho', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
                      ],
                    ),
                    const SizedBox(height: space16),
                    _buildFormField(label: 'Số lượng', controller: _quantityController, keyboardType: TextInputType.number),
                  ],
                ),
              ),
              // Tags
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tags', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
                    const SizedBox(height: space16),
                    if (_tags.isNotEmpty) ...[
                      Wrap(
                        spacing: space8,
                        runSpacing: space8,
                        children: _tags.map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 8),
                          child: Chip(
                            label: Text(tag, style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600, fontSize: 13)),
                            backgroundColor: const Color(0xFFD1FADF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF22C55E)),
                            onDeleted: () => _removeTag(tag),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide.none,
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: space12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: inputHeight,
                            child: TextField(
                              controller: _tagsController,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm hoặc thêm tag',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadiusMedium)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: inputPadding, vertical: 0),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onSubmitted: (val) => _addTag(),
                            ),
                          ),
                        ),
                        const SizedBox(width: space8),
                        SizedBox(
                          height: inputHeight,
                          child: ElevatedButton(
                            onPressed: _addTag,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              elevation: 0,
                            ),
                            child: const Text('Thêm'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Ghi chú
              SectionCard(
                child: _buildFormField(label: 'Ghi chú', controller: _notesController, minLines: 2, maxLines: 4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ảnh sản phẩm lên đầu - Tạm thời ẩn, sẽ phát triển sau
        // SectionCard(
        //   padding: const EdgeInsets.all(16),
        //   child: _buildProductImageBlock(),
        // ),
        // const SizedBox(height: 16),
        // Thông tin cơ bản
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thông tin cơ bản', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
              const SizedBox(height: space16),
              _buildFormField(label: 'Tên thương mại *', controller: _commonNameController),
              const SizedBox(height: space12),
              _buildFormField(label: 'Tên nội bộ', controller: _nameController),
              const SizedBox(height: space12),
              _buildFormField(label: 'Mô tả', controller: _descriptionController, minLines: 3, maxLines: 5),
              const SizedBox(height: space12),
              _buildFormField(label: 'Barcode', controller: _barcodeController),
              const SizedBox(height: space12),
              _buildFormField(label: 'SKU', controller: _skuController),
              const SizedBox(height: space12),
              _buildFormField(label: 'Đơn vị tính', controller: _unitController),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Danh mục & Nhà cung cấp
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Danh mục & Nhà cung cấp', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
              const SizedBox(height: space16),
              _buildFormField(
                label: 'Danh mục',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SizedBox(
                    height: 40,
                    child: MultiSelectDropdown<ProductCategory>(
                      label: 'Danh mục',
                      items: _allCategories.map((c) => MultiSelectItem<ProductCategory>(value: c, label: c.name)).toList(),
                      initialSelectedValues: _selectedCategories,
                      onSelectionChanged: (values) { setState(() { _selectedCategories = values; }); },
                      hint: 'Chọn danh mục',
                      isTreeMode: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: space12),
              _buildFormField(label: 'Nhà cung cấp', child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SizedBox(
                  height: 40,
                  child: MultiSelectDropdown<String>(
                    label: 'Company',
                    items: _allCompanies.map((c) => MultiSelectItem(value: c.id, label: c.name)).toList(),
                    initialSelectedValues: _selectedCompanyIds,
                    onSelectionChanged: (values) { setState(() { _selectedCompanyIds = values; }); },
                    hint: 'Chọn nhà cung cấp',
                  ),
                ),
              )),
              if (_selectedCompanyIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCompanyIds.map((id) {
                      final company = _allCompanies.firstWhereOrNull((c) => c.id == id);
                      return company == null ? const SizedBox() : Chip(
                        label: Text(company.name, style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600, fontSize: 14)),
                        backgroundColor: const Color(0xFFD1FADF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF22C55E)),
                        onDeleted: () => setState(() {
                          _selectedCompanyIds = List.from(_selectedCompanyIds)..remove(id);
                        }),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Giá & Tồn kho
        SectionCard(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Giá', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
              const SizedBox(height: space16),
              Row(
                children: [
                  Checkbox(
                    value: _autoCalculatePrice,
                    onChanged: (val) {
                      setState(() {
                        _autoCalculatePrice = val ?? true;
                        if (_autoCalculatePrice) _calculateSalePrice();
                      });
                    },
                    activeColor: mainGreen,
                  ),
                  const Text('Tính giá tự động'),
                ],
              ),
              const SizedBox(height: 8),
              _buildFormField(
                label: 'Giá nhập *',
                controller: _costPriceController,
                keyboardType: TextInputType.number,
              ),
              if (_autoCalculatePrice) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 0, right: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lợi nhuận gộp (%)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: mainGreen,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 10),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: mainGreen,
                          inactiveTrackColor: mainGreen.withOpacity(0.15),
                          thumbColor: Colors.white,
                          overlayColor: mainGreen.withOpacity(0.15),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 2, pressedElevation: 4),
                          trackHeight: 4,
                          valueIndicatorColor: mainGreen,
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                          tickMarkShape: const RoundSliderTickMarkShape(),
                          showValueIndicator: ShowValueIndicator.never,
                        ),
                        child: Slider(
                          value: _profitMargin,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: '${_profitMargin.round()}%',
                          onChanged: (val) {
                            setState(() {
                              _profitMargin = val;
                              _profitMarginController.text = _profitMargin.toStringAsFixed(0);
                              _calculateSalePrice();
                            });
                          },
                        ),
                      ),
                      Center(
                        child: Text(
                          '${_profitMargin.round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: mainGreen,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _buildFormField(
                label: 'Giá bán *',
                controller: _sellPriceController,
                keyboardType: TextInputType.number,
                enabled: !_autoCalculatePrice,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tồn kho
        SectionCard(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
             color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Tồn kho', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
                ],
              ),
              const SizedBox(height: 16),
              _buildFormField(label: 'Số lượng', controller: _quantityController, keyboardType: TextInputType.number),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Thông tin y tế
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thông tin y tế', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
              const SizedBox(height: space16),
              _buildFormField(label: 'Thành phần', controller: _ingredientsController, minLines: 3, maxLines: 5),
              const SizedBox(height: space12),
              _buildFormField(label: 'Chỉ định', controller: _usageController, minLines: 3, maxLines: 5),
              const SizedBox(height: space12),
              _buildFormField(label: 'Chống chỉ định', controller: _contraindicationController, maxLines: 2),
              const SizedBox(height: space12),
              _buildFormField(label: 'Cách dùng', controller: _directionController, maxLines: 2),
              const SizedBox(height: space12),
              _buildFormField(label: 'Thời gian ngưng sử dụng', controller: _withdrawalTimeController, maxLines: 1),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Trạng thái
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trạng thái', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
              const SizedBox(height: space16),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _isActive,
                    onChanged: (v) => setState(() => _isActive = v ?? true),
                    activeColor: mainGreen,
                  ),
                  const Text('Đang kinh doanh'),
                  const SizedBox(width: space16),
                  Radio<bool>(
                    value: false,
                    groupValue: _isActive,
                    onChanged: (v) => setState(() => _isActive = v ?? false),
                    activeColor: mainGreen,
                  ),
                  const Text('Ngừng kinh doanh'),
                ],
              ),
              if (!_isActive) ...[
                const SizedBox(height: space12),
                _buildFormField(label: 'Lý do ngừng kinh doanh', controller: _discontinueReasonController),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tags
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tags', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
              const SizedBox(height: space16),
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: space8,
                  runSpacing: space8,
                  children: _tags.map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: Chip(
                      label: Text(tag, style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600, fontSize: 13)),
                      backgroundColor: const Color(0xFFD1FADF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF22C55E)),
                      onDeleted: () => _removeTag(tag),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide.none,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: space12),
              ],
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: inputHeight,
                      child: TextField(
                        controller: _tagsController,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm hoặc thêm tag',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadiusMedium)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: inputPadding, vertical: 0),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (val) => _addTag(),
                      ),
                    ),
                  ),
                  const SizedBox(width: space8),
                  SizedBox(
                    height: inputHeight,
                    child: ElevatedButton(
                      onPressed: _addTag,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        elevation: 0,
                      ),
                      child: const Text('Thêm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Ghi chú
        SectionCard(
          child: _buildFormField(label: 'Ghi chú', controller: _notesController, minLines: 2, maxLines: 4),
        ),
      ],
    );
  }
}

// SectionCard widget for consistent styling
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;

  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: decoration ?? BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
} 