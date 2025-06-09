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
  Set<String> selectedProductIds = {};
  int currentProductCount = 0;

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

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###', 'vi_VN');
    final isMobile = MediaQuery.of(context).size.width < 600;
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
                              onPressed: _importProductsFromExcel,
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
                                                          Text('Mã vạch', style: TextStyle(fontSize: 15, color: Colors.grey[400], fontWeight: FontWeight.w500)),
                                                          Text(product.barcode ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                                        ],
                                                      ),
                                                    ),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text('Số lượng', style: TextStyle(fontSize: 15, color: Colors.grey[400], fontWeight: FontWeight.w500)),
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
                                                      child: Checkbox(
                                                        value: selectedProductIds.length == sortedProducts.length && sortedProducts.isNotEmpty,
                                                        onChanged: (checked) {
                                                          setState(() {
                                                            if (checked == true) {
                                                              selectedProductIds.addAll(sortedProducts.map((p) => p.id));
                                                            } else {
                                                              selectedProductIds.clear();
                                                            }
                                                          });
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
                                                  child: Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textThird)),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: Text('Mã vạch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textThird)),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: Text('Số lượng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textThird)),
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
                                                        child: Checkbox(
                                                          value: selectedProductIds.contains(product.id),
                                                          onChanged: (checked) {
                                                            setState(() {
                                                              if (checked == true) {
                                                                selectedProductIds.add(product.id);
                                                              } else {
                                                                selectedProductIds.remove(product.id);
                                                              }
                                                            });
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
                                        // Bulk delete button
                                        if (selectedProductIds.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 12, right: 8),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton.icon(
                                                icon: const Icon(Icons.delete),
                                                label: const Text('Xóa các sản phẩm đã chọn'),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text('Xóa sản phẩm'),
                                                      content: Text('Bạn có chắc muốn xóa \\${selectedProductIds.length} sản phẩm đã chọn?'),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true) {
                                                    for (final id in selectedProductIds) {
                                                      await _productService.deleteProduct(id);
                                                    }
                                                    OverlayEntry? entry;
                                                    entry = OverlayEntry(
                                                      builder: (_) => DesignSystemSnackbar(
                                                        message: 'Đã xóa các sản phẩm đã chọn!',
                                                        icon: Icons.check_circle,
                                                        onDismissed: () => entry?.remove(),
                                                      ),
                                                    );
                                                    Overlay.of(context).insert(entry);
                                                    setState(() {});
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
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