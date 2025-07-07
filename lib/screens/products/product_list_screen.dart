import 'package:flutter/material.dart';
import 'dart:convert';

import '../../services/product_service.dart';
import '../../widgets/main_layout.dart';
import 'product_detail_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';

import 'dart:math' show min;
// import 'dart:html' as html;
import '../../widgets/product_card_item.dart';
import '../../widgets/product_list_card.dart';

import 'dart:ui' as ui;
import '../../widgets/common/design_system.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';

// Custom thumb shape with blue border
class BlueBorderThumbShape extends RoundSliderThumbShape {
  const BlueBorderThumbShape({
    super.enabledThumbRadius = 9.0,
    double super.disabledThumbRadius = 9.0,
  });

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
      ..color = Colors.white;
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
  final bool _overwrite = false;
  List<List<String>>? _csvPreviewRows;
  List<String>? _csvPreviewHeaders;

  // Infinite scroll state
  final int itemsPerPage = 10;
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
    // TODO: Implement with new category relation service
    // final set = products.expand((p) => p.categoryIds).where((c) => c.isNotEmpty).toSet();
    // final list = set.toList()..sort();
    // return ['Tất cả', ...list];
    return ['Tất cả']; // Tạm thời return empty list
  }

  List<String> get allTags => ['kháng sinh', 'phổ rộng', 'vitamin', 'bổ sung', 'NSAID', 'giảm đau', 'quinolone'];

  List<Product> filterProducts(List<Product> products) {
    return products.where((product) {
      // Tìm kiếm theo tên, mã vạch, SKU
      if (searchText.isNotEmpty) {
        final searchLower = searchText.toLowerCase();
        final matchesSearch = product.internalName.toLowerCase().contains(searchLower) ||
            product.tradeName.toLowerCase().contains(searchLower) ||
            (product.barcode != null && product.barcode!.toLowerCase().contains(searchLower)) ||
            (product.sku != null && product.sku!.toLowerCase().contains(searchLower));
        if (!matchesSearch) return false;
      }

      // Lọc theo danh mục
      if (selectedCategory != 'Tất cả') {
        // TODO: Implement with new category relation service
        // if (!product.categoryIds.contains(selectedCategory)) {
        //   return false;
        // }
        return true; // Tạm thời return true
      }
      
      // Lọc theo khoảng giá
      if (priceRange.start > 0 || priceRange.end < maxPrice) {
        if (product.salePrice < priceRange.start || product.salePrice > priceRange.end) {
          return false;
        }
      }
    
      // Lọc theo khoảng tồn kho
      if (stockRange.start > 0 || stockRange.end < maxStock) {
        if (product.stockSystem < stockRange.start || product.stockSystem > stockRange.end) {
          return false;
        }
      }
      
      // Lọc theo trạng thái
      if (status != 'Tất cả trạng thái') {
        final isActive = product.status;
        switch (status) {
          case 'Còn bán':
            if (isActive == false) return false;
            break;
          case 'Ngừng bán':
            if (isActive == true) return false;
            break;
        }
      }

      // Lọc theo tags
      if (selectedTags.isNotEmpty) {
        final productTags = product.tags.map((tag) => tag.toLowerCase()).toSet();
        final hasMatchingTag = selectedTags.any((tag) => productTags.contains(tag.toLowerCase()));
        if (hasMatchingTag == false) return false;
      }
      
      return true;
    }).toList();
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
      debugPrint('Importing file: ${file.name}');

      List<Map<String, dynamic>> products = [];
      final bytes = file.bytes!;
      final fileName = file.name.toLowerCase();

      if (fileName.endsWith('.csv')) {
        // Xử lý file CSV
        String csvString = utf8.decode(bytes);
        // Chuẩn hóa line break về \n
        csvString = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        debugPrint('CSV content length: \\${csvString.length}');
        debugPrint('CSV content preview: \\${csvString.substring(0, min(200, csvString.length))}');

        final csvTable = const CsvToListConverter().convert(csvString);
        debugPrint('CSV table length: \\${csvTable.length}');

        if (csvTable.isEmpty) {
          throw Exception('File CSV không có dữ liệu');
        }

        // Lấy header và chuyển về chữ thường
        final headers = (csvTable[0]).map((e) => e.toString().trim().toLowerCase()).toList();
        debugPrint('Raw headers: \\$headers');

        // Mapping header tiếng Việt sang tên trường tiếng Anh
        final headerMapping = {
          'tên nội bộ': 'internalName',
          'tên thương mại': 'tradeName',
          'danh mục sản phẩm': 'categoryIds',
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
        debugPrint('Processed headers: \\$processedHeaders');

        // Kiểm tra các trường bắt buộc
        final requiredFields = ['internalName', 'categoryIds', 'unit', 'stockSystem'];
        final missingFields = requiredFields.where((field) => !processedHeaders.contains(field)).toList();
        if (missingFields.isNotEmpty) {
          debugPrint('Thiếu các trường bắt buộc: \\${missingFields.join(", ")}');
          throw Exception('Thiếu các trường bắt buộc: \\${missingFields.join(", ")}');
        }

        // Xử lý từng dòng dữ liệu
        for (var i = 1; i < csvTable.length; i++) {
          final row = csvTable[i];
          debugPrint('Row $i (${row.length} columns): $row');

          if (row.length != headers.length) {
            debugPrint('Bỏ qua dòng $i: Số lượng cột không khớp với header (${row.length} != ${headers.length})');
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
                case 'categoryIds':
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
              debugPrint('Bỏ qua dòng $i: Thiếu trường bắt buộc $field, value: ${product[field]}');
              valid = false;
            }
          }
          if (!valid) {
            debugPrint('Dòng $i bị bỏ qua do thiếu trường bắt buộc. Product: $product');
            continue;
          }

          debugPrint('Created product (row $i): $product');
          products.add(product);
        }
        debugPrint('Tổng số sản phẩm hợp lệ được import: ${products.length}');
      } else {
        // Xử lý file Excel
        final excelFile = excel.Excel.decodeBytes(bytes);
        final sheet = excelFile.tables[excelFile.tables.keys.first];
        if (sheet == null) throw 'Sheet không hợp lệ';
        
        final headers = sheet.rows.first.map((cell) => cell?.value.toString().trim().toLowerCase() ?? '').toList();
        debugPrint('Excel headers (gốc): $headers');
        // Mapping header tiếng Việt sang tên trường tiếng Anh
        final headerMapping = {
          'tên nội bộ': 'internalName',
          'tên thương mại': 'tradeName',
          'danh mục sản phẩm': 'categoryIds',
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
        debugPrint('Processed Excel headers (mapping): $processedHeaders');
        for (var i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          final Map<String, dynamic> product = {};
          for (var j = 0; j < processedHeaders.length; j++) {
            final field = processedHeaders[j];
            if (field.isEmpty) continue;
            final cell = row[j];
            final value = cell?.value;
            debugPrint('Row $i, Col $j: header="${headers[j]}", mapped="$field", value="$value"');
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
              case 'categoryIds':
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
          for (final field in ['internalName', 'categoryIds', 'unit', 'stockSystem']) {
            if (product[field] == null || product[field].toString().isEmpty) {
              debugPrint('Bỏ qua dòng $i: Thiếu trường bắt buộc $field');
              valid = false;
            }
          }
          if (!valid) continue;
          debugPrint('Created product (row $i): $product');
          products.add(product);
        }
      }

      if (products.isEmpty) {
        throw Exception('Không có sản phẩm nào được tìm thấy trong file');
      }

      debugPrint('Total products to import: ${products.length}');

      // Import vào Firestore
      final batch = FirebaseFirestore.instance.batch();
      for (var product in products) {
        final docRef = FirebaseFirestore.instance.collection('products').doc();
        batch.set(docRef, Product.normalizeProductData(product));
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
      debugPrint('Import error: $e');
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
        // TODO: Implement with new category relation service
        // excel.TextCellValue(p.categoryIds.join(', ')),
        excel.TextCellValue(''), // Tạm thời empty string
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
    // final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    // final url = html.Url.createObjectUrlFromBlob(blob);
    // final anchor = html.AnchorElement(href: url)
    //   ..setAttribute('download', fileName)
    //   ..click();
    // html.Url.revokeObjectUrl(url);
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
    debugPrint('--- Sản phẩm có tồn kho = 99999 ---');
    for (final p in stock99999) {
      debugPrint('ID: \\${p.id}, Tên: \\${p.internalName}, Tồn kho: \\${p.stockSystem}');
    }
    debugPrint('--- Sản phẩm có giá bán = 1,000,000 ---');
    for (final p in price1000000) {
      debugPrint('ID: \\${p.id}, Tên: \\${p.internalName}, Giá bán: \\${p.salePrice}');
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset pagination when filters change
    if (oldWidget.filterCategory != widget.filterCategory ||
        oldWidget.filterPriceRange != widget.filterPriceRange ||
        oldWidget.filterStockRange != widget.filterStockRange ||
        oldWidget.filterStatus != widget.filterStatus ||
        oldWidget.filterTags != widget.filterTags) {
      _resetPagination();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    selectedProductIds.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchText = _searchController.text;
      _resetPagination();
    });
  }

  void _resetPagination() {
    setState(() {
      currentPage = 1;
      isLoadingMore = false;
    });
  }

  bool get _hasActiveFilters {
    return searchText.isNotEmpty ||
           selectedCategory != 'Tất cả' ||
           status != 'Tất cả' ||
           selectedTags.isNotEmpty ||
           priceRange.start > 0 ||
           priceRange.end < maxPrice ||
           stockRange.start > 0 ||
           stockRange.end < maxStock;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('\n=== DEBUG: Building ProductListScreen ===');
    
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: appBackground,
      body: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: isMobile
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Danh sách sản phẩm',
                            style: h1Mobile,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 28, color: Colors.green),
                            tooltip: 'Thêm sản phẩm',
                            onPressed: () => widget.onNavigate?.call(MainPage.addProduct),
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
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
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
                        padding: isMobile ? const EdgeInsets.symmetric(horizontal: 15) : const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            TextField(
                              controller: _searchController,
                              decoration: searchInputDecoration(
                                hint: 'Tìm theo tên, mã vạch...',
                              ),
                              style: const TextStyle(fontSize: 14),
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
                        padding: isMobile ? const EdgeInsets.symmetric(horizontal: 15, vertical: 0) : const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 80.0),
                        child: StreamBuilder<List<Product>>(
                          stream: _productService.getProducts(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Có lỗi xảy ra: ${snapshot.error}',
                                ),
                              );
                            }

                            if (widget.isLoadingProducts) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final products = snapshot.data ?? [];
                            debugPrint('Raw products count: ${products.length}');
                            
                            checkExtremeProducts(products);
                            debugPrint('After checking extreme products: ${products.length}');
                            
                            updateFilterRanges(products);
                            final filteredProducts = filterProducts(products);
                            debugPrint('After filtering: ${filteredProducts.length}');
                            
                            final sortedProducts = sortProducts(filteredProducts);
                            debugPrint('After sorting: ${sortedProducts.length}');
                            
                            // Tính toán sản phẩm cho trang hiện tại
                            final startIndex = (currentPage - 1) * itemsPerPage;
                            final endIndex = startIndex + itemsPerPage;
                            final pagedProducts = sortedProducts.sublist(
                              startIndex, 
                              endIndex > sortedProducts.length ? sortedProducts.length : endIndex
                            );
                            debugPrint('Final paged products: ${pagedProducts.length}');
                            debugPrint('=== End ProductListScreen Build ===\n');

                            if (products.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32.0),
                                child: Center(
                                  child: Text(
                                    'Đang kiểm tra dữ liệu sản phẩm!',
                                  ),
                                ),
                              );
                            }

                            if (filteredProducts.isEmpty && _hasActiveFilters) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Không tìm thấy sản phẩm nào phù hợp với bộ lọc',
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Thử thay đổi điều kiện tìm kiếm hoặc bộ lọc',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: [
                                // Filter and Sort Row
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200, width: 1),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: isMobile ? 160 : 200,
                                        child: ShopifyDropdown<String>(
                                          items: sortOptions.map((o) => o['key'] as String).toList(),
                                          value: sortOption,
                                          getLabel: (key) => sortOptions.firstWhere((o) => o['key'] == key)['label'],
                                          onChanged: (val) {
                                            setState(() {
                                              sortOption = val ?? sortOption;
                                              _resetPagination();
                                            });
                                          },
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
                                // Product List with modern card design
                                Container(
                                  decoration: BoxDecoration(
                                    // color: Colors.grey[50], // Bỏ nền xám, để transparent
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      if (!isMobile)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
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
                                              Expanded(flex: 3, child: Text('Tên sản phẩm', style: TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 14))),
                                              Expanded(flex: 2, child: Text('Giá nhập', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 14))),
                                              Expanded(flex: 2, child: Text('Đơn vị', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 14))),
                                              Expanded(flex: 2, child: Text('Tồn kho hóa đơn', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 14))),
                                              Expanded(flex: 2, child: Text('Tồn kho hệ thống', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 14))),
                                            ],
                                          ),
                                        ),
                                      // Danh sách sản phẩm hoặc thông báo trống
                                      if (pagedProducts.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                                          child: Center(
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Không có sản phẩm nào để hiển thị',
                                                ),
                                                if (currentPage > 1) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Đã hiển thị tất cả sản phẩm',
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        SizedBox(
                                          height: MediaQuery.of(context).size.height * 0.6,
                                          child: ListView.builder(
                                            itemCount: pagedProducts.length,
                                            itemBuilder: (context, index) {
                                              final product = pagedProducts[index];
                                              final isMobile = MediaQuery.of(context).size.width < 600;

                                              if (isMobile) {
                                                // Mobile: render dạng card hiện đại
                                                return Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.08),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: InkWell(
                                                    onTap: () => widget.onProductTap?.call(product),
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(16),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      product.tradeName,
                                                                      style: const TextStyle(
                                                                        fontWeight: FontWeight.w600,
                                                                        fontSize: 16,
                                                                        color: Colors.black87,
                                                                      ),
                                                                    ),
                                                                    if (product.internalName.isNotEmpty)
                                                                      Padding(
                                                                        padding: const EdgeInsets.only(top: 4),
                                                                        child: Text(
                                                                          product.internalName,
                                                                          style: TextStyle(
                                                                            fontSize: 14,
                                                                            color: Colors.grey[600],
                                                                            fontWeight: FontWeight.w400,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: product.stockSystem > 10 ? Colors.green[50] : Colors.orange[50],
                                                                  borderRadius: BorderRadius.circular(6),
                                                                  border: Border.all(
                                                                    color: product.stockSystem > 10 ? Colors.green[200]! : Colors.orange[200]!,
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  '${product.stockSystem}',
                                                                  style: TextStyle(
                                                                    color: product.stockSystem > 10 ? Colors.green[700] : Colors.orange[700],
                                                                    fontWeight: FontWeight.w600,
                                                                    fontSize: 12,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 12),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    'Giá nhập',
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: Colors.grey[600],
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    formatCurrency(product.costPrice),
                                                                    style: const TextStyle(
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.w600,
                                                                      color: Colors.black87,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Column(
                                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                                children: [
                                                                  Text(
                                                                    'Mã vạch',
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: Colors.grey[600],
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    product.barcode ?? '-',
                                                                    style: const TextStyle(
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.w500,
                                                                      color: Colors.black87,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                // Desktop/tablet: render dạng bảng hiện đại
                                                return Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(8),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.04),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  child: InkWell(
                                                    onTap: () => widget.onProductTap?.call(product),
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                                                Text(
                                                                  product.tradeName,
                                                                  style: bodyLarge.copyWith(
                                                                    fontWeight: FontWeight.w600,
                                                                    color: Colors.black87,
                                                                  ),
                                                                ),
                                                                if (product.internalName.isNotEmpty)
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(top: 2),
                                                                    child: Text(
                                                                      product.internalName,
                                                                      style: body.copyWith(
                                                                        color: Colors.grey[600],
                                                                        fontSize: 13,
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: Align(
                                                              alignment: Alignment.center,
                                                              child: Text(
                                                                formatCurrency(product.costPrice),
                                                                style: body.copyWith(
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.black87,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: Align(
                                                              alignment: Alignment.center,
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.grey[100],
                                                                  borderRadius: BorderRadius.circular(4),
                                                                ),
                                                                child: Text(
                                                                  product.unit,
                                                                  style: body.copyWith(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: Align(
                                                              alignment: Alignment.center,
                                                              child: Text(
                                                                '${product.stockInvoice}',
                                                                style: bodyLarge.copyWith(
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.blue[700],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: Align(
                                                              alignment: Alignment.center,
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: product.stockSystem > 10 ? Colors.green[50] : Colors.orange[50],
                                                                  borderRadius: BorderRadius.circular(4),
                                                                  border: Border.all(
                                                                    color: product.stockSystem > 10 ? Colors.green[200]! : Colors.orange[200]!,
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  '${product.stockSystem}',
                                                                  style: bodyLarge.copyWith(
                                                                    fontWeight: FontWeight.w600,
                                                                    fontSize: 13,
                                                                    color: product.stockSystem > 10 ? Colors.green[700] : Colors.orange[700],
                                                                  ),
                                                                ),
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
                                    ],
                                  ),
                                ),
                                // Pagination controls
                                if (filteredProducts.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200, width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Hiển thị ${((currentPage - 1) * itemsPerPage) + 1}-${min(currentPage * itemsPerPage, filteredProducts.length)} của ${filteredProducts.length} sản phẩm',
                                          style: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: currentPage > 1 ? mainGreen : Colors.grey[200],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: IconButton(
                                                onPressed: currentPage > 1 ? () {
                                                  setState(() {
                                                    currentPage--;
                                                  });
                                                } : null,
                                                icon: const Icon(Icons.chevron_left, size: 20),
                                                style: IconButton.styleFrom(
                                                  foregroundColor: currentPage > 1 ? Colors.white : Colors.grey[400],
                                                  padding: const EdgeInsets.all(8),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: mainGreen,
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: mainGreen.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                '$currentPage',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: currentPage < (filteredProducts.length / itemsPerPage).ceil() ? mainGreen : Colors.grey[200],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: IconButton(
                                                onPressed: currentPage < (filteredProducts.length / itemsPerPage).ceil() ? () {
                                                  setState(() {
                                                    currentPage++;
                                                  });
                                                } : null,
                                                icon: const Icon(Icons.chevron_right, size: 20),
                                                style: IconButton.styleFrom(
                                                  foregroundColor: currentPage < (filteredProducts.length / itemsPerPage).ceil() ? Colors.white : Colors.grey[400],
                                                  padding: const EdgeInsets.all(8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
}

// Thêm class custom thumb shape cho slider
class _CustomBlueThumbShape extends RoundSliderThumbShape {
  const _CustomBlueThumbShape({super.enabledThumbRadius, double super.disabledThumbRadius = 10.0});

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
    final Paint fillPaint = Paint()..color = Colors.white;
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF3a6ff8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);
  }
}