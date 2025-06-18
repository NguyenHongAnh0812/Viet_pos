import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'package:intl/intl.dart' show NumberFormat;
import '../widgets/main_layout.dart';
import 'products/product_detail_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:math' show min;
import 'dart:html' as html;
import '../widgets/product_card_item.dart';
import '../widgets/product_list_card.dart';
import '../widgets/common/design_system.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

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
    required ui.TextDirection textDirection,
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
  final VoidCallback? onOpenFilterSidebar;
  final String? filterCategory;
  final RangeValues? filterPriceRange;
  final RangeValues? filterStockRange;
  final String? filterStatus;
  final Set<String>? filterTags;
  final bool isLoadingProducts;
  final VoidCallback? onReloadProducts;
  const ProductListScreen({
    super.key,
    this.onProductTap,
    this.onNavigate,
    this.onOpenFilterSidebar,
    this.filterCategory,
    this.filterPriceRange,
    this.filterStockRange,
    this.filterStatus,
    this.filterTags,
    this.isLoadingProducts = false,
    this.onReloadProducts,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String get selectedCategory => widget.filterCategory ?? 'Tất cả';
  RangeValues get priceRange => widget.filterPriceRange ?? const RangeValues(0, 0);
  RangeValues get stockRange => widget.filterStockRange ?? const RangeValues(0, 0);
  String get status => widget.filterStatus ?? 'Tất cả';
  Set<String> get selectedTags => widget.filterTags ?? {};
  String searchText = '';
  bool isFilterSidebarOpen = false;
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

  // Infinite scroll state
  final int itemsPerPage = 30;
  int currentPage = 1;
  bool isLoadingMore = false;

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
    final set = products.map((p) => p.categoryId).where((c) => c != null && c.isNotEmpty).toSet();
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
      if (selectedCategory != 'Tất cả' && p.categoryId != selectedCategory) {
        return false;
      }
      
      // Price filter
      if (p.salePrice < priceRange.start || p.salePrice > priceRange.end) {
        return false;
      }
      
      // Stock filter - Only apply if stock range is not default
      if (stockRange.start > 0 || stockRange.end < 99999) {
        if (p.stockSystem < stockRange.start || p.stockSystem > stockRange.end) {
          return false;
        }
      }
    
      
      // Tags filter - Only apply if tags are selected
      if (selectedTags.isNotEmpty) {
        if (!selectedTags.any((tag) => p.tags.contains(tag))) {
          return false;
        }
      }
      
      // Search text filter - Only apply if search text is not empty
      if (searchText.isNotEmpty) {
        final searchLower = searchText.toLowerCase();
        // Tìm theo tên nội bộ, tên thương mại và mã vạch
        if (!p.internalName.toLowerCase().contains(searchLower) && 
            !p.tradeName.toLowerCase().contains(searchLower) &&
            !(p.barcode != null && p.barcode!.toLowerCase().contains(searchLower))) {
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
        products.sort((a, b) => a.internalName.toLowerCase().compareTo(b.internalName.toLowerCase()));
        break;
      case 'name_desc':
        products.sort((a, b) => b.internalName.toLowerCase().compareTo(a.internalName.toLowerCase()));
        break;
      case 'price_asc':
        products.sort((a, b) => a.salePrice.compareTo(b.salePrice));
        break;
      case 'price_desc':
        products.sort((a, b) => b.salePrice.compareTo(a.salePrice));
        break;
      case 'stock_asc':
        products.sort((a, b) => a.stockSystem.compareTo(b.stockSystem));
        break;
      case 'stock_desc':
        products.sort((a, b) => b.stockSystem.compareTo(a.stockSystem));
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
          'tên nội bộ': 'internalName',
          'tên thương mại': 'tradeName',
          'danh mục sản phẩm': 'categoryId',
          'mã vạch': 'barcode',
          'sku': 'sku',
          'đơn vị tính': 'unit',
          'tags': 'tags',
          'mô tả': 'description',
          'công dụng': 'usage',
          'thành phần': 'ingredients',
          'ghi chú': 'notes',
          'số lượng sản phẩm': 'stockSystem',
          'giá nhập': 'costPrice',
          'giá bán': 'salePrice',
          'trạng thái': 'status'
        };

        // Chuyển đổi header sang tiếng Anh
        final processedHeaders = headers.map((h) => headerMapping[h] ?? h).toList();
        print('Processed headers: \\${processedHeaders}');

        // Kiểm tra các trường bắt buộc
        final requiredFields = ['internalName', 'categoryId', 'unit', 'stockSystem'];
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
                case 'stockSystem':
                  product[field] = int.tryParse(value) ?? 0;
                  break;
                case 'costPrice':
                case 'salePrice':
                  product[field] = double.tryParse(value) ?? 0.0;
                  break;
                case 'status':
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
          product['tradeName'] ??= product['internalName'];
          product['costPrice'] ??= 0.0;
          product['salePrice'] ??= 0.0;
          product['status'] ??= true;
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
        final excelFile = excel.Excel.decodeBytes(bytes);
        final sheet = excelFile.tables[excelFile.tables.keys.first];
        if (sheet == null) throw 'Sheet không hợp lệ';
        
        final headers = sheet.rows.first.map((cell) => cell?.value.toString().trim().toLowerCase() ?? '').toList();
        print('Excel headers (gốc): $headers');
        // Mapping header tiếng Việt sang tên trường tiếng Anh
        final headerMapping = {
          'tên nội bộ': 'internalName',
          'tên thương mại': 'tradeName',
          'danh mục sản phẩm': 'categoryId',
          'mã vạch': 'barcode',
          'sku': 'sku',
          'đơn vị tính': 'unit',
          'tags': 'tags',
          'mô tả': 'description',
          'công dụng': 'usage',
          'thành phần': 'ingredients',
          'ghi chú': 'notes',
          'số lượng sản phẩm': 'stockSystem',
          'giá nhập': 'costPrice',
          'giá bán': 'salePrice',
          'trạng thái': 'status'
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
              case 'stockSystem':
                product[field] = int.tryParse(value?.toString() ?? '') ?? 0;
                break;
              case 'costPrice':
              case 'salePrice':
                product[field] = double.tryParse(value?.toString() ?? '') ?? 0.0;
                break;
              case 'status':
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
          product['tradeName'] ??= product['internalName'];
          product['costPrice'] ??= 0.0;
          product['salePrice'] ??= 0.0;
          product['status'] ??= true;
          product['createdAt'] = FieldValue.serverTimestamp();
          product['updatedAt'] = FieldValue.serverTimestamp();
          // Kiểm tra dữ liệu bắt buộc
          bool valid = true;
          for (final field in ['internalName', 'categoryId', 'unit', 'stockSystem']) {
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
    final excelFile = excel.Excel.createExcel();
    final sheet = excelFile['Sheet1'];
    // Header tiếng Việt
    final headers = [
      'Tên nội bộ',
      'Tên thương mại',
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
    sheet.appendRow(headers.map((h) => excel.TextCellValue(h)).toList());
    for (final p in products) {
      sheet.appendRow([
        excel.TextCellValue(p.internalName),
        excel.TextCellValue(p.tradeName),
        excel.TextCellValue(p.categoryId),
        excel.TextCellValue(p.barcode ?? ''),
        excel.TextCellValue(p.sku ?? ''),
        excel.TextCellValue(p.unit),
        excel.TextCellValue(p.tags.join(', ')),
        excel.TextCellValue(p.description),
        excel.TextCellValue(p.usage),
        excel.TextCellValue(p.ingredients),
        excel.TextCellValue(p.notes),
        excel.IntCellValue(p.stockSystem),
        excel.DoubleCellValue(p.costPrice),
        excel.DoubleCellValue(p.salePrice),
        
        excel.TextCellValue(p.createdAt.toString()),
        excel.TextCellValue(p.updatedAt.toString()),
      ]);
    }
    final fileBytes = excelFile.encode()!;
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
      int newMinStock = products.map((p) => p.stockSystem).reduce((a, b) => a < b ? a : b);
      int newMaxStock = products.map((p) => p.stockSystem).reduce((a, b) => a > b ? a : b);
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
          });
        });
      }
    }
  }

  void checkExtremeProducts(List<Product> products) {
    final stock99999 = products.where((p) => p.stockSystem == 99999).toList();
    final price1000000 = products.where((p) => p.salePrice == 1000000).toList();
    print('--- Sản phẩm có tồn kho = 99999 ---');
    for (final p in stock99999) {
      print('ID: \\${p.id}, Tên: \\${p.internalName}, Tồn kho: \\${p.stockSystem}');
    }
    print('--- Sản phẩm có giá bán = 1,000,000 ---');
    for (final p in price1000000) {
      print('ID: \\${p.id}, Tên: \\${p.internalName}, Giá bán: \\${p.salePrice}');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('\n=== DEBUG: Building ProductListScreen ===');
    
    final isMobile = MediaQuery.of(context).size.width < 600;
    final numberFormat = NumberFormat('#,###', 'vi_VN');
    
    return Scaffold(
      backgroundColor: appBackground,
      body: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Danh sách sản phẩm',
                            style: MediaQuery.of(context).size.width < 600 ? h1Mobile : h2,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => widget.onNavigate?.call(MainPage.addProduct),
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm sản phẩm'),
                                style: primaryButtonStyle,
                              ),
                              const SizedBox(width: 8),
                              ValueListenableBuilder<Set<String>>(
                                valueListenable: selectedProductIds,
                                builder: (context, selected, _) {
                                  if (selected.isEmpty) return const SizedBox.shrink();
                                  return Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Xác nhận xóa'),
                                              content: Text('Bạn có chắc chắn muốn xóa ${selected.length} sản phẩm đã chọn?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Hủy'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            try {
                                              final batch = FirebaseFirestore.instance.batch();
                                              for (final id in selected) {
                                                final docRef = FirebaseFirestore.instance.collection('products').doc(id);
                                                batch.delete(docRef);
                                              }
                                              await batch.commit();
                                              selectedProductIds.value = {};
                                              if (mounted) {
                                                OverlayEntry? entry;
                                                entry = OverlayEntry(
                                                  builder: (_) => DesignSystemSnackbar(
                                                    message: 'Đã xóa ${selected.length} sản phẩm thành công',
                                                    icon: Icons.check_circle,
                                                    onDismissed: () => entry?.remove(),
                                                  ),
                                                );
                                                Overlay.of(context).insert(entry);
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                OverlayEntry? entry;
                                                entry = OverlayEntry(
                                                  builder: (_) => DesignSystemSnackbar(
                                                    message: 'Lỗi khi xóa sản phẩm: $e',
                                                    icon: Icons.error,
                                                    onDismissed: () => entry?.remove(),
                                                  ),
                                                );
                                                Overlay.of(context).insert(entry);
                                              }
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        label: Text('Xóa ${selected.length} sản phẩm', style: const TextStyle(color: Colors.red)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _importProductsFromExcel,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Import'),
                                style: secondaryButtonStyle,
                              ),
                              const SizedBox(width: 8),
                              StreamBuilder<List<Product>>(
                                stream: _productService.getProducts(),
                                builder: (context, snapshot) {
                                  final products = snapshot.data ?? [];
                                  return OutlinedButton.icon(
                                    onPressed: () => _exportProductsToExcel(products),
                                    icon: const Icon(Icons.download),
                                    label: const Text('Export'),
                                    style: secondaryButtonStyle,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => widget.onNavigate?.call(MainPage.addProduct),
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm sản phẩm'),
                                style: primaryButtonStyle,
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Danh sách sản phẩm',
                            style: h2,
                          ),
                          Row(
                            children: [
                              ValueListenableBuilder<Set<String>>(
                                valueListenable: selectedProductIds,
                                builder: (context, selected, _) {
                                  if (selected.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Xác nhận xóa'),
                                            content: Text('Bạn có chắc chắn muốn xóa ${selected.length} sản phẩm đã chọn?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Hủy'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          try {
                                            final batch = FirebaseFirestore.instance.batch();
                                            for (final id in selected) {
                                              final docRef = FirebaseFirestore.instance.collection('products').doc(id);
                                              batch.delete(docRef);
                                            }
                                            await batch.commit();
                                            selectedProductIds.value = {};
                                            if (mounted) {
                                              OverlayEntry? entry;
                                              entry = OverlayEntry(
                                                builder: (_) => DesignSystemSnackbar(
                                                  message: 'Đã xóa ${selected.length} sản phẩm thành công',
                                                  icon: Icons.check_circle,
                                                  onDismissed: () => entry?.remove(),
                                                ),
                                              );
                                              Overlay.of(context).insert(entry);
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              OverlayEntry? entry;
                                              entry = OverlayEntry(
                                                builder: (_) => DesignSystemSnackbar(
                                                  message: 'Lỗi khi xóa sản phẩm: $e',
                                                  icon: Icons.error,
                                                  onDismissed: () => entry?.remove(),
                                                ),
                                              );
                                              Overlay.of(context).insert(entry);
                                            }
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      label: Text('Xóa ${selected.length} sản phẩm', style: const TextStyle(color: Colors.red)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              OutlinedButton.icon(
                                onPressed: _importProductsFromExcel,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Import'),
                                style: secondaryButtonStyle,
                              ),
                              const SizedBox(width: 8),
                              StreamBuilder<List<Product>>(
                                stream: _productService.getProducts(),
                                builder: (context, snapshot) {
                                  final products = snapshot.data ?? [];
                                  return OutlinedButton.icon(
                                    onPressed: () => _exportProductsToExcel(products),
                                    icon: const Icon(Icons.download),
                                    label: const Text('Export'),
                                    style: secondaryButtonStyle,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => widget.onNavigate?.call(MainPage.addProduct),
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm sản phẩm'),
                                style: primaryButtonStyle,
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
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
                              return Center(
                                child: Text(
                                  'Có lỗi xảy ra: ${snapshot.error}',
                                  style: TextStyle(color: Colors.red[600]),
                                ),
                              );
                            }

                            if (widget.isLoadingProducts) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final products = snapshot.data ?? [];
                            print('Raw products count: ${products.length}');
                            
                            checkExtremeProducts(products);
                            print('After checking extreme products: ${products.length}');
                            
                            updateFilterRanges(products);
                            final filteredProducts = filterProducts(products);
                            print('After filtering: ${filteredProducts.length}');
                            
                            final sortedProducts = sortProducts(filteredProducts);
                            print('After sorting: ${sortedProducts.length}');
                            
                            final pagedProducts = sortedProducts.take(currentPage * itemsPerPage).toList();
                            print('Final paged products: ${pagedProducts.length}');
                            print('=== End ProductListScreen Build ===\n');

                            if (products.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32.0),
                                child: Center(
                                  child: Text(
                                    'Đang kiểm tra dữ liệu sản phẩm!',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                  ),
                                ),
                              );
                            }

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
                                        onPressed: widget.onOpenFilterSidebar,
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
                                // Product List with infinite scroll
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  child: Column(
                                    children: [
                                      if (!isMobile)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                            ),
                                            border: const Border(
                                              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 1,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: ValueListenableBuilder<Set<String>>(
                                                    valueListenable: selectedProductIds,
                                                    builder: (context, selected, _) {
                                                      return Checkbox(
                                                        value: selected.length == pagedProducts.length,
                                                        onChanged: pagedProducts.isEmpty ? null : (checked) {
                                                          if (checked == true) {
                                                            selectedProductIds.value = Set<String>.from(pagedProducts.map((p) => p.id));
                                                          } else {
                                                            selectedProductIds.value = {};
                                                          }
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Expanded(flex: 3, child: Text('Tên sản phẩm', style: TextStyle(color: textMuted, fontWeight: FontWeight.bold))),
                                              Expanded(flex: 2, child: Text('Giá nhập', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontWeight: FontWeight.bold))),
                                              Expanded(flex: 2, child: Text('Đơn vị', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontWeight: FontWeight.bold))),
                                              Expanded(flex: 2, child: Text('Tồn kho hóa đơn', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontWeight: FontWeight.bold))),
                                              Expanded(flex: 2, child: Text('Tồn kho hệ thống', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontWeight: FontWeight.bold))),
                                            ],
                                          ),
                                        ),
                                      // Danh sách sản phẩm hoặc thông báo trống
                                      if (pagedProducts.isEmpty)
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
                                        SizedBox(
                                          height: MediaQuery.of(context).size.height * 0.6,
                                          child: NotificationListener<ScrollNotification>(
                                            onNotification: (scrollInfo) {
                                              _handleScroll(scrollInfo, sortedProducts.length);
                                              return false;
                                            },
                                            child: ListView.builder(
                                              itemCount: pagedProducts.length + (isLoadingMore ? 1 : 0),
                                              itemBuilder: (context, index) {
                                                if (index == pagedProducts.length) {
                                                  return const Padding(
                                                    padding: EdgeInsets.symmetric(vertical: 16),
                                                    child: Center(child: CircularProgressIndicator()),
                                                  );
                                                }
                                                final product = pagedProducts[index];
                                                final isMobile = MediaQuery.of(context).size.width < 600;

                                                if (isMobile) {
                                                  // Mobile: render dạng card
                                                  return InkWell(
                                                    onTap: () => widget.onProductTap?.call(product),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        border: Border(
                                                          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                                                        ),
                                                      ),
                                                      padding: const EdgeInsets.all(16),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(product.tradeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter')),
                                                          if (product.internalName.isNotEmpty)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 2),
                                                              child: Text(product.internalName, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w400, fontFamily: 'Inter')),
                                                            ),
                                                          const SizedBox(height: 16),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                'Mã vạch: ${product.barcode ?? '-'}',
                                                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                                              ),
                                                              Text(
                                                                'Số lượng: ${product.stockSystem}',
                                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  // Desktop/tablet: render dạng bảng với checkbox chọn nhiều
                                                  return InkWell(
                                                    onTap: () => widget.onProductTap?.call(product),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        border: Border(
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
                                                          Expanded(
                                                            flex: 3,
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(product.tradeName, style: bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                                                                if (product.internalName.isNotEmpty)
                                                                  Text(product.internalName, style: body.copyWith(color: Colors.grey[600])),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: Align(
                                                              alignment: Alignment.center,
                                                              child: Text('${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(product.costPrice)}', style: body),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: Align(
                                                              alignment: Alignment.center,
                                                              child: Text(product.unit, style: body),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: Align(
                                                              alignment: Alignment.center,
                                                              child: Text('${product.stockInvoice}', style: bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: Align(
                                                              alignment: Alignment.center,
                                                              child: Text('${product.stockSystem}', style: bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    selectedProductIds.dispose();
    super.dispose();
  }

  void _handleScroll(ScrollNotification scrollInfo, int totalItems) {
    if (!isLoadingMore && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
      final maxPage = (totalItems / itemsPerPage).ceil();
      if (currentPage < maxPage) {
        setState(() {
          isLoadingMore = true;
          currentPage++;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => isLoadingMore = false);
        });
      }
    }
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
    required ui.TextDirection textDirection,
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