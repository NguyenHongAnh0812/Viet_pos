import 'package:flutter/material.dart';
import 'dart:convert';

import '../../services/product_service.dart';
import '../../widgets/main_layout.dart';
import 'product_detail_screen.dart';
import 'edit_product_screen.dart';
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
import '../../services/product_category_service.dart';
import '../../widgets/custom/multi_select_dropdown.dart';
import 'package:intl/intl.dart';

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
  final _categoryService = ProductCategoryService();
  final TextEditingController _searchController = TextEditingController();
  // Thêm khai báo biến filter danh mục
  List<ProductCategory> selectedCategories = [];
  List<ProductCategory> allCategories = [];
  List<String> allTags = ['kháng sinh', 'phổ rộng', 'vitamin', 'bổ sung', 'NSAID', 'giảm đau', 'quinolone'];
  String get selectedCategory => widget.filterCategory ?? 'Tất cả';
  // Getter lấy filter từ state, ưu tiên biến filter trong state, không lấy từ widget
  String get status => filterStatus ?? 'Tất cả';
  RangeValues get priceRange => filterPriceRange ?? RangeValues(0, maxPrice);
  RangeValues get stockRange => filterStockRange ?? RangeValues(0, maxStock.toDouble());
  Set<String> get selectedTags => filterTags ?? {};
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
  // Thêm biến đếm số lượng sản phẩm lọc được cho header
  int _productCount = 0;

  // Infinite scroll state
  final int itemsPerPage = 10;
  int currentPage = 1;
  bool isLoadingMore = false;

  // Thêm các biến filter cho state
  String? filterStatus;
  RangeValues? filterPriceRange;
  RangeValues? filterStockRange;
  Set<String>? filterTags;

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

  List<Product> filterProducts(List<Product> products) {
    debugPrint('FILTER: status=$status, priceRange=(${priceRange.start}, ${priceRange.end}), stockRange=(${stockRange.start}, ${stockRange.end}), selectedTags=$selectedTags');
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
      if (selectedCategories.isNotEmpty) {
        final selectedIds = selectedCategories.map((c) => c.id).toSet();
        if (!product.categoryIds.any((id) => selectedIds.contains(id))) {
          return false;
        }
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
      if (status != 'Tất cả') {
        if (status == 'active' && product.status != 'active') return false;
        if (status == 'inactive' && product.status != 'inactive') return false;
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
                  product[field] = (value.toLowerCase() == 'còn bán' || value.toLowerCase() == 'active') ? 'active' : 'inactive';
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
          product['status'] ??= 'active';
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
                product[field] = (value?.toString().toLowerCase() ?? '') == 'còn bán' ? 'active' : 'inactive';
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
          product['status'] ??= 'active';
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
        
        excel.TextCellValue(p.status == 'active' ? 'Đang KD' : 'Ngừng KD'),
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
        }
        );
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
    // Load categories for filter
    _categoryService.getCategories().first.then((cats) {
      if (mounted) setState(() => allCategories = cats);
    });
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
           selectedCategories.isNotEmpty ||
           status != 'Tất cả' ||
           selectedTags.isNotEmpty ||
           priceRange.start > 0 ||
           priceRange.end < maxPrice ||
           stockRange.start > 0 ||
           stockRange.end < maxStock;
  }

  void _showAdvancedFilterModal() async {
    final numberFormat = NumberFormat.decimalPattern('vi');
    double safeMinPrice = 0; // luôn là 0
    double safeMaxPrice = maxPrice > 0 ? maxPrice : 1;
    int safeMinStock = 0; // luôn là 0
    int safeMaxStock = maxStock > 0 ? maxStock : 1;
    RangeValues safePriceRange = priceRange;
    if (safePriceRange.start < safeMinPrice || safePriceRange.start > safeMaxPrice) safePriceRange = RangeValues(safeMinPrice, safePriceRange.end);
    if (safePriceRange.end > safeMaxPrice || safePriceRange.end < safeMinPrice) safePriceRange = RangeValues(safePriceRange.start, safeMaxPrice);
    if (safePriceRange.start > safePriceRange.end) safePriceRange = RangeValues(safeMinPrice, safeMaxPrice);
    RangeValues safeStockRange = stockRange;
    if (safeStockRange.start < safeMinStock || safeStockRange.start > safeMaxStock) safeStockRange = RangeValues(safeMinStock.toDouble(), safeStockRange.end);
    if (safeStockRange.end > safeMaxStock || safeStockRange.end < safeMinStock) safeStockRange = RangeValues(safeStockRange.start, safeMaxStock.toDouble());
    if (safeStockRange.start > safeStockRange.end) safeStockRange = RangeValues(safeMinStock.toDouble(), safeMaxStock.toDouble());

    RangeValues tempPrice = safePriceRange;
    RangeValues tempStock = safeStockRange;
    Set<String> tempTags = Set<String>.from(selectedTags);
    String tagSearch = '';
    String tempStatus = status;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.only(top: 60, left: 0, right: 0),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bộ lọc nâng cao', style: h4.copyWith(color: mainGreen, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            debugPrint('APPLY FILTER: status=$tempStatus, priceRange=($tempPrice), stockRange=($tempStock), tags=$tempTags');
                            setState(() {
                              // Áp dụng các filter vào state
                              filterStatus = tempStatus;
                              filterPriceRange = tempPrice;
                              filterStockRange = tempStock;
                              filterTags = Set<String>.from(tempTags);
                              _resetPagination();
                            });
                            Navigator.pop(context);
                          },
                          child: Text('Áp dụng', style: labelLarge.copyWith(color: mainGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Giảm khoảng cách header với trạng thái
                    Text('Trạng thái', style: labelLarge.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8), // Giảm từ 12 -> 8
                    Row(
                      children: [
                        _StatusToggleButton(
                          label: 'Tất cả',
                          selected: tempStatus == 'Tất cả',
                          onTap: () => setModalState(() => tempStatus = 'Tất cả'),
                        ),
                        const SizedBox(width: 8), // Giảm từ 12 -> 8
                        _StatusToggleButton(
                          label: 'Đang KD',
                          selected: tempStatus == 'active',
                          onTap: () => setModalState(() => tempStatus = 'active'),
                        ),
                        const SizedBox(width: 8), // Giảm từ 12 -> 8
                        _StatusToggleButton(
                          label: 'Ngừng KD',
                          selected: tempStatus == 'inactive',
                          onTap: () => setModalState(() => tempStatus = 'inactive'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Giảm từ 24 -> 16
                    Text('Khoảng giá', style: labelLarge.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RangeSlider(
                          values: tempPrice,
                          min: 0,
                          max: safeMaxPrice,
                          divisions: 100,
                          labels: RangeLabels(
                            '${numberFormat.format(tempPrice.start)}đ',
                            '${numberFormat.format(tempPrice.end)}đ',
                          ),
                          onChanged: (v) => setModalState(() => tempPrice = v),
                          activeColor: Colors.black,
                          inactiveColor: borderColor,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${numberFormat.format(tempPrice.start)}đ',
                              style: bodySmall.copyWith(color: textSecondary),
                            ),
                            Text(
                              '${numberFormat.format(safeMaxPrice)}đ',
                              style: bodySmall.copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10), // Tăng khoảng cách với label tiếp theo
                      ],
                    ),
                    Text('Tồn kho', style: labelLarge.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RangeSlider(
                          values: tempStock,
                          min: 0,
                          max: safeMaxStock.toDouble(),
                          divisions: 100,
                          labels: RangeLabels(
                            numberFormat.format(tempStock.start),
                            numberFormat.format(tempStock.end),
                          ),
                          onChanged: (v) => setModalState(() => tempStock = v),
                          activeColor: Colors.black,
                          inactiveColor: borderColor,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              numberFormat.format(tempStock.start),
                              style: bodySmall.copyWith(color: textSecondary),
                            ),
                            Text(
                              numberFormat.format(safeMaxStock),
                              style: bodySmall.copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10), // Tăng khoảng cách với label tiếp theo
                      ],
                    ),
                    const SizedBox(height: 16), // Giảm từ 24 -> 16
                    Text('Tags', style: labelLarge.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4), // Giảm từ 8 -> 4
                    // Input tags cao hơn
                    SizedBox(
                      height: 40, // Giảm từ 48 -> 40
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm tags...',
                          isDense: true, // true để giảm padding
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10), // Giảm padding
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16), // Giảm radius
                            borderSide: const BorderSide(color: borderColor),
                          ),
                        ),
                        onChanged: (v) => setModalState(() => tagSearch = v),
                      ),
                    ),
                    const SizedBox(height: 8), // Giảm từ 12 -> 8
                    Container(
                      constraints: BoxConstraints(maxHeight: 90), // Giảm maxHeight từ 120 -> 90
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6, // Giảm spacing từ 8 -> 6
                          runSpacing: 6, // Giảm runSpacing từ 8 -> 6
                          children: allTags
                              .where((t) => t.toLowerCase().contains(tagSearch.toLowerCase()))
                              .map((tag) => _TagButton(
                                    tag: tag,
                                    selected: tempTags.contains(tag),
                                    onTap: () => setModalState(() {
                                      if (tempTags.contains(tag)) {
                                        tempTags.remove(tag);
                                      } else {
                                        tempTags.add(tag);
                                      }
                                    }),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onAdvancedFilterApplied(RangeValues price, RangeValues stock, Set<String> tags) {
    setState(() {
      tempPriceRange = price;
      tempStockRange = stock;
      tempSelectedTags = tags;
      // Áp dụng filter thực tế
      // Có thể gọi _resetPagination hoặc filterProducts tuỳ logic
    });
  }

  void _showCategoryFilterModal() async {
    List<ProductCategory> tempSelected = List.from(selectedCategories);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.only(top: 60),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chọn danh mục', style: TextStyle(color: mainGreen, fontWeight: FontWeight.bold, fontSize: 20)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedCategories = List.from(tempSelected);
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Áp dụng', style: TextStyle(color: mainGreen, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...allCategories.map((cat) => Padding(
                    padding: EdgeInsets.only(left: 20.0 * (cat.level ?? 0)),
                    child: CheckboxListTile(
                      value: tempSelected.any((c) => c.id == cat.id),
                      onChanged: (checked) {
                        setModalState(() {
                          if (checked == true) {
                            if (!tempSelected.any((c) => c.id == cat.id)) tempSelected.add(cat);
                          } else {
                            tempSelected.removeWhere((c) => c.id == cat.id);
                          }
                        });
                      },
                      title: Text(cat.name),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  )),
                ],
              ),
            );
          },
        );
      },
    );
    // Sau khi chọn xong, filter lại sản phẩm
    setState(() {
      // Nếu không chọn gì thì filterCategory = 'Tất cả'
      if (selectedCategories.isEmpty) {
        tempSelectedCategory = '';
      } else {
        tempSelectedCategory = selectedCategories.map((c) => c.id).join(',');
      }
      _resetPagination();
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('\n=== DEBUG: Building ProductListScreen ===');
    final isMobile = MediaQuery.of(context).size.width < 600;
    bool _showSearch = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          backgroundColor: appBackground,
          floatingActionButton: FloatingActionButton(
            backgroundColor: mainGreen,
            onPressed: () => widget.onNavigate?.call(MainPage.addProduct),
            child: const Icon(Icons.add, color: Colors.white, size: 32),
            shape: const CircleBorder(),
          ),
          body: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                  // Di chuyển header vào trong StreamBuilder để lấy filteredProducts.length
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Product List and Filter/Sort Row together in StreamBuilder
                      Padding(
                        padding: isMobile ? const EdgeInsets.symmetric(horizontal: 0, vertical: 0) : const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 80.0),
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
                            
                            final startIndex = (currentPage - 1) * itemsPerPage;
                            final endIndex = startIndex + itemsPerPage;
                            final pagedProducts = sortedProducts.sublist(
                              startIndex,
                              endIndex > sortedProducts.length ? sortedProducts.length : endIndex,
                            );
                            // Header nằm trong StreamBuilder để lấy filteredProducts.length
                            Widget header = Container(
                              color: mainGreen,
                              padding: const EdgeInsets.only(left: 20, right: 8, top: 18, bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Sản phẩm (${filteredProducts.length})',
                                             style: h2Mobile.copyWith(color: Colors.white),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.search, color: Colors.white),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => FractionallySizedBox(
                                              heightFactor: 1.0, // Full height
                                              child: _ProductSearchSheet(
                                                onProductSelected: (product) {
                                                  // Có thể xử lý khi chọn sản phẩm nếu muốn
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Đưa filter/sort lên header xanh
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: _showCategoryFilterModal,
                                        child: Row(
                                          children: [
                                            Text('Danh mục', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                            if (selectedCategories.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 4),
                                                child: Icon(Icons.check_circle, color: Colors.white, size: 14),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      // Giá bán (sort)
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (sortOption == 'price_asc') {
                                              sortOption = 'price_desc';
                                            } else {
                                              sortOption = 'price_asc';
                                            }
                                            // Bỏ sort tồn kho nếu đang chọn
                                            if (sortOption == 'stock_asc' || sortOption == 'stock_desc') {
                                              sortOption = 'price_asc';
                                            }
                                            _resetPagination();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: sortOption == 'price_asc' || sortOption == 'price_desc'
                                              ? BoxDecoration(
                                                  color: Colors.white.withOpacity(0.18),
                                                  borderRadius: BorderRadius.circular(6),
                                                )
                                              : null,
                                          child: Row(
                                            children: [
                                              Text(
                                                'Giá bán',
                                                style: TextStyle(
                                                  color: (sortOption == 'price_asc' || sortOption == 'price_desc') ? Colors.white : Colors.white70,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (sortOption == 'price_asc')
                                                const Icon(Icons.arrow_upward, size: 16, color: Colors.white),
                                              if (sortOption == 'price_desc')
                                                const Icon(Icons.arrow_downward, size: 16, color: Colors.white),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      // Tồn kho (sort)
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (sortOption == 'stock_asc') {
                                              sortOption = 'stock_desc';
                                            } else {
                                              sortOption = 'stock_asc';
                                            }
                                            // Bỏ sort giá nếu đang chọn
                                            if (sortOption == 'price_asc' || sortOption == 'price_desc') {
                                              sortOption = 'stock_asc';
                                            }
                                            _resetPagination();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: sortOption == 'stock_asc' || sortOption == 'stock_desc'
                                              ? BoxDecoration(
                                                  color: Colors.white.withOpacity(0.18),
                                                  borderRadius: BorderRadius.circular(6),
                                                )
                                              : null,
                                          child: Row(
                                            children: [
                                              Text(
                                                'Tồn kho',
                                                style: TextStyle(
                                                  color: (sortOption == 'stock_asc' || sortOption == 'stock_desc') ? Colors.white : Colors.white70,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (sortOption == 'stock_asc')
                                                const Icon(Icons.arrow_upward, size: 16, color: Colors.white),
                                              if (sortOption == 'stock_desc')
                                                const Icon(Icons.arrow_downward, size: 16, color: Colors.white),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      // Icon filter
                                      IconButton(
                                        icon: const Icon(Icons.filter_alt_outlined, color: Colors.white, size: 22),
                                        onPressed: _showAdvancedFilterModal,
                                        tooltip: 'Bộ lọc',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                            debugPrint('Final paged products: ${pagedProducts.length}');
                            debugPrint('=== End ProductListScreen Build ===\n');

                            if (products.isEmpty) {
                              return Column(
                                children: [
                                  header,
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                                    child: Center(
                                      child: Text('Đang kiểm tra dữ liệu sản phẩm!'),
                                    ),
                                  ),
                                ],
                              );
                            }

                            if (filteredProducts.isEmpty && _hasActiveFilters) {
                              return Column(
                                children: [
                                  header,
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Text('Không tìm thấy sản phẩm nào phù hợp với bộ lọc'),
                                          const SizedBox(height: 8),
                                          Text('Thử thay đổi điều kiện tìm kiếm hoặc bộ lọc'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                header,
                                // Product List with mobile layout for both desktop and mobile
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(0),
                                  ),
                                  child: Column(
                                    children: [
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
                                          height: MediaQuery.of(context).size.height * 0.8,
                                          child: ListView.builder(
                                            itemCount: pagedProducts.length,
                                            itemBuilder: (context, index) {
                                              final product = pagedProducts[index];
                                              
                                              // Mobile layout for both desktop and mobile
                                              return Dismissible(
                                                key: ValueKey(product.id),
                                                direction: DismissDirection.endToStart,
                                                background: Container(
                                                  alignment: Alignment.centerRight,
                                                  color: Colors.redAccent,
                                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                                  child: const Icon(Icons.delete, color: Colors.white, size: 32),
                                                ),
                                                confirmDismiss: (direction) async {
                                                  return await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text('Xác nhận xóa'),
                                                      content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.tradeName}"?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, false),
                                                          child: const Text('Hủy'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, true),
                                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                          child: const Text('Xóa'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                onDismissed: (direction) async {
                                                  await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
                                                  if (mounted) {
                                                    OverlayEntry? entry;
                                                    entry = OverlayEntry(
                                                      builder: (_) => DesignSystemSnackbar(
                                                        message: 'Đã xóa sản phẩm thành công',
                                                        icon: Icons.check_circle,
                                                        onDismissed: () => entry?.remove(),
                                                      ),
                                                    );
                                                    Overlay.of(context).insert(entry);
                                                  }
                                                  setState(() {}); // Cập nhật lại UI
                                                },
                                                child: InkWell(
                                                  onTap: () => Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) => EditProductScreen(product: product),
                                                    ),
                                                  ),
                                                  child: Container(
                                                    color: Colors.white,
                                                    width: double.infinity,
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            // Ảnh placeholder
                                                            Container(
                                                              width: 56,
                                                              height: 56,
                                                              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12, left: 16),
                                                              decoration: BoxDecoration(
                                                                color: Colors.grey[300],
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: const Icon(Icons.image, color: Colors.white54, size: 32),
                                                            ),
                                                            // Thông tin sản phẩm
                                                            Expanded(
                                                              child: Stack(
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                                                                    child: Column(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(product.tradeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                                        if (product.internalName.isNotEmpty)
                                                                          Padding(
                                                                            padding: const EdgeInsets.only(top: 2),
                                                                            child: Text(product.internalName, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                                          ),
                                                                        if ((product.barcode ?? '').isNotEmpty)
                                                                          Padding(
                                                                            padding: const EdgeInsets.only(top: 2),
                                                                            child: Text(product.barcode!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                                          ),
                                                                        Padding(
                                                                          padding: const EdgeInsets.only(top: 8),
                                                                          child: Text('Giá bán: ${formatCurrency(product.salePrice)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  // Số lượng (chip bo tròn, viền xanh, góc trên phải)
                                                                  Positioned(
                                                                    top: 12,
                                                                    right: 16,
                                                                    child: Container(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.white,
                                                                        border: Border.all(color: mainGreen, width: 1),
                                                                        borderRadius: BorderRadius.circular(20),
                                                                      ),
                                                                      child: Text('${product.stockSystem} ${product.unit}', style: const TextStyle(color: mainGreen, fontSize: 12, fontWeight: FontWeight.w500)),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        // Border xám nhạt dưới cùng
                                                        Container(
                                                          height: 1,
                                                          color: Colors.grey[200],
                                                          margin: const EdgeInsets.only(left: 88), // thẳng hàng với text, không kéo dài dưới avatar
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                    // Pagination controls
                                    if (filteredProducts.length > itemsPerPage) ...[
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
                                                IconButton(
                                                  onPressed: currentPage > 1 ? () {
                                                    setState(() {
                                                      currentPage--;
                                                    });
                                                  } : null,
                                                  icon: const Icon(Icons.chevron_left, size: 20),
                                                  color: currentPage > 1 ? mainGreen : Colors.grey[400],
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: Colors.transparent,
                                                    padding: const EdgeInsets.all(8),
                                                    elevation: 0,
                                                    shadowColor: Colors.transparent,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: mainGreen,
                                                    borderRadius: BorderRadius.circular(8),
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
                                                IconButton(
                                                  onPressed: currentPage < (filteredProducts.length / itemsPerPage).ceil() ? () {
                                                    setState(() {
                                                      currentPage++;
                                                    });
                                                  } : null,
                                                  icon: const Icon(Icons.chevron_right, size: 20),
                                                  color: currentPage < (filteredProducts.length / itemsPerPage).ceil() ? mainGreen : Colors.grey[400],
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: Colors.transparent,
                                                    padding: const EdgeInsets.all(8),
                                                    elevation: 0,
                                                    shadowColor: Colors.transparent,
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
      },
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
    final products = await ProductService().getProducts().first;
    setState(() {
      _results = products.where((p) =>
        p.internalName.toLowerCase().contains(query) ||
        p.tradeName.toLowerCase().contains(query) ||
        (p.barcode?.toLowerCase().contains(query) ?? false)
      ).toList();
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header với search bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Tìm theo tên, mã vạch, SKU...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Dịch placeholder sang phải
                      ),
                      style: h4,
                    ),
                  ),
                ],
              ),
            ),
            // Kết quả tìm kiếm
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _controller.text.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('Nhập từ khoá để tìm kiếm sản phẩm', style: bodySmall.copyWith(color: textSecondary)),
                            ],
                          ),
                        )
                      : _results.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text('Không tìm thấy sản phẩm phù hợp', style: bodySmall.copyWith(color: textSecondary)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _results.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final p = _results[i];
                                return InkWell(
                                  onTap: () {
                                    widget.onProductSelected?.call(p);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Ảnh placeholder
                                        Container(
                                          width: 48,
                                          height: 48,
                                          margin: const EdgeInsets.only(right: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.image, color: Colors.white54, size: 28),
                                        ),
                                        // Thông tin sản phẩm
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.tradeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              if (p.internalName.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(p.internalName, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                                ),
                                              if ((p.barcode ?? '').isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(p.barcode!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                                ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text('Giá bán: ${formatCurrency(p.salePrice)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Chip số lượng
                                        Container(
                                          margin: const EdgeInsets.only(left: 8, top: 2),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${p.stockSystem} ${p.unit}',
                                            style: const TextStyle(color: Color(0xFF34A853), fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

// Widget cho nút trạng thái toggle
class _StatusToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _StatusToggleButton({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), // Giảm từ 20,10 -> 14,8
        decoration: BoxDecoration(
          color: selected ? mainGreen : Colors.white,
          borderRadius: BorderRadius.circular(18), // Giảm từ 24 -> 18
          border: Border.all(color: mainGreen.withOpacity(0.3), width: 1.2), // Giảm width
        ),
        child: Text(
          label,
          style: body.copyWith(
            color: selected ? Colors.white : mainGreen,
            fontWeight: FontWeight.w500,
            fontSize: 14, // Giảm font size
          ),
        ),
      ),
    );
  }
}

// Widget cho tag button
class _TagButton extends StatelessWidget {
  final String tag;
  final bool selected;
  final VoidCallback onTap;
  const _TagButton({required this.tag, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Giảm từ 16,8 -> 12,6
        decoration: BoxDecoration(
          color: selected ? mainGreen.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16), // Giảm từ 20 -> 16
          border: Border.all(color: selected ? mainGreen : borderColor, width: 1),
        ),
        child: Text(
          tag,
          style: bodySmall.copyWith(
            color: selected ? mainGreen : textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 13, // Giảm font size
          ),
        ),
      ),
    );
  }
}