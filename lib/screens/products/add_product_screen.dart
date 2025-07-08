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
import 'dart:html' as html;
import 'package:collection/collection.dart';
import '../../widgets/common/design_system.dart';
import '../../models/product_category.dart';
import '../../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AddProductScreen({super.key, this.onBack});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> with TickerProviderStateMixin {
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
  final bool _autoCalculatePrice = true;
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

  // Tab controller for modern tabbed interface
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _profitMarginController.text = _defaultProfitMargin.toStringAsFixed(0);
    _loadCompanies();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        if (_selectedCategories.isNotEmpty && _selectedCategories.first is String) {
          final idSet = Set<String>.from(_selectedCategories as List<String>);
          _selectedCategories = _allCategories.where((c) => idSet.contains(c.id)).toList();
        }
      });
    }
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
    final profitMargin = double.tryParse(_profitMarginController.text) ?? _defaultProfitMargin;
    if (costPrice > 0) {
      final salePrice = costPrice * (1 + profitMargin / 100);
      final formattedPrice = formatCurrency(salePrice);
      _sellPriceController.value = TextEditingValue(
        text: formattedPrice,
        selection: TextSelection.collapsed(offset: formattedPrice.length),
      );
    } else {
      _sellPriceController.text = '';
    }
  }

  Future<void> _pickMultiImageFromGallery() async {
    if (kIsWeb) {
      final input = html.FileUploadInputElement()..accept = 'image/*'..multiple = true;
      input.click();
      input.onChange.listen((event) {
        final files = input.files;
        if (files != null && files.isNotEmpty) {
          int remain = 5 - _webImageBytesList.length;
          if (files.length > remain) {
            _showPopupNotification('Chỉ được chọn tối đa 5 ảnh', Icons.error_outline);
          }
          for (final file in files.take(remain)) {
            final reader = html.FileReader();
            reader.readAsArrayBuffer(file);
            reader.onLoadEnd.listen((event) {
              setState(() {
                _webImageBytesList.add(reader.result as Uint8List);
              });
            });
          }
        }
      });
    } else {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles.isNotEmpty) {
        int remain = 5 - _productImageFiles.length;
        if (pickedFiles.length > remain) {
          _showPopupNotification('Chỉ được chọn tối đa 5 ảnh', Icons.error_outline);
        }
        setState(() {
          _productImageFiles.addAll(pickedFiles.take(remain).map((e) => File(e.path)));
        });
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (kIsWeb) return;
    if (_productImageFiles.length >= 5) {
      _showPopupNotification('Chỉ được chọn tối đa 5 ảnh', Icons.error_outline);
      return;
    }
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        if (_productImageFiles.length < 5) {
          _productImageFiles.add(File(pickedFile.path));
        }
      });
    }
  }

  void _removeImage() {
    setState(() {
      _productImageFiles.clear();
      _productImageUrls.clear();
    });
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putFile(imageFile);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Upload image error: $e');
      return null;
    }
  }

  Future<List<String>> _uploadAllImages() async {
    List<String> urls = [];
    if (kIsWeb && _webImageBytesList.isNotEmpty) {
      for (final bytes in _webImageBytesList) {
        final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}_${urls.length}.web.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        final uploadTask = await ref.putData(bytes);
        final url = await uploadTask.ref.getDownloadURL();
        urls.add(url);
      }
    } else if (_productImageFiles.isNotEmpty) {
      for (final file in _productImageFiles) {
        final url = await _uploadImageToFirebase(file);
        if (url != null) urls.add(url);
      }
    }
    return urls;
  }

  @override
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      List<String> imageUrls = await _uploadAllImages();
      if (imageUrls.isNotEmpty) {
        _productImageUrls = imageUrls;
      }
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
        'status': _isActive ? 'active' : 'inactive',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'images': imageUrls,
        'main_image': imageUrls.isNotEmpty ? imageUrls[_mainImageIndex.clamp(0, imageUrls.length-1)] : null,
        'mfg_date': _mfgDate,
        'exp_date': _expDate,
        'origin': _originController.text.trim(),
        'contraindication': _contraindicationController.text.trim(),
        'direction': _directionController.text.trim(),
        'withdrawal_time': _withdrawalTimeController.text.trim(),
      };
      final productData = Product.normalizeProductData(rawData);
      final docRef = await FirebaseFirestore.instance.collection('products').add(productData);
      
      // Lưu mối quan hệ Product-Category với hierarchy (Approach 2)
      if (_selectedCategories.isNotEmpty) {
        // Lấy tất cả category IDs (bao gồm cả parent categories)
        final allCategoryIds = await _getAllCategoryIdsForProduct(_selectedCategories.map((c) => c.id).toList());
        
        // Lưu tất cả mối quan hệ vào product_categories collection
        final batch = FirebaseFirestore.instance.batch();
        for (final categoryId in allCategoryIds) {
          final relationDocRef = FirebaseFirestore.instance.collection('product_categories').doc();
          batch.set(relationDocRef, {
            'product_id': docRef.id,
            'category_id': categoryId,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        
        debugPrint('=== APPROACH 2: Đã lưu hierarchy ===');
        debugPrint('Product ID: ${docRef.id}');
        debugPrint('Selected categories: $_selectedCategories');
        debugPrint('All category IDs (including parents): $allCategoryIds');
        debugPrint('Total relationships created: ${allCategoryIds.length}');
      }
      
      // Lưu mối quan hệ Product-Company vào bảng trung gian
      if (_selectedCompanyIds.isNotEmpty) {
        await _productCompanyService.addProductCompanies(docRef.id, _selectedCompanyIds);
      }
      
      if (mounted) {
        // Hiển thị popup thông báo thành công theo styleguide
        _showPopupNotification('Đã thêm sản phẩm mới thành công!', Icons.check_circle);
        
        if (widget.onBack != null) widget.onBack!();
      }
    } catch (e) {
      if (mounted) {
        // Hiển thị popup thông báo lỗi theo styleguide
        _showPopupNotification('Lỗi: $e', Icons.error_outline);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
      _costPriceController.text = formatCurrency(100000);
      _sellPriceController.text = formatCurrency(120000);
      _profitMarginController.text = '20';
      _quantityController.text = '50';
      _isActive = true;
      _notesController.text = 'Ghi chú sản phẩm mẫu';
      _selectedCompanyIds = _allCompanies.isNotEmpty ? [_allCompanies.first.id] : [];
      _mfgDate = DateTime(DateTime.now().year - 1, 1, 1);
      _expDate = DateTime(DateTime.now().year + 1, 1, 1);
      _originController.text = 'Việt Nam';
      _contraindicationController.text = 'Không có';
      _directionController.text = 'Không có';
      _withdrawalTimeController.text = 'Không có';
    });
  }

  Future<void> _createSampleCategories() async {
    try {
      final sampleCategories = [
        ProductCategory(id: '', name: 'Kháng sinh', description: 'Thuốc kháng sinh'),
        ProductCategory(id: '', name: 'Vitamin', description: 'Vitamin và khoáng chất'),
        ProductCategory(id: '', name: 'Thuốc giảm đau', description: 'Thuốc giảm đau, hạ sốt'),
        ProductCategory(id: '', name: 'Thuốc khác', description: 'Các loại thuốc khác'),
      ];

      for (final category in sampleCategories) {
        await _categoryService.addCategory(category);
      }

      if (mounted) {
        // Hiển thị popup thông báo thành công theo styleguide
        _showPopupNotification('Đã tạo danh mục mẫu thành công!', Icons.check_circle);
      }
    } catch (e) {
      if (mounted) {
        // Hiển thị popup thông báo lỗi theo styleguide
        _showPopupNotification('Lỗi: $e', Icons.error_outline);
      }
    }
  }

  // Helper method để lấy tất cả parent category IDs
  Future<List<String>> _getAllParentCategoryIds(String categoryId) async {
    List<String> parentIds = [];
    String? currentId = categoryId;
    
    while (currentId != null && currentId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance.collection('categories').doc(currentId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final parentId = data['parentId'] as String?;
        if (parentId != null && parentId.isNotEmpty) {
          parentIds.add(parentId);
          currentId = parentId;
        } else {
          break;
        }
      } else {
        break;
      }
    }
    
    return parentIds;
  }

  // Helper method để lấy tất cả category IDs (bao gồm cả parent) cho một sản phẩm
  Future<List<String>> _getAllCategoryIdsForProduct(List<String> selectedCategoryIds) async {
    Set<String> allCategoryIds = {};
    for (final categoryId in selectedCategoryIds) {
      allCategoryIds.add(categoryId);
      final parentIds = await _getAllParentCategoryIds(categoryId);
      allCategoryIds.addAll(parentIds);
    }
    return allCategoryIds.toList();
  }

  // Debug method để hiển thị thông tin hierarchy
  Future<void> _debugCategoryHierarchy() async {
    if (_selectedCategories.isEmpty) {
      debugPrint('Không có category nào được chọn');
      return;
    }
    
    debugPrint('=== DEBUG CATEGORY HIERARCHY ===');
    debugPrint('Selected categories: $_selectedCategories');
    
    for (final category in _selectedCategories) {
      final parentIds = await _getAllParentCategoryIds(category.id);
      debugPrint('Category ${category.id} -> Parent IDs: $parentIds');
    }
    
    final allCategoryIds = await _getAllCategoryIdsForProduct(_selectedCategories.map((c) => c.id).toList());
    debugPrint('All category IDs (including parents): $allCategoryIds');
    debugPrint('=== END DEBUG ===');
  }

  // Helper method để hiển thị popup thông báo
  void _showPopupNotification(String message, IconData icon) {
    if (!mounted) return;
    
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

  // Test method để tạo category mới với Materialized Path
  Future<void> _testCreateCategoryWithPath() async {
    try {
      debugPrint('=== TEST CREATE CATEGORY WITH PATH ===');
      
      // Tạo root category
      final rootCategory = ProductCategory(
        id: '',
        name: 'Thuốc',
        description: 'Danh mục thuốc chính',
        parentId: null,
      );
      
      await _categoryService.addCategory(rootCategory);
      debugPrint('✅ Đã tạo root category: Thuốc');
      
      // Lấy root category ID
      final categories = await _categoryService.getCategories().first;
      final rootCat = categories.firstWhere((c) => c.name == 'Thuốc');
      
      // Tạo child category
      final childCategory = ProductCategory(
        id: '',
        name: 'Vitamin',
        description: 'Vitamin và khoáng chất',
        parentId: rootCat.id,
      );
      
      await _categoryService.addCategory(childCategory);
      debugPrint('✅ Đã tạo child category: Vitamin (parent: ${rootCat.name})');
      
      // Lấy child category ID
      final updatedCategories = await _categoryService.getCategories().first;
      final vitaminCat = updatedCategories.firstWhere((c) => c.name == 'Vitamin');
      
      debugPrint('📊 Category info:');
      debugPrint('   - ID: ${vitaminCat.id}');
      debugPrint('   - Name: ${vitaminCat.name}');
      debugPrint('   - Parent ID: ${vitaminCat.parentId}');
      debugPrint('   - Path: ${vitaminCat.path}');
      debugPrint('   - Path Array: ${vitaminCat.pathArray}');
      debugPrint('   - Level: ${vitaminCat.level}');
      
      if (mounted) {
        // Hiển thị popup thông báo thành công theo styleguide
        _showPopupNotification('✅ Đã tạo category test thành công!', Icons.check_circle);
      }
      
    } catch (e) {
      debugPrint('❌ Lỗi test: $e');
      if (mounted) {
        // Hiển thị popup thông báo lỗi theo styleguide
        _showPopupNotification('Lỗi: $e', Icons.error_outline);
      }
    }
  }

  Future<void> _pickMfgDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _mfgDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      helpText: 'Chọn năm sản xuất',
      fieldLabelText: 'Năm sản xuất',
      fieldHintText: 'yyyy',
      initialEntryMode: DatePickerEntryMode.calendar,
    );
    if (picked != null) {
      setState(() => _mfgDate = picked);
    }
  }

  Future<void> _pickExpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
      helpText: 'Chọn năm hết hạn',
      fieldLabelText: 'Năm hết hạn',
      fieldHintText: 'yyyy',
      initialEntryMode: DatePickerEntryMode.calendar,
    );
    if (picked != null) {
      setState(() => _expDate = picked);
    }
  }

  void _removeImageAt(int index) {
    setState(() {
      if (kIsWeb && _webImageBytesList.isNotEmpty) {
        _webImageBytesList.removeAt(index);
      } else if (_productImageFiles.isNotEmpty) {
        _productImageFiles.removeAt(index);
      } else if (_productImageUrls.isNotEmpty) {
        _productImageUrls.removeAt(index);
      }
      if (_mainImageIndex >= index && _mainImageIndex > 0) {
        _mainImageIndex--;
      }
    });
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
                      onPressed: widget.onBack,
                    ),
                    Expanded(
                      child: Text(
                        'Thêm sản phẩm mới',
                        style: h2Mobile.copyWith(color: Colors.white),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _fillSampleData,
                      icon: const Icon(Icons.auto_fix_high, size: 18, color: Colors.white),
                      label: Text(isDesktop ? 'Dữ liệu mẫu' : 'Mẫu', style: const TextStyle(color: Colors.white)),
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
        // Cột 7: Thông tin cơ bản, Ảnh sản phẩm, Thông tin y tế
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              // Ảnh sản phẩm
              SectionCard(
                padding: const EdgeInsets.all(16),
                child: _buildProductImageBlock(),
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
                    const SizedBox(height: space12),
                    _buildFormField(label: 'Nguồn gốc xuất xứ', controller: _originController),
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

  Widget _buildSidebarCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSidebarInfoItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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
        // 1. Ảnh sản phẩm
        _buildProductImageBlock(),
        const SizedBox(height: 16),
        // 2. Thông tin cơ bản
        SectionCard(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: space12),
              _buildFormField(label: 'Barcode', controller: _barcodeController),
              const SizedBox(height: space12),
              _buildFormField(label: 'SKU', controller: _skuController),
              const SizedBox(height: space12),
              _buildFormField(label: 'Đơn vị tính', controller: _unitController),
              const SizedBox(height: space12),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 3. Danh mục & Nhà phân phối
        SectionCard(
          padding: const EdgeInsets.all(16),
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
        // 4. Giá
        SectionCard(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  Text('Giá', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: mainGreen)),
                ],
              ),
              const SizedBox(height: space16),
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
        const SizedBox(height: 16),
        // 5. Tồn kho
        SectionCard(
          padding: const EdgeInsets.all(16),
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
        const SizedBox(height: 16),
        // 6. Thông tin y tế
        SectionCard(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: space12),
              _buildFormField(label: 'Nguồn gốc xuất xứ', controller: _originController),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 7. Trạng thái
        SectionCard(
          padding: const EdgeInsets.all(16),
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
        // 8. Tag
        SectionCard(
          padding: const EdgeInsets.all(16),
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
        // 9. Ghi chú
        SectionCard(
          padding: const EdgeInsets.all(16),
          child: _buildFormField(label: 'Ghi chú', controller: _notesController, minLines: 2, maxLines: 4),
        ),
      ],
    );
  }

  Widget _buildProductImageBlock() {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ảnh sản phẩm', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF22C55E))),
          const SizedBox(height: 16),
          // Hiển thị grid ảnh
          if ((kIsWeb && _webImageBytesList.isNotEmpty) || _productImageFiles.isNotEmpty || _productImageUrls.isNotEmpty)
            Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: kIsWeb ? _webImageBytesList.length : (_productImageFiles.isNotEmpty ? _productImageFiles.length : _productImageUrls.length),
                  itemBuilder: (context, index) {
                    Widget img;
                    if (kIsWeb && _webImageBytesList.isNotEmpty) {
                      img = Image.memory(_webImageBytesList[index], fit: BoxFit.cover);
                    } else if (_productImageFiles.isNotEmpty) {
                      img = Image.file(_productImageFiles[index], fit: BoxFit.cover);
                    } else {
                      img = Image.network(_productImageUrls[index], fit: BoxFit.cover);
                    }
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox.expand(child: img),
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImageAt(index),
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
                              child: const Icon(Icons.close, size: 18, color: Colors.red),
                            ),
                          ),
                        ),
                        if (index == _mainImageIndex)
                          Positioned(
                            bottom: 4, left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Color(0xFF22C55E), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Đại diện', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          )
                        else
                          Positioned(
                            bottom: 4, left: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _mainImageIndex = index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Color(0xFF22C55E))),
                                child: const Text('Chọn đại diện', style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          // Nút upload nhiều ảnh
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (kIsWeb ? _webImageBytesList.length : _productImageFiles.length) >= 5 ? null : _pickMultiImageFromGallery,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    foregroundColor: Colors.grey[800],
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ).copyWith(
                    side: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
                        return const BorderSide(color: Color(0xFF22C55E), width: 1.5);
                      }
                      return BorderSide(color: Colors.grey[300]!);
                    }),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.upload_outlined, size: 28, color: Color(0xFF475569)),
                      SizedBox(height: 8),
                      Text('Tải nhiều ảnh', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              if (!kIsWeb) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _productImageFiles.length >= 5 ? null : _pickImageFromCamera,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      foregroundColor: Colors.grey[800],
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ).copyWith(
                      side: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
                          return const BorderSide(color: Color(0xFF22C55E), width: 1.5);
                        }
                        return BorderSide(color: Colors.grey[300]!);
                      }),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.photo_camera_outlined, size: 28, color: Color(0xFF475569)),
                        SizedBox(height: 8),
                        Text('Chụp ảnh', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    TextEditingController? controller,
    String? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
    int maxLines = 1,
    int? minLines,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    Widget? child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 4),
              Text(
                suffix,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (child != null)
          child
        else
          SizedBox(
            height: (maxLines == 1 && (minLines == null || minLines == 1)) ? inputHeight : null,
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              maxLines: maxLines,
              minLines: minLines,
              onChanged: onChanged,
              validator: validator,
              style: const TextStyle(fontSize: 15, height: 1.2),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: mainGreen, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: destructiveRed, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: destructiveRed, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: inputPadding, vertical: maxLines > 1 || (minLines != null && minLines > 1) ? 12 : 0),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  const SectionCard({super.key, required this.child, this.padding, this.decoration});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: padding ?? const EdgeInsets.all(cardPadding),
      decoration: decoration ?? BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}

// Thêm widget _ProductSearchSheet để fix lỗi linter
class _ProductSearchSheet extends StatefulWidget {
  final Function(Product)? onProductSelected;
  const _ProductSearchSheet({this.onProductSelected});

  @override
  State<_ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<_ProductSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  List<Product> _results = [];
  bool _loading = false;

  void _onChanged() async {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final products = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      _results = products.docs.map((doc) => Product.fromMap(doc.id, doc.data())).where((p) =>
        p.internalName.toLowerCase().contains(query) ||
        p.tradeName.toLowerCase().contains(query) ||
        (p.barcode?.toLowerCase().contains(query) ?? false) ||
        (p.sku?.toLowerCase().contains(query) ?? false)
      ).toList();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.98,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm sản phẩm theo tên, mã vạch, SKU...',
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => _onChanged(),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results = []);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_results.isEmpty && _controller.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Không tìm thấy sản phẩm phù hợp', style: TextStyle(color: Colors.grey)),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = _results[index];
                    return ListTile(
                      title: Text(p.tradeName.isNotEmpty ? p.tradeName : p.internalName),
                      subtitle: Text('Barcode: ${p.barcode ?? ''} | SKU: ${p.sku ?? ''}'),
                      onTap: () {
                        if (widget.onProductSelected != null) widget.onProductSelected!(p);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
} 