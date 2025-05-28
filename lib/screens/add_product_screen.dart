import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/main_layout.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../services/product_category_service.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Điền dữ liệu mẫu',
            onPressed: () {
              setState(() {
                _nameController.text = 'Amoxicillin 500mg';
                _commonNameController.text = 'Amoxicillin';
                _barcodeController.text = '8931234567890';
                _skuController.text = 'AMO500';
                _unitController.text = 'Viên';
                _quantityController.text = '100';
                _importPriceController.text = '25000';
                _sellPriceController.text = '35000';
                _tagsController.text = 'kháng sinh, phổ rộng';
                _descriptionController.text = 'Thuốc kháng sinh phổ rộng, điều trị nhiễm khuẩn';
                _usageController.text = 'Uống 1-2 viên/lần, 2-3 lần/ngày';
                _ingredientsController.text = 'Amoxicillin trihydrate 500mg';
                _notesController.text = 'Bảo quản nơi khô ráo, tránh ánh nắng trực tiếp';
                _selectedCategory = '1';
                _isActive = true;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DefaultTextStyle(
              style: const TextStyle(fontSize: 13.0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm mới',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Nhập thông tin sản phẩm',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      Card(
                        color: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: Colors.grey.shade300, width: 1.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 16.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Tên danh pháp *', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _nameController,
                                          readOnly: widget.isEdit,
                                          decoration: InputDecoration(
                                            hintText: 'Nhập tên danh pháp',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5.0),
                                              borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Vui lòng nhập tên danh pháp';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16.0),
                                        Text('Danh mục *', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        StreamBuilder<List<ProductCategory>>(
                                          stream: _categoryService.getCategories(),
                                          builder: (context, AsyncSnapshot<List<ProductCategory>> snapshot) {
                                            final categories = snapshot.data ?? [];
                                            // Nếu _selectedCategory không nằm trong danh sách, reset về null
                                            if (_selectedCategory != null && !categories.any((c) => c.name == _selectedCategory)) {
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                setState(() {
                                                  _selectedCategory = null;
                                                });
                                              });
                                            }
                                            return DropdownButtonFormField<String>(
                                              value: _selectedCategory,
                                              items: categories.map<DropdownMenuItem<String>>((cat) => DropdownMenuItem<String>(
                                                value: cat.name,
                                                child: Text(cat.name),
                                              )).toList(),
                                              onChanged: (v) => setState(() => _selectedCategory = v),
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                              ),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Vui lòng chọn danh mục';
                                                }
                                                return null;
                                              },
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 16.0),
                                        Text('SKU', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _skuController,
                                          decoration: InputDecoration(
                                            hintText: 'Nhập mã SKU',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Tên thông dụng', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _commonNameController,
                                          decoration: InputDecoration(
                                            hintText: 'Nhập tên thông dụng',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                        ),
                                        const SizedBox(height: 16.0),
                                        Text('Mã vạch', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _barcodeController,
                                          decoration: InputDecoration(
                                            hintText: 'Nhập mã vạch',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                        ),
                                        const SizedBox(height: 16.0),
                                        Text('Đơn vị tính', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _unitController,
                                          decoration: InputDecoration(
                                            hintText: 'VD: Viên, Chai, Lọ...',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      Card(
                        color: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: Colors.grey.shade300, width: 1.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Giá & Số lượng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 16.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Số lượng', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _quantityController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            hintText: '0',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                          validator: (value) {
                                            if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                                              return 'Số lượng không hợp lệ';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Giá nhập *', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _importPriceController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            hintText: '0',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                           validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Vui lòng nhập giá nhập';
                                            }
                                            if (double.tryParse(value) == null) {
                                              return 'Giá nhập không hợp lệ';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Giá bán *', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _sellPriceController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            hintText: '0',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Vui lòng nhập giá bán';
                                            }
                                            if (double.tryParse(value) == null) {
                                              return 'Giá bán không hợp lệ';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      Card(
                        color: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: Colors.grey.shade300, width: 1.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Thông tin chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 16.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Tags (phân cách bằng dấu phẩy)', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _tagsController,
                                          decoration: InputDecoration(
                                            hintText: 'VD: kháng sinh, giảm đau',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                        ),
                                        const SizedBox(height: 16.0),
                                        Text('Mô tả sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _descriptionController,
                                          decoration: InputDecoration(
                                            hintText: 'Nhập mô tả sản phẩm',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                          maxLines: 3,
                                        ),
                                        const SizedBox(height: 16.0),
                                        Text('Thành phần', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _ingredientsController,
                                          decoration: InputDecoration(
                                            hintText: 'Nhập thành phần sản phẩm',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                          maxLines: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Trạng thái sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Switch(value: _isActive, onChanged: (value) {
                                              setState(() {
                                                _isActive = value;
                                              });
                                            }),
                                          ],
                                        ),
                                        const SizedBox(height: 16.0),
                                        Text('Công dụng', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _usageController,
                                          decoration: InputDecoration(
                                            hintText: 'Nhập công dụng sản phẩm',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                          maxLines: 3,
                                        ),
                                        const SizedBox(height: 16.0),
                                        Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: _notesController,
                                          decoration: InputDecoration(
                                            hintText: 'Nhập ghi chú',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                          maxLines: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: widget.onBack,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                foregroundColor: Colors.blue,
                              ),
                              child: const Text('Hủy'),
                            ),
                            const SizedBox(width: 16.0),
                            ElevatedButton.icon(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  final barcode = _barcodeController.text.trim();
                                  final sku = _skuController.text.trim();
                                  final name = _nameController.text.trim();
                                  final importPrice = double.tryParse(_importPriceController.text) ?? 0.0;
                                  final salePrice = double.tryParse(_sellPriceController.text) ?? 0.0;
                                  final firestore = FirebaseFirestore.instance;
                                  final productsRef = firestore.collection('products');
                                  // Kiểm tra trùng barcode (loại trừ sản phẩm hiện tại khi sửa)
                                  if (barcode.isNotEmpty) {
                                    final barcodeQuery = await productsRef.where('barcode', isEqualTo: barcode).get();
                                    if (barcodeQuery.docs.any((doc) => widget.isEdit ? doc.id != widget.product?.id : true)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Mã vạch đã tồn tại!')),
                                      );
                                      return;
                                    }
                                  }
                                  // Kiểm tra trùng SKU (loại trừ sản phẩm hiện tại khi sửa)
                                  if (sku.isNotEmpty) {
                                    final skuQuery = await productsRef.where('sku', isEqualTo: sku).get();
                                    if (skuQuery.docs.any((doc) => widget.isEdit ? doc.id != widget.product?.id : true)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('SKU đã tồn tại!')),
                                      );
                                      return;
                                    }
                                  }
                                  // Cảnh báo nếu giá bán < giá nhập
                                  if (salePrice < importPrice) {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Cảnh báo'),
                                        content: const Text('Giá bán nhỏ hơn giá nhập. Bạn vẫn muốn lưu sản phẩm này?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Hủy'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Vẫn lưu'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm != true) return;
                                  }
                                  // Tạo dữ liệu sản phẩm
                                  final productData = {
                                    'name': name,
                                    'commonName': _commonNameController.text,
                                    'barcode': barcode,
                                    'sku': sku,
                                    'unit': _unitController.text,
                                    'stock': int.tryParse(_quantityController.text) ?? 0,
                                    'importPrice': importPrice,
                                    'salePrice': salePrice,
                                    'tags': _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                                    'description': _descriptionController.text,
                                    'usage': _usageController.text,
                                    'ingredients': _ingredientsController.text,
                                    'notes': _notesController.text,
                                    'category': _selectedCategory,
                                    'isActive': _isActive,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  };
                                  try {
                                    if (widget.isEdit && widget.product != null) {
                                      // 1. Cập nhật các trường sản phẩm trước (không có editHistory)
                                      await productsRef.doc(widget.product!.id).update(productData);

                                      // 2. Lấy server timestamp thực tế
                                      final serverTimeDoc = await firestore.collection('serverTime').add({'ts': FieldValue.serverTimestamp()});
                                      final serverTimeSnap = await serverTimeDoc.get();
                                      final serverTimestamp = serverTimeSnap['ts'];

                                      // 3. Thêm lịch sử chỉnh sửa với timestamp thực tế
                                      final editHistory = {
                                        'editor': 'user@example.com', // TODO: Lấy user thực tế nếu có auth
                                        'editedAt': serverTimestamp,
                                        'fieldsChanged': productData.keys.toList(),
                                      };
                                      await productsRef.doc(widget.product!.id).update({
                                        'editHistory': FieldValue.arrayUnion([editHistory]),
                                      });

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Cập nhật sản phẩm thành công!')),
                                      );
                                      if (widget.onBack != null) {
                                        widget.onBack!();
                                      }
                                    } else {
                                      // Thêm mới
                                      await productsRef.add({
                                        ...productData,
                                        'createdAt': FieldValue.serverTimestamp(),
                                      });
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã lưu sản phẩm thành công!')),
                                      );
                                      if (widget.onBack != null) {
                                        widget.onBack!();
                                      }
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi khi lưu sản phẩm: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.save),
                              label: const Text('Lưu sản phẩm'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
