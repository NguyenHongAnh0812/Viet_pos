import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'package:intl/intl.dart' show NumberFormat;
import '../widgets/main_layout.dart';
import 'products/product_detail_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ex;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:math' show min;
import 'dart:html' as html;
import '../widgets/product_card_item.dart';
import '../widgets/product_list_card.dart';
import '../widgets/common/design_system.dart';

// Custom thumb shape with blue border
class BlueBorderThumbShape extends RoundSliderThumbShape {
  const BlueBorderThumbShape({
    double enabledThumbRadius = 9.0,
    double disabledThumbRadius = 9.0,
  }) : super(enabledThumbRadius: enabledThumbRadius, disabledThumbRadius: disabledThumbRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter? labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
    bool isEnabled = false,
    bool isOnTop = false,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;
    final double radius = isEnabled
        ? (enabledThumbRadius ?? 9.0)
        : (disabledThumbRadius ?? 9.0);
    final Paint fillPaint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white;
    final Paint borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);
  }
}

class ProductListScreen extends StatefulWidget {
  final Function(Product)? onProductTap;
  final Function(MainPage)? onNavigate;
  const ProductListScreen({super.key, this.onProductTap, this.onNavigate});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = 'Tất cả';
  RangeValues priceRange = const RangeValues(0, 1000000);
  RangeValues stockRange = const RangeValues(0, 99999);
  String status = 'Tất cả';
  Set<String> selectedTags = {};
  String searchText = '';
  bool isFilterOpen = false;
  String sortOption = 'name_asc';
  int minStock = 0;
  int maxStock = 99999;
  double minPrice = 0;
  double maxPrice = 1000000;
  String tempSelectedCategory = '';
  RangeValues? tempPriceRange;
  RangeValues? tempStockRange;
  String tempStatus = '';
  Set<String> tempSelectedTags = {};
  String tempSearchText = '';
  // Multi-select state for checkboxes
  final ValueNotifier<Set<String>> selectedProductIds = ValueNotifier({});
  int currentProductCount = 0;
  // Thêm biến lưu file import
  PlatformFile? _importFile;
  bool _overwrite = false;
  List<List<String>>? _csvPreviewRows;
  List<String>? _csvPreviewHeaders;

  final List<Map<String, dynamic>> sortOptions = [
    {
      'key': 'name_asc',
      'label': 'Tên (A → Z)',
      'icon': Icons.arrow_downward,
    },
    {
      'key': 'name_desc',
      'label': 'Tên (Z → A)',
      'icon': Icons.arrow_upward,
    },
    {
      'key': 'price_asc',
      'label': 'Giá: Thấp → Cao',
      'icon': Icons.arrow_downward,
    },
    {
      'key': 'price_desc',
      'label': 'Giá: Cao → Thấp',
      'icon': Icons.arrow_upward,
    },
    {
      'key': 'stock_asc',
      'label': 'Tồn kho: Ít → Nhiều',
      'icon': Icons.arrow_upward,
    },
    {
      'key': 'stock_desc',
      'label': 'Tồn kho: Nhiều → Ít',
      'icon': Icons.arrow_downward,
    },
  ];

  List<String> getCategoriesFromProducts(List<Product> products) {
    final set = products.map((p) => p.category).where((c) => c != null && c.isNotEmpty).toSet();
    final list = set.toList()..sort();
    return ['Tất cả', ...list];
  }

  List<String> get allTags => ['kháng sinh', 'phổ rộng', 'vitamin', 'bổ sung', 'NSAID', 'giảm đau', 'quinolone'];

  List<Product> filterProducts(List<Product> products) {
    print('\n=== Product Filtering Debug ===');
    print('Raw products from Firebase: ${products.length}');
    print('Current filter settings:');
    print('- Category: $selectedCategory');
    print('- Price range: $priceRange');
    print('- Stock range: $stockRange');
    print('- Status: $status');
    print('- Selected tags: $selectedTags');
    print('- Search text: $searchText');
    
    final filtered = products.where((p) {
      // Category filter
      if (selectedCategory != 'Tất cả' && p.category != selectedCategory) {
        return false;
      }
      
      // Price filter
      if (p.salePrice < priceRange.start || p.salePrice > priceRange.end) {
        return false;
      }
      
      // Stock filter - Only apply if stock range is not default
      if (stockRange.start > 0 || stockRange.end < 99999) {
        if (p.stock < stockRange.start || p.stock > stockRange.end) {
          return false;
        }
      }
      
      // Status filter
      if (status == 'Còn bán' && !p.isActive) {
        return false;
      }
      if (status == 'Ngừng bán' && p.isActive) {
        return false;
      }
      
      // Tags filter - Only apply if tags are selected
      if (selectedTags.isNotEmpty) {
        if (!selectedTags.any((tag) => p.tags.contains(tag))) {
          return false;
        }
      }
      
      // Search text filter - Only apply if search text is not empty
      if (searchText.isNotEmpty) {
        if (!p.name.toLowerCase().contains(searchText.toLowerCase()) && 
            !(p.barcode != null && p.barcode!.toLowerCase().contains(searchText.toLowerCase()))) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    print('\nFiltering results:');
    print('- Total products: ${products.length}');
    print('- Filtered products: ${filtered.length}');
    print('- Filtered out: ${products.length - filtered.length}');
    print('=== End Product Filtering Debug ===\n');
    
    return filtered;
  }

  List<Product> sortProducts(List<Product> products) {
    switch (sortOption) {
      case 'name_asc':
        products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        products.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'price_asc':
        products.sort((a, b) => a.salePrice.compareTo(b.salePrice));
        break;
      case 'price_desc':
        products.sort((a, b) => b.salePrice.compareTo(a.salePrice));
        break;
      case 'stock_asc':
        products.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'stock_desc':
        products.sort((a, b) => b.stock.compareTo(a.stock));
        break;
    }
    return products;
  }

  Future<void> _importProductsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );

      if (result == null) return;

      final file = result.files.first;
      print('Importing file: ${file.name}');

      List<Map<String, dynamic>> products = [];
      final bytes = file.bytes!;
      final fileName = file.name.toLowerCase();

      if (fileName.endsWith('.csv')) {
        // Xử lý file CSV
        String csvString = utf8.decode(bytes);
        // Chuẩn hóa line break về \n
        csvString = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        print('CSV content length: \\${csvString.length}');
        print('CSV content preview: \\${csvString.substring(0, min(200, csvString.length))}');

        final csvTable = const CsvToListConverter().convert(csvString);
        print('CSV table length: \\${csvTable.length}');

        if (csvTable.isEmpty) {
          throw Exception('File CSV không có dữ liệu');
        }

        // Lấy header và chuyển về chữ thường
        final headers = (csvTable[0] as List).map((e) => e.toString().trim().toLowerCase()).toList();
        print('Raw headers: \\${headers}');

        // Mapping header tiếng Việt sang tên trường tiếng Anh
        final headerMapping = {
          'tên danh pháp': 'name',
          'tên thường gọi': 'commonName',
          'danh mục sản phẩm': 'category',
          'mã vạch': 'barcode',
          'sku': 'sku',
          'đơn vị tính': 'unit',
          'tags': 'tags',
          'mô tả': 'description',
          'công dụng': 'usage',
          'thành phần': 'ingredients',
          'ghi chú': 'notes',
          'số lượng sản phẩm': 'stock',
          'giá nhập': 'importPrice',
          'giá bán': 'salePrice',
          'trạng thái': 'isActive'
        };

        // Chuyển đổi header sang tiếng Anh
        final processedHeaders = headers.map((h) => headerMapping[h] ?? h).toList();
        print('Processed headers: \\${processedHeaders}');

        // Kiểm tra các trường bắt buộc
        final requiredFields = ['name', 'category', 'unit', 'stock'];
        final missingFields = requiredFields.where((field) => !processedHeaders.contains(field)).toList();
        if (missingFields.isNotEmpty) {
          print('Thiếu các trường bắt buộc: \\${missingFields.join(", ")}');
          throw Exception('Thiếu các trường bắt buộc: \\${missingFields.join(", ")}');
        }

        // Xử lý từng dòng dữ liệu
        for (var i = 1; i < csvTable.length; i++) {
          final row = csvTable[i] as List;
          print('Row $i (${row.length} columns): $row');

          if (row.length != headers.length) {
            print('Bỏ qua dòng $i: Số lượng cột không khớp với header (${row.length} != ${headers.length})');
            continue;
          }

          final product = <String, dynamic>{};
          for (var j = 0; j < headers.length; j++) {
            final header = headers[j];
            final value = row[j].toString().trim();
            final field = headerMapping[header];

            if (field != null) {
              switch (field) {
                case 'stock':
                  product[field] = int.tryParse(value) ?? 0;
                  break;
                case 'importPrice':
                case 'salePrice':
                  product[field] = double.tryParse(value) ?? 0.0;
                  break;
                case 'isActive':
                  product[field] = value.toLowerCase() == 'còn bán';
                  break;
                case 'tags':
                  product[field] = value.split(',').map((e) => e.trim()).toList();
                  break;
                default:
                  product[field] = value;
              }
            }
          }

          // Thêm các trường mặc định nếu chưa có
          product['commonName'] ??= product['name'];
          product['importPrice'] ??= 0.0;
          product['salePrice'] ??= 0.0;
          product['isActive'] ??= true;
          product['createdAt'] = FieldValue.serverTimestamp();
          product['updatedAt'] = FieldValue.serverTimestamp();

          // Kiểm tra dữ liệu bắt buộc
          bool valid = true;
          for (final field in requiredFields) {
            if (product[field] == null || product[field].toString().isEmpty) {
              print('Bỏ qua dòng $i: Thiếu trường bắt buộc $field, value: ${product[field]}');
              valid = false;
            }
          }
          if (!valid) {
            print('Dòng $i bị bỏ qua do thiếu trường bắt buộc. Product: $product');
            continue;
          }

          print('Created product (row $i): $product');
          products.add(product);
        }
        print('Tổng số sản phẩm hợp lệ được import: ${products.length}');
      } else {
        // Xử lý file Excel
        final excel = ex.Excel.decodeBytes(bytes);
        final sheet = excel.tables[excel.tables.keys.first];
        if (sheet == null) throw 'Sheet không hợp lệ';
        
        final headers = sheet.rows.first.map((cell) => cell?.value.toString().trim().toLowerCase() ?? '').toList();
        print('Excel headers (gốc): $headers');
        // Mapping header tiếng Việt sang tên trường tiếng Anh
        final headerMapping = {
          'tên danh pháp': 'name',
          'tên thường gọi': 'commonName',
          'danh mục sản phẩm': 'category',
          'mã vạch': 'barcode',
          'sku': 'sku',
          'đơn vị tính': 'unit',
          'tags': 'tags',
          'mô tả': 'description',
          'công dụng': 'usage',
          'thành phần': 'ingredients',
          'ghi chú': 'notes',
          'số lượng sản phẩm': 'stock',
          'giá nhập': 'importPrice',
          'giá bán': 'salePrice',
          'trạng thái': 'isActive'
        };
        final processedHeaders = headers.map((h) => headerMapping[h] ?? h).toList();
        print('Processed Excel headers (mapping): $processedHeaders');
        for (var i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          final Map<String, dynamic> product = {};
          for (var j = 0; j < processedHeaders.length; j++) {
            final field = processedHeaders[j];
            if (field == null || field.isEmpty) continue;
            final cell = row[j];
            final value = cell?.value;
            print('Row $i, Col $j: header="${headers[j]}", mapped="$field", value="$value"');
            switch (field) {
              case 'stock':
                product[field] = int.tryParse(value?.toString() ?? '') ?? 0;
                break;
              case 'importPrice':
              case 'salePrice':
                product[field] = double.tryParse(value?.toString() ?? '') ?? 0.0;
                break;
              case 'isActive':
                product[field] = (value?.toString().toLowerCase() ?? '') == 'còn bán';
                break;
              case 'tags':
                product[field] = (value?.toString() ?? '').split(',').map((e) => e.trim()).toList();
                break;
              default:
                product[field] = value?.toString() ?? '';
            }
          }
          // Thêm các trường mặc định nếu chưa có
          product['commonName'] ??= product['name'];
          product['importPrice'] ??= 0.0;
          product['salePrice'] ??= 0.0;
          product['isActive'] ??= true;
          product['createdAt'] = FieldValue.serverTimestamp();
          product['updatedAt'] = FieldValue.serverTimestamp();
          // Kiểm tra dữ liệu bắt buộc
          bool valid = true;
          for (final field in ['name', 'category', 'unit', 'stock']) {
            if (product[field] == null || product[field].toString().isEmpty) {
              print('Bỏ qua dòng $i: Thiếu trường bắt buộc $field');
              valid = false;
            }
          }
          if (!valid) continue;
          print('Created product (row $i): $product');
          products.add(product);
        }
      }

      if (products.isEmpty) {
        throw Exception('Không có sản phẩm nào được tìm thấy trong file');
      }

      print('Total products to import: ${products.length}');

      // Import vào Firestore
      final batch = FirebaseFirestore.instance.batch();
      for (var product in products) {
        final docRef = FirebaseFirestore.instance.collection('products').doc();
        batch.set(docRef, product);
      }

      await batch.commit();
      if (mounted) {
        OverlayEntry? entry;
        entry = OverlayEntry(
          builder: (_) => DesignSystemSnackbar(
            message: 'Đã import ${products.length} sản phẩm thành công',
            icon: Icons.check_circle,
            onDismissed: () => entry?.remove(),
          ),
        );
        Overlay.of(context).insert(entry);
      }
    } catch (e) {
      print('Import error: $e');
      if (mounted) {
        OverlayEntry? entry;
        entry = OverlayEntry(
          builder: (_) => DesignSystemSnackbar(
            message: 'Lỗi khi import: $e',
            icon: Icons.error,
            onDismissed: () => entry?.remove(),
          ),
        );
        Overlay.of(context).insert(entry);
      }
    }
  }

  Future<void> _exportProductsToExcel(List<Product> products) async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // Header tiếng Việt
    final headers = [
      'Tên danh pháp',
      'Tên thường gọi',
      'Danh mục sản phẩm',
      'Mã vạch',
      'SKU',
      'Đơn vị tính',
      'Tags',
      'Mô tả',
      'Công dụng',
      'Thành phần',
      'Ghi chú',
      'Số lượng sản phẩm',
      'Giá nhập',
      'Giá bán',
      'Trạng thái',
      'Ngày tạo',
      'Ngày cập nhật',
    ];
    sheet.appendRow(headers);
    for (final p in products) {
      sheet.appendRow([
        p.name,
        p.commonName,
        p.category,
        p.barcode ?? '',
        p.sku ?? '',
        p.unit,
        p.tags.join(', '),
        p.description,
        p.usage,
        p.ingredients,
        p.notes,
        p.stock,
        p.importPrice,
        p.salePrice,
        p.isActive ? 'Còn bán' : 'Ngừng bán',
        p.createdAt.toString(),
        p.updatedAt.toString(),
      ]);
    }
    final fileBytes = excel.encode()!;
    final fileName = 'products_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    if (mounted) {
      OverlayEntry? entry;
      entry = OverlayEntry(
        builder: (_) => DesignSystemSnackbar(
          message: 'Đã xuất file Excel thành công!',
          icon: Icons.check_circle,
          onDismissed: () => entry?.remove(),
        ),
      );
      Overlay.of(context).insert(entry);
    }
  }

  void updateFilterRanges(List<Product> products) {
    if (products.isNotEmpty) {
      int newMinStock = products.map((p) => p.stock).reduce((a, b) => a < b ? a : b);
      int newMaxStock = products.map((p) => p.stock).reduce((a, b) => a > b ? a : b);
      double newMinPrice = products.map((p) => p.salePrice).reduce((a, b) => a < b ? a : b);
      double newMaxPrice = products.map((p) => p.salePrice).reduce((a, b) => a > b ? a : b);

      // Chỉ setState nếu giá trị thực sự thay đổi
      if (newMinStock != minStock || newMaxStock != maxStock ||
          newMinPrice != minPrice || newMaxPrice != maxPrice) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            minStock = newMinStock;
            maxStock = newMaxStock;
            minPrice = newMinPrice;
            maxPrice = newMaxPrice;
            stockRange = RangeValues(minStock.toDouble(), maxStock.toDouble());
            priceRange = RangeValues(minPrice, maxPrice);
          });
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Reset filter về mặc định mỗi lần vào màn hình
    selectedCategory = 'Tất cả';
    status = 'Tất cả';
    selectedTags = {};
    priceRange = const RangeValues(0, 1000000);
    stockRange = const RangeValues(0, 99999);
    searchText = '';
  }

  Future<void> _showImportDialog() async {
    setState(() {
      _importFile = null;
      _overwrite = false;
      _csvPreviewRows = null;
      _csvPreviewHeaders = null;
    });
    await showDesignSystemDialog(
      context: context,
      title: 'Nhập sản phẩm bằng CSV',
      maxWidth: MediaQuery.of(context).size.width * 0.6,
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          PlatformFile? localImportFile = _importFile;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'xlsx']);
                      if (result != null && result.files.isNotEmpty) {
                        setDialogState(() {
                          localImportFile = result.files.first;
                        });
                        setState(() {
                          _importFile = result.files.first;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: primaryBlue,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Choose File', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(localImportFile?.name ?? 'No file chosen', style: TextStyle(color: textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (localImportFile != null) ...[
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _overwrite,
                  onChanged: (v) {
                    setDialogState(() => _overwrite = v ?? false);
                    setState(() => _overwrite = v ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Ghi đè sản phẩm có Tên khoa học trùng khớp. Các giá trị hiện tại sẽ được thay thế cho tất cả các cột có trong CSV.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        html.AnchorElement(href: '/templates/sample_products_import_template.xlsx')
                          ..setAttribute('download', 'sample_products_import_template.xlsx')
                          ..click();
                      },
                      child: Text('Tải CSV mẫu', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w500, decoration: TextDecoration.underline)),
                    ),
                    const SizedBox(width: 16),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: ghostBorderButtonStyle,
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: localImportFile != null
                          ? () async {
                              final file = localImportFile!;
                              List<List<dynamic>> rows = [];
                              if (file.extension == 'csv') {
                                final content = String.fromCharCodes(file.bytes!);
                                rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(content);
                              } else if (file.extension == 'xlsx') {
                                final excel = ex.Excel.decodeBytes(file.bytes!);
                                final sheet = excel.tables[excel.tables.keys.first];
                                if (sheet != null) {
                                  rows = sheet.rows.map((r) => r.map((c) => c?.value?.toString() ?? '').toList()).toList();
                                }
                              }
                              if (rows.isEmpty) return;
                              setState(() {
                                _csvPreviewHeaders = rows.first.map((e) => e.toString()).toList();
                                _csvPreviewRows = rows.skip(1).map((r) => r.map((e) => e.toString()).toList()).toList();
                              });
                              Navigator.pop(context);
                              _showPreviewDialog();
                            }
                          : null,
                      style: primaryButtonStyle,
                      child: const Text('Tải lên và xem trước'),
                    ),    
                  ],
                ),
              ],
              if (localImportFile == null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        html.AnchorElement(href: '/templates/sample_products_import_template.xlsx')
                          ..setAttribute('download', 'sample_products_import_template.xlsx')
                          ..click();
                      },
                      child: Text('Tải CSV mẫu', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w500, decoration: TextDecoration.underline)),
                    ),
                    const SizedBox(width: 16),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: ghostBorderButtonStyle,
                      child: const Text('Hủy'),
                    ),
                                        
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: null,
                      style: primaryButtonStyle,
                      child: const Text('Tải lên và xem trước'),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
      actions: const [], // Remove actions, all actions are in content
    );
  }

  Future<void> _showPreviewDialog() async {
    if (_csvPreviewHeaders == null || _csvPreviewRows == null) return;

    // Lọc và sắp xếp lại các cột cần hiển thị
    final requiredHeaders = ['Tên pháp danh', 'Tên thường gọi', 'Mã vạch', 'SKU', 'Giá nhập', 'Giá bán', 'Tồn kho'];
    final headerIndices = <int>[];
    
    for (var header in requiredHeaders) {
      final index = _csvPreviewHeaders!.indexWhere((h) => h.toLowerCase() == header.toLowerCase());
      if (index != -1) {
        headerIndices.add(index);
      }
    }

    // Tạo dữ liệu hiển thị mới
    final displayHeaders = headerIndices.map((i) => _csvPreviewHeaders![i]).toList();
    final displayRows = _csvPreviewRows!.map((row) => 
      headerIndices.map((i) => row[i]).toList()
    ).toList();

    await showDesignSystemDialog(
      context: context,
      title: 'Xem trước dữ liệu nhập',
      maxWidth: MediaQuery.of(context).size.width * 0.7,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Xem trước dữ liệu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: displayHeaders.map((h) => DataColumn(
                  label: Container(
                    constraints: const BoxConstraints(minWidth: 120),
                    child: Text(h, 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )).toList(),
                rows: displayRows.map((row) => DataRow(
                  cells: row.map((cell) => DataCell(
                    Container(
                      constraints: const BoxConstraints(minWidth: 120),
                      child: Text(cell.toString(), 
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )).toList(),
                )).toList(),
                headingRowHeight: 48,
                dataRowHeight: 48,
                horizontalMargin: 16,
                columnSpacing: 24,
                dividerThickness: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: ghostBorderButtonStyle,
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            await _importProductsFromCsv();
            Navigator.pop(context);
          },
          style: primaryButtonStyle,
          child: const Text('Nhập sản phẩm'),
        ),
      ],
    );
  }

  Future<void> _importProductsFromCsv() async {
    if (_csvPreviewHeaders == null || _csvPreviewRows == null) return;
    final headers = _csvPreviewHeaders!;
    final rows = _csvPreviewRows!;

    // Map header tiếng Việt sang field tiếng Anh
    final headerMap = <int, String>{};
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].trim().toLowerCase();
      switch (header) {
        case 'tên pháp danh':
        case 'tên danh pháp':
          headerMap[i] = 'name';
          break;
        case 'tên thường gọi':
          headerMap[i] = 'commonName';
          break;
        case 'mã vạch':
          headerMap[i] = 'barcode';
          break;
        case 'sku':
          headerMap[i] = 'sku';
          break;
        case 'giá nhập':
          headerMap[i] = 'importPrice';
          break;
        case 'giá bán':
          headerMap[i] = 'salePrice';
          break;
        case 'tồn kho':
        case 'số lượng sản phẩm':
          headerMap[i] = 'stock';
          break;
        case 'danh mục':
        case 'danh mục sản phẩm':
          headerMap[i] = 'category';
          break;
        case 'đơn vị':
        case 'đơn vị tính':
          headerMap[i] = 'unit';
          break;
        case 'tags':
          headerMap[i] = 'tags';
          break;
        case 'mô tả':
          headerMap[i] = 'description';
          break;
        case 'công dụng':
          headerMap[i] = 'usage';
          break;
        case 'thành phần':
          headerMap[i] = 'ingredients';
          break;
        case 'ghi chú':
          headerMap[i] = 'notes';
          break;
        case 'trạng thái':
          headerMap[i] = 'isActive';
          break;
      }
    }

    int imported = 0;
    int updated = 0;
    int failed = 0;
    List<String> errorRows = [];

    // Tạo danh sách các thao tác (set/update)
    List<Future<void>> batchTasks = [];
    List<WriteBatch> batches = [];
    WriteBatch currentBatch = FirebaseFirestore.instance.batch();
    int batchCount = 0;
    const int maxBatch = 400;

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      try {
        final data = <String, dynamic>{};
        for (int i = 0; i < row.length; i++) {
          if (headerMap.containsKey(i)) {
            final field = headerMap[i]!;
            final value = row[i].toString().trim();
            switch (field) {
              case 'name':
              case 'commonName':
              case 'barcode':
              case 'sku':
              case 'category':
              case 'unit':
              case 'description':
              case 'usage':
              case 'ingredients':
              case 'notes':
                data[field] = value;
                break;
              case 'importPrice':
              case 'salePrice':
                final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
                data[field] = double.tryParse(cleanValue) ?? 0.0;
                break;
              case 'stock':
                final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                data[field] = int.tryParse(cleanValue) ?? 0;
                break;
              case 'tags':
                data[field] = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                break;
              case 'isActive':
                data[field] = value.toLowerCase() == 'còn bán' || 
                             value.toLowerCase() == 'true' || 
                             value == '1' ||
                             value.toLowerCase() == 'đang bán';
                break;
            }
          }
        }
        if (data['name'] == null || data['name'].toString().isEmpty) {
          failed++;
          errorRows.add('Dòng ${rowIndex + 2}: Thiếu tên sản phẩm');
          continue;
        }
        data['commonName'] ??= data['name'];
        data['importPrice'] ??= 0.0;
        data['salePrice'] ??= 0.0;
        data['stock'] ??= 0;
        data['isActive'] ??= true;
        data['tags'] ??= <String>[];
        data['description'] ??= '';
        data['usage'] ??= '';
        data['ingredients'] ??= '';
        data['notes'] ??= '';
        data['createdAt'] = FieldValue.serverTimestamp();
        data['updatedAt'] = FieldValue.serverTimestamp();

        if (_overwrite) {
          // Tìm sản phẩm theo tên khoa học
          final query = await FirebaseFirestore.instance
              .collection('products')
              .where('name', isEqualTo: data['name'])
              .get();
          if (query.docs.isNotEmpty) {
            currentBatch.update(query.docs.first.reference, data);
            updated++;
          } else {
            final docRef = FirebaseFirestore.instance.collection('products').doc();
            currentBatch.set(docRef, data);
            imported++;
          }
        } else {
          final docRef = FirebaseFirestore.instance.collection('products').doc();
          currentBatch.set(docRef, data);
          imported++;
        }
        batchCount++;
        if (batchCount >= maxBatch) {
          batches.add(currentBatch);
          currentBatch = FirebaseFirestore.instance.batch();
          batchCount = 0;
        }
      } catch (e) {
        failed++;
        errorRows.add('Dòng ${rowIndex + 2}: $e');
      }
    }
    if (batchCount > 0) {
      batches.add(currentBatch);
    }
    try {
      for (final batch in batches) {
        await batch.commit();
      }
      if (mounted) {
        OverlayEntry? entry;
        entry = OverlayEntry(
          builder: (_) => DesignSystemSnackbar(
            message: 'Đã nhập $imported, cập nhật $updated, lỗi $failed sản phẩm!',
            icon: Icons.check_circle,
            onDismissed: () => entry?.remove(),
          ),
        );
        Overlay.of(context).insert(entry);
        setState(() {}); // reload UI
      }
    } catch (e) {
      if (mounted) {
        OverlayEntry? entry;
        entry = OverlayEntry(
          builder: (_) => DesignSystemSnackbar(
            message: 'Lỗi khi import: $e',
            icon: Icons.error,
            onDismissed: () => entry?.remove(),
          ),
        );
        Overlay.of(context).insert(entry);
      }
      return;
    }
    if (errorRows.isNotEmpty && mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Một số dòng bị lỗi'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: errorRows.map((e) => Text(e)).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###', 'vi_VN');
    final isMobile = MediaQuery.of(context).size.width < 1024;
    return Scaffold(
      backgroundColor: appBackground,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Danh sách sản phẩm', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => widget.onNavigate?.call(MainPage.addProduct),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm sản phẩm'),
                          style: primaryButtonStyle,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Danh sách sản phẩm', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: ElevatedButton.icon(
                              onPressed: _showImportDialog,
                              icon: const Icon(Icons.file_upload_outlined),
                              label: const Text('Import'),
                              style: ghostBorderButtonStyle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final products = await _productService.getProducts().first;
                                await _exportProductsToExcel(products);
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Export'),
                              style: ghostBorderButtonStyle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onNavigate?.call(MainPage.addProduct),
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm sản phẩm'),
                              style: primaryButtonStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          // Search and Filter Section
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: searchInputDecoration(
                            hint: 'Tìm theo tên, mã vạch...',
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (v) => setState(() => searchText = v),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: () {
                              // TODO: Implement QR scan logic
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Icon(
                                Icons.qr_code_scanner,
                                size: 24,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Product List and Filter/Sort Row together in StreamBuilder
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 80.0),
                    child: StreamBuilder<List<Product>>(
                      stream: _productService.getProducts(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Lỗi: ${snapshot.error}'));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final products = snapshot.data ?? [];
                        final filteredProducts = filterProducts(products);
                        final sortedProducts = sortProducts(filteredProducts);
                        final isMobile = MediaQuery.of(context).size.width < 600;
                        return Column(
                          children: [
                            // Filter and Sort Row
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 0.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: isMobile ? 160 : 200,
                                    child: ShopifyDropdown<String>(
                                      items: sortOptions.map((o) => o['key'] as String).toList(),
                                      value: sortOption,
                                      getLabel: (key) => sortOptions.firstWhere((o) => o['key'] == key)['label'],
                                      onChanged: (val) => setState(() => sortOption = val ?? sortOption),
                                      hint: 'Tên: A - Z',
                                    ),
                                  ),
                                  const Spacer(),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() => isFilterOpen = !isFilterOpen);
                                    },
                                    icon: const Icon(Icons.filter_alt_outlined),
                                    label: const Text('Bộ lọc'),
                                    style: secondaryButtonStyle,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${filteredProducts.length} sản phẩm',
                                    style: const TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            // Product List
                            if (sortedProducts.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32.0),
                                child: Center(
                                  child: Text(
                                    'Không tìm thấy sản phẩm nào',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                  ),
                                ),
                              )
                            else
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isMobile = constraints.maxWidth < 600;
                                  if (isMobile) {
                                    // Mobile card style
                                    return Column(
                                      children: [
                                        ...sortedProducts.map((product) {
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.04),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                                if (product.commonName.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2),
                                                    child: Text(product.commonName, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w400)),
                                                  ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('Mã vạch', style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w500)),
                                                          Text(product.barcode ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                                        ],
                                                      ),
                                                    ),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text('Số lượng', style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w500)),
                                                        Text('${product.stock}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ], 
                                    );
                                  } else {
                                    // Desktop/tablet: render dạng bảng
                                    return Column(
                                      children: [
                                        // Header row
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12, right: 8),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: ValueListenableBuilder<Set<String>>(
                                              valueListenable: selectedProductIds,
                                              builder: (context, selected, _) {
                                                return ElevatedButton.icon(
                                                  icon: const Icon(Icons.delete),
                                                  label: const Text('Xóa các sản phẩm đã chọn'),
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                                  onPressed: selected.isEmpty ? null : () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text('Xóa sản phẩm'),
                                                        content: Text('Bạn có chắc muốn xóa ${selected.length} sản phẩm đã chọn?'),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      final batch = FirebaseFirestore.instance.batch();
                                                      int count = 0;
                                                      for (final id in selected) {
                                                        final ref = FirebaseFirestore.instance.collection('products').doc(id);
                                                        batch.delete(ref);
                                                        count++;
                                                        if (count == 490) {
                                                          await batch.commit();
                                                          count = 0;
                                                        }
                                                      }
                                                      if (count > 0) {
                                                        await batch.commit();
                                                      }
                                                      selectedProductIds.value = {};
                                                      OverlayEntry? entry;
                                                      entry = OverlayEntry(
                                                        builder: (_) => DesignSystemSnackbar(
                                                          message: 'Đã xóa các sản phẩm đã chọn!',
                                                          icon: Icons.check_circle,
                                                          onDismissed: () => entry?.remove(),
                                                        ),
                                                      );
                                                      Overlay.of(context).insert(entry);
                                                      await Future.delayed(const Duration(milliseconds: 500));
                                                      setState(() {});
                                                    }
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                            ),
                                            border: Border(
                                              bottom: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 1,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: SizedBox(
                                                    width: 32,
                                                    height: 32,
                                                    child: Theme(
                                                      data: Theme.of(context).copyWith(
                                                        unselectedWidgetColor: Color(0xFF3a6ff8),
                                                        checkboxTheme: CheckboxThemeData(
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          side: const BorderSide(color: Color(0xFF3a6ff8), width: 1),
                                                          fillColor: MaterialStateProperty.resolveWith<Color?>((states) {
                                                            if (states.contains(MaterialState.selected)) {
                                                              return Color(0xFF3a6ff8);
                                                            }
                                                            return Colors.white;
                                                          }),
                                                          checkColor: MaterialStateProperty.all<Color>(Colors.white),
                                                        ),
                                                      ),
                                                      child: ValueListenableBuilder<Set<String>>(
                                                        valueListenable: selectedProductIds,
                                                        builder: (context, selected, _) {
                                                          return Checkbox(
                                                            value: selected.length == sortedProducts.length && sortedProducts.isNotEmpty,
                                                            onChanged: (checked) {
                                                              if (checked == true) {
                                                                selectedProductIds.value = Set<String>.from(sortedProducts.map((p) => p.id));
                                                              } else {
                                                                selectedProductIds.value = {};
                                                              }
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 5,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textSecondary)),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: Text('Mã vạch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textSecondary)),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: Text('Số lượng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textSecondary)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Product rows
                                        ...sortedProducts.asMap().entries.map((entry) {
                                          final idx = entry.key;
                                          final product = entry.value;
                                          final isLast = idx == sortedProducts.length - 1;
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 0),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: isLast
                                                ? const BorderRadius.only(
                                                    bottomLeft: Radius.circular(12),
                                                    bottomRight: Radius.circular(12),
                                                  )
                                                : BorderRadius.zero,
                                              border: isLast
                                                ? null
                                                : Border(
                                                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                                                  ),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: SizedBox(
                                                      width: 32,
                                                      height: 32,
                                                      child: Theme(
                                                        data: Theme.of(context).copyWith(
                                                          unselectedWidgetColor: Color(0xFF3a6ff8),
                                                          checkboxTheme: CheckboxThemeData(
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            side: const BorderSide(color: Color(0xFF3a6ff8), width: 1),
                                                            fillColor: MaterialStateProperty.resolveWith<Color?>((states) {
                                                              if (states.contains(MaterialState.selected)) {
                                                                return Color(0xFF3a6ff8);
                                                              }
                                                              return Colors.white;
                                                            }),
                                                            checkColor: MaterialStateProperty.all<Color>(Colors.white),
                                                          ),
                                                        ),
                                                        child: ValueListenableBuilder<Set<String>>(
                                                          valueListenable: selectedProductIds,
                                                          builder: (context, selected, _) {
                                                            return Checkbox(
                                                              value: selected.contains(product.id),
                                                              onChanged: (checked) {
                                                                final newSet = Set<String>.from(selected);
                                                                if (checked == true) {
                                                                  newSet.add(product.id);
                                                                } else {
                                                                  newSet.remove(product.id);
                                                                }
                                                                selectedProductIds.value = newSet;
                                                              },
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 5,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                        if (product.commonName.isNotEmpty)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 2),
                                                            child: Text(product.commonName, style: TextStyle(fontSize: 14, color: textThird , fontWeight: FontWeight.w400)),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(product.barcode ?? '-', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text('${product.stock}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  }
                                },
                              ),
                          ],
                        );
                      },
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

  @override
  void dispose() {
    selectedProductIds.dispose();
    super.dispose();
  }
}

// Thêm class custom thumb shape cho slider
class _CustomBlueThumbShape extends RoundSliderThumbShape {
  const _CustomBlueThumbShape({double enabledThumbRadius = 10.0, double disabledThumbRadius = 10.0})
      : super(enabledThumbRadius: enabledThumbRadius, disabledThumbRadius: disabledThumbRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter? labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
    bool isEnabled = false,
    bool isOnTop = false,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;
    final double radius = isEnabled ? (enabledThumbRadius ?? 10.0) : (disabledThumbRadius ?? 10.0);
    final Paint fillPaint = Paint()..color = sliderTheme.thumbColor ?? Colors.white;
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF3a6ff8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);
  }
}