import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';

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
  final _importPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _tagsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _usageController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategory;
  bool _isActive = false; // Mặc định là Không hoạt động như mẫu

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
                        'Thêm sản phẩm mới',
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
                                        DropdownButtonFormField<String>(
                                          value: _selectedCategory,
                                          decoration: InputDecoration(
                                            hintText: 'Chọn danh mục',
                                            border: OutlineInputBorder(
                                               borderRadius: BorderRadius.circular(5.0),
                                               borderSide: BorderSide(color: Colors.grey.shade200),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: '1', child: Text('Danh mục 1')),
                                            DropdownMenuItem(value: '2', child: Text('Danh mục 2')),
                                          ], // TODO: Replace with actual categories
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedCategory = value;
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Vui lòng chọn danh mục';
                                            }
                                            return null;
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
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final productData = {
                                    'name': _nameController.text,
                                    'commonName': _commonNameController.text,
                                    'barcode': _barcodeController.text,
                                    'sku': _skuController.text,
                                    'unit': _unitController.text,
                                    'quantity': int.tryParse(_quantityController.text) ?? 0,
                                    'importPrice': double.tryParse(_importPriceController.text) ?? 0.0,
                                    'sellPrice': double.tryParse(_sellPriceController.text) ?? 0.0,
                                    'tags': _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                                    'description': _descriptionController.text,
                                    'usage': _usageController.text,
                                    'ingredients': _ingredientsController.text,
                                    'notes': _notesController.text,
                                    'category': _selectedCategory,
                                    'isActive': _isActive,
                                  };
                                  print(productData);
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
