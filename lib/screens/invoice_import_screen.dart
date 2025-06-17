import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/product_service.dart';
import 'dart:io';
import 'dart:async';

class ImportProgress {
  final int totalItems;
  final int processedItems;
  final int successCount;
  final int errorCount;
  final List<String> errors;
  final bool isPaused;
  final String currentStatus;

  ImportProgress({
    required this.totalItems,
    required this.processedItems,
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.isPaused,
    required this.currentStatus,
  });
}

class InvoiceImportScreen extends StatefulWidget {
  const InvoiceImportScreen({super.key});

  @override
  State<InvoiceImportScreen> createState() => _InvoiceImportScreenState();
}

class _InvoiceImportScreenState extends State<InvoiceImportScreen> {
  String _status = 'Chưa chọn file nào';
  List<Map<String, dynamic>> _excelData = [];
  List<Map<String, dynamic>> _filteredData = [];
  List<Map<String, dynamic>> _mergedData = [];
  List<Map<String, dynamic>> _companyData = [];
  bool _showFilteredData = false;
  bool _showMergedData = false;
  bool _isImporting = false;
  
  // Thêm các biến mới
  double _progress = 0.0;
  int _currentPage = 0;
  int _pageSize = 100;
  List<String> _validationErrors = [];
  Map<String, int> _retryCount = {};
  int _maxRetries = 3;
  List<String> _importErrors = [];

  // Thêm biến mới để lưu thông tin bộ nhớ
  String _memoryStatus = '';
  bool _hasEnoughMemory = true;

  bool _isPaused = false;
  int _lastProcessedIndex = 0;
  ImportProgress? _importProgress;

  bool _isLoading = false;
  bool _isLoadingFile = false;

  int _importedCount = 0;
  int _totalCount = 0;
  int _currentBatch = 0;
  int _totalBatches = 0;
  Timer? _progressTimer;
  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  // Hàm validate dữ liệu
  List<String> validateRow(List<dynamic> row, int rowIndex) {
    List<String> errors = [];
    
    // Kiểm tra tên sản phẩm
    if (row[0].toString().trim().isEmpty) {
      errors.add('Dòng ${rowIndex + 1}: Tên sản phẩm không được để trống');
    }
    
    // Kiểm tra đơn vị tính
    if (row[1].toString().trim().isEmpty) {
      errors.add('Dòng ${rowIndex + 1}: Đơn vị tính không được để trống');
    }
    
    // Kiểm tra số lượng
    final quantity = double.tryParse(row[2].toString().replaceAll(',', ''));
    if (quantity == null || quantity <= 0) {
      errors.add('Dòng ${rowIndex + 1}: Số lượng phải lớn hơn 0');
    }
    
    return errors;
  }

  // Hàm kiểm tra bộ nhớ
  Future<void> checkMemoryStatus() async {
    try {
      if (Platform.isAndroid) {
        // Lấy thông tin bộ nhớ trên Android
        final result = await Process.run('cat', ['/proc/meminfo']);
        final memInfo = result.stdout.toString();
        
        // Parse thông tin bộ nhớ
        final totalMem = RegExp(r'MemTotal:\s+(\d+)').firstMatch(memInfo)?.group(1);
        final freeMem = RegExp(r'MemFree:\s+(\d+)').firstMatch(memInfo)?.group(1);
        final availableMem = RegExp(r'MemAvailable:\s+(\d+)').firstMatch(memInfo)?.group(1);
        
        if (totalMem != null && availableMem != null) {
          final total = int.parse(totalMem);
          final available = int.parse(availableMem);
          final usedPercentage = ((total - available) / total * 100).toStringAsFixed(1);
          
          setState(() {
            _memoryStatus = 'Bộ nhớ: ${(available / 1024 / 1024).toStringAsFixed(1)}GB khả dụng / ${(total / 1024 / 1024).toStringAsFixed(1)}GB tổng (${usedPercentage}% đã sử dụng)';
            _hasEnoughMemory = available > 500 * 1024 * 1024; // Yêu cầu ít nhất 500MB free
          });
        }
      } else if (Platform.isIOS) {
        // Lấy thông tin bộ nhớ trên iOS
        final result = await Process.run('vm_stat', []);
        final vmStats = result.stdout.toString();
        
        // Parse thông tin bộ nhớ
        final pageSize = 4096; // Default page size on iOS
        final freePages = RegExp(r'Pages free:\s+(\d+)').firstMatch(vmStats)?.group(1);
        final totalPages = RegExp(r'Pages active:\s+(\d+)').firstMatch(vmStats)?.group(1);
        
        if (freePages != null && totalPages != null) {
          final free = int.parse(freePages) * pageSize;
          final total = int.parse(totalPages) * pageSize;
          final usedPercentage = ((total - free) / total * 100).toStringAsFixed(1);
          
          setState(() {
            _memoryStatus = 'Bộ nhớ: ${(free / 1024 / 1024).toStringAsFixed(1)}GB khả dụng / ${(total / 1024 / 1024).toStringAsFixed(1)}GB tổng (${usedPercentage}% đã sử dụng)';
            _hasEnoughMemory = free > 500 * 1024 * 1024; // Yêu cầu ít nhất 500MB free
          });
        }
      } else {
        // Cho các platform khác
        setState(() {
          _memoryStatus = 'Không thể kiểm tra bộ nhớ trên platform này';
          _hasEnoughMemory = true; // Mặc định cho phép
        });
      }
    } catch (e) {
      print('Error checking memory: $e');
      setState(() {
        _memoryStatus = 'Không thể kiểm tra bộ nhớ: $e';
        _hasEnoughMemory = true; // Mặc định cho phép
      });
    }
  }

  // Hàm ước tính bộ nhớ cần thiết cho file Excel
  Future<void> estimateExcelMemory(FilePickerResult result) async {
    if (result.files.first.bytes == null) return;
    
    final fileSize = result.files.first.bytes!.length;
    // Ước tính bộ nhớ cần thiết (thường gấp 2-3 lần kích thước file)
    final estimatedMemory = fileSize * 3;
    
    setState(() {
      _memoryStatus += '\nKích thước file: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB';
      _memoryStatus += '\nBộ nhớ ước tính cần: ${(estimatedMemory / 1024 / 1024).toStringAsFixed(2)}MB';
    });
  }

  // Hàm ước tính bộ nhớ cần thiết cho danh sách sản phẩm
  Future<void> estimateProductsMemory() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').count().get();
      final productCount = snapshot.count ?? 0;
      
      // Ước tính mỗi sản phẩm cần khoảng 1KB bộ nhớ
      final estimatedMemory = productCount * 1024;
      
      setState(() {
        _memoryStatus += '\nSố lượng sản phẩm: $productCount';
        _memoryStatus += '\nBộ nhớ ước tính cho sản phẩm: ${(estimatedMemory / 1024 / 1024).toStringAsFixed(2)}MB';
      });
    } catch (e) {
      print('Error estimating products memory: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    checkMemoryStatus();
  }

  // Hàm đọc file Excel với pagination
  Future<void> readExcelFile() async {
    try {
      setState(() {
        _status = 'Đang đọc file Excel...';
        _isLoading = true;
        _isLoadingFile = true;
        _excelData = [];
        _filteredData = [];
        _mergedData = [];
        _companyData = [];
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) return;

      final bytes = result.files.first.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];
      
      if (sheet == null) {
        throw Exception('Không tìm thấy sheet trong file Excel');
      }

      // Lấy header và tìm vị trí các cột cần thiết
      final headers = sheet.rows.first.map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '').toList();

      // Lưu dữ liệu gốc từ Excel vào _excelData
      final List<Map<String, dynamic>> rawData = [];
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final Map<String, dynamic> rowData = {};
        for (var j = 0; j < headers.length; j++) {
          if (j < row.length) {
            rowData[headers[j]] = row[j]?.value?.toString() ?? '';
          }
        }
        rawData.add(rowData);
      }

      // Tìm vị trí các cột
      final productIndex = headers.indexWhere((h) => h.contains('product'));
      final unitIndex = headers.indexWhere((h) => h.contains('đơn vị tính'));
      final quantityIndex = headers.indexWhere((h) => h.contains('số lượng'));
      final toImportIndex = headers.indexWhere((h) => h.contains('to import'));
      final unitPriceIndex = headers.indexWhere((h) => h.contains('đơn giá'));
      final companyNameIndex = headers.indexWhere((h) => h.contains('tên người bán'));
      final companyAddressIndex = headers.indexWhere((h) => h.contains('địa chỉ bên bán'));
      final companyTaxCodeIndex = headers.indexWhere((h) => h.contains('mã số thuế'));
      final invoiceNumberIndex = headers.indexWhere((h) => h.contains('số hóa đơn'));

      // Kiểm tra các cột bắt buộc
      if (productIndex == -1 || unitIndex == -1 || quantityIndex == -1 || toImportIndex == -1) {
        throw Exception('Không tìm thấy một hoặc nhiều cột cần thiết (Product, Đơn vị tính, Số lượng, To import)');
      }

      // Kiểm tra các cột thông tin công ty
      if (companyNameIndex == -1 || companyAddressIndex == -1 || companyTaxCodeIndex == -1) {
        throw Exception('Không tìm thấy một hoặc nhiều cột cần thiết (Tên người bán, Địa chỉ bên bán, Mã số thuế)');
      }

      // Bước 2,3: Xử lý dữ liệu cho bảng products
      final Map<String, Map<String, dynamic>> mergedProducts = {};
      for (var row in rawData) {
        if (row['to import']?.toLowerCase() == 'true') {
          final productName = row[headers[productIndex]]?.toString().trim() ?? '';
          if (productName.isEmpty) continue;

          final unit = row[headers[unitIndex]]?.toString().trim() ?? '';
          final quantity = double.tryParse(row[headers[quantityIndex]]?.toString().replaceAll(',', '') ?? '0') ?? 0;
          final unitPrice = double.tryParse(row[headers[unitPriceIndex]]?.toString().replaceAll(',', '') ?? '0') ?? 0;

          if (mergedProducts.containsKey(productName)) {
            final existing = mergedProducts[productName]!;
            final existingQuantity = double.tryParse(existing['số lượng']?.toString() ?? '0') ?? 0;
            final existingPrice = double.tryParse(existing['đơn giá']?.toString() ?? '0') ?? 0;
            
            mergedProducts[productName] = {
              ...existing,
              'số lượng': (existingQuantity + quantity).toString(),
              'đơn giá': ((existingPrice + unitPrice) / 2).toString(),
            };
          } else {
            mergedProducts[productName] = {
              'product': productName,
              'đơn vị tính': unit,
              'số lượng': quantity.toString(),
              'đơn giá': unitPrice.toString(),
            };
          }
        }
      }

      // Bước 4: Xử lý dữ liệu cho bảng company
      final Map<String, Map<String, dynamic>> uniqueCompanies = {};
      for (var row in rawData) {
        if (row['to import']?.toLowerCase() == 'true') {
          final companyName = row[headers[companyNameIndex]]?.toString().trim() ?? '';
          final companyAddress = row[headers[companyAddressIndex]]?.toString().trim() ?? '';
          final companyTaxCode = row[headers[companyTaxCodeIndex]]?.toString().trim() ?? '';

          if (companyName.isNotEmpty) {
            final key = '$companyName-$companyTaxCode';
            if (!uniqueCompanies.containsKey(key)) {
              uniqueCompanies[key] = {
                'name': companyName,
                'address': companyAddress,
                'tax_code': companyTaxCode,
              };
            }
          }
        }
      }

      // Bước 5: Xử lý dữ liệu cho order và order_item
      final List<Map<String, dynamic>> orderData = [];
      for (var row in rawData) {
        if (row['to import']?.toLowerCase() == 'true') {
          final invoiceNumber = row[headers[invoiceNumberIndex]]?.toString().trim() ?? '';
          if (invoiceNumber.isNotEmpty) {
            orderData.add(row); // Sử dụng dữ liệu gốc từ Excel
          }
        }
      }

      setState(() {
        _excelData = rawData; // Lưu dữ liệu gốc từ Excel
        _mergedData = mergedProducts.values.toList(); // Lưu dữ liệu đã gộp sản phẩm
        _companyData = uniqueCompanies.values.toList(); // Lưu dữ liệu công ty đã lọc
        _status = 'Đã đọc ${rawData.length} dòng dữ liệu từ file Excel';
        _isLoading = false;
        _isLoadingFile = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Lỗi khi đọc file: $e';
        _isLoading = false;
        _isLoadingFile = false;
      });
    }
  }

  void filterData() {
    final Map<String, Map<String, dynamic>> mergedProducts = {};
    
    for (var row in _excelData) {
      final productName = row['product']?.toString() ?? '';
      if (mergedProducts.containsKey(productName)) {
        final existing = mergedProducts[productName]!;
        final currentQuantity = double.tryParse(row['số lượng']?.toString() ?? '0') ?? 0;
        final existingQuantity = double.tryParse(existing['số lượng']?.toString() ?? '0') ?? 0;
        final currentPrice = double.tryParse(row['đơn giá']?.toString() ?? '0') ?? 0;
        final existingPrice = double.tryParse(existing['đơn giá']?.toString() ?? '0') ?? 0;
        
        mergedProducts[productName] = {
          ...existing,
          'số lượng': (currentQuantity + existingQuantity).toString(),
          'đơn giá': ((currentPrice + existingPrice) / 2).toString(),
        };
      } else {
        mergedProducts[productName] = row;
      }
    }

    setState(() {
      _mergedData = mergedProducts.values.toList();
      _status = 'Đã gộp ${_mergedData.length} sản phẩm trùng tên';
    });
  }

  // Hàm load sản phẩm theo batch
  Future<Map<String, DocumentSnapshot>> loadProductsInBatches() async {
    final productsRef = FirebaseFirestore.instance.collection('products');
    final Map<String, DocumentSnapshot> allProducts = {};
    
    setState(() {
      _status = 'Đang tải danh sách sản phẩm...';
    });

    try {
      // Đọc toàn bộ sản phẩm một lần
      final batch = await productsRef.get();
      
      for (var doc in batch.docs) {
        allProducts[doc['internal_name'] as String] = doc;
      }
      
      setState(() {
        _status = 'Đã tải ${allProducts.length} sản phẩm';
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _status = 'Lỗi khi tải sản phẩm: $e';
      });
    }
    
    return allProducts;
  }

  // Hàm commit batch với retry
  Future<bool> commitBatchWithRetry(WriteBatch batch, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        await batch.commit();
        return true;
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: i + 1));
      }
    }
    return false;
  }

  void pauseImport() {
    setState(() {
      _isPaused = true;
      _status = 'Đã tạm dừng import. Nhấn Tiếp tục để tiếp tục.';
    });
  }

  void resumeImport() {
    setState(() {
      _isPaused = false;
      _status = 'Đang tiếp tục import...';
    });
  }

  Future<void> importToFirebase() async {
    if (_mergedData.isEmpty) {
      setState(() => _status = 'Không có dữ liệu để import');
      return;
    }

    setState(() {
      _isImporting = true;
      _status = 'Đang import dữ liệu...';
      _progress = 0.0;
      _importErrors = [];
    });

    try {
      final allProducts = await loadProductsInBatches();
      int updatedCount = 0;
      int newCount = 0;
      int errorCount = 0;
      final totalItems = _mergedData.length;
      // Tăng số lượng sản phẩm mỗi batch lên 2000 cho web
      const int batchLimit = 2000;

      for (int batchStart = 0; batchStart < _mergedData.length; batchStart += batchLimit) {
        if (_isPaused) {
          setState(() => _status = 'Đã tạm dừng import. Nhấn Tiếp tục để tiếp tục.');
          return;
        }

        final batch = FirebaseFirestore.instance.batch();
        final batchEnd = (batchStart + batchLimit < _mergedData.length) ? batchStart + batchLimit : _mergedData.length;
        int batchOperations = 0;

        for (int i = batchStart; i < batchEnd; i++) {
          final row = _mergedData[i];
          final name = row['product']?.toString() ?? '';
          final unit = row['đơn vị tính']?.toString() ?? '';
          final quantity = double.tryParse(row['số lượng']?.toString() ?? '0') ?? 0;
          final costPrice = double.tryParse(row['đơn giá']?.toString() ?? '0') ?? 0;

          try {
            if (allProducts.containsKey(name)) {
              // Cập nhật sản phẩm hiện có
              final doc = allProducts[name]!;
              final currentStock = (doc['stock_invoice'] ?? 0).toDouble();
              batch.update(doc.reference, {
                'stock_invoice': currentStock + quantity,
                'cost_price': costPrice,
                'updated_at': FieldValue.serverTimestamp(),
              });
              updatedCount++;
            } else {
              // Tạo sản phẩm mới
              final productData = {
                'internal_name': name,
                'unit': unit,
                'stock_invoice': quantity,
                'cost_price': costPrice,
                'category_id': null, // Cho phép null
                'status': 'active',
                'description': '',
                'usage': '',
                'ingredients': '',
                'notes': '',
                'sale_price': 0,
                'gross_profit': 0,
                'auto_price': false,
                'tags': [],
                'barcode': null,
                'sku': null,
                'created_at': FieldValue.serverTimestamp(),
                'updated_at': FieldValue.serverTimestamp(),
              };
              final docRef = FirebaseFirestore.instance.collection('products').doc();
              batch.set(docRef, productData);
              newCount++;
            }
            batchOperations++;
          } catch (e) {
            errorCount++;
            _importErrors.add('Lỗi ở dòng ${i + 1}: $e');
          }

          setState(() {
            _progress = (i + 1) / totalItems;
            _status = 'Đang import... ${((i + 1) / totalItems * 100).toStringAsFixed(1)}%';
          });
        }

        if (batchOperations > 0) {
          try {
            await commitBatchWithRetry(batch);
            // Giảm delay xuống 100ms cho web
            await Future.delayed(const Duration(milliseconds: 100));
          } catch (e) {
            errorCount += batchOperations;
            _importErrors.add('Lỗi khi commit batch: $e');
          }
        }
      }

      setState(() {
        _isImporting = false;
        _status = 'Import hoàn tất. Đã cập nhật $updatedCount sản phẩm, thêm mới $newCount sản phẩm, $errorCount lỗi.';
      });

      // Thêm nút tạo dữ liệu công ty
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563eb), // Màu xanh dương
          foregroundColor: Colors.white, // Màu chữ và icon
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        icon: const Icon(Icons.business),
        label: const Text('Import dữ liệu công ty'),
        onPressed: () async {
          await _createCompaniesAndGetMap(_companyData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo dữ liệu công ty hoàn tất!')),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isImporting = false;
        _status = 'Lỗi khi import: $e';
      });
    }
  }

  // Thêm hàm _createCompaniesAndGetMap
  Future<void> _createCompaniesAndGetMap(List<Map<String, dynamic>> companies) async {
    for (var company in companies) {
      final name = company['name']?.trim().toLowerCase() ?? '';
      final taxCode = company['tax_code']?.trim().toLowerCase() ?? '';
      final address = company['address'] ?? '';
      if (name.isEmpty || taxCode.isEmpty) continue;
      final query = await FirebaseFirestore.instance.collection('companies')
        .where('name', isEqualTo: name)
        .where('tax_code', isEqualTo: taxCode)
        .limit(1).get();
      DocumentReference docRef;
      if (query.docs.isEmpty) {
        docRef = await FirebaseFirestore.instance.collection('companies').add({
          'name': name,
          'tax_code': taxCode,
          'address': address,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        docRef = query.docs.first.reference;
        await docRef.update({
          'address': address,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Thêm hàm filterCompanyData để lọc các công ty trùng nhau
  List<Map<String, dynamic>> filterCompanyData(List<Map<String, dynamic>> companies) {
    final Map<String, Map<String, dynamic>> uniqueCompanies = {};
    for (var company in companies) {
      final taxCode = company['tax_code'] ?? '';
      final name = company['name'] ?? '';
      final key = '$taxCode-$name';
      if (!uniqueCompanies.containsKey(key)) {
        uniqueCompanies[key] = company;
      }
    }
    return uniqueCompanies.values.toList();
  }

  // Thêm hàm readInvoicesFromExcel để đọc danh sách hóa đơn từ file Excel
  Future<void> readInvoicesFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null) {
          final excel = Excel.decodeBytes(bytes);
          final sheet = excel.tables.keys.first;
          final rows = excel.tables[sheet]!.rows;

          final List<Map<String, dynamic>> invoices = [];
          final headers = rows[0].map((cell) => cell?.value.toString().toLowerCase() ?? '').toList();

          for (var i = 1; i < rows.length; i++) {
            final row = rows[i];
            final invoice = {
              'ký hiệu': row[0]?.value.toString() ?? '',
              'số hóa đơn': row[1]?.value.toString() ?? '',
              'ngày tạo hóa đơn': row[2]?.value.toString() ?? '',
              'tên người bán': row[3]?.value.toString() ?? '',
              'địa chỉ bên bán': row[4]?.value.toString() ?? '',
              'mã số thuế': row[5]?.value.toString() ?? '',
              'product': row[6]?.value.toString() ?? '',
              'đơn vị tính': row[7]?.value.toString() ?? '',
              'số lượng': row[8]?.value.toString() ?? '',
              'đơn giá': row[9]?.value.toString() ?? '',
              'tiền chiết khấu': row[10]?.value.toString() ?? '',
              'tax-able': row[11]?.value.toString() ?? '',
              'tax rate': row[12]?.value.toString() ?? '',
              'thuế GTGT': row[13]?.value.toString() ?? '',
              'tổng giảm trừ khác': row[14]?.value.toString() ?? '',
              'tổng tiền thanh toán': row[15]?.value.toString() ?? '',
            };
            invoices.add(invoice);
          }

          setState(() {
            _mergedData = invoices;
            _status = 'Đã đọc ${invoices.length} hóa đơn từ file Excel';
          });
        }
      }
    } catch (e) {
      setState(() {
        _status = 'Lỗi khi đọc file: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tạo danh sách tên sản phẩm bị ghép
    final Set<String> mergedNames = {};
    final Map<String, int> nameCount = {};
    for (var row in _mergedData) {
      final name = row['product']?.toString() ?? '';
      nameCount[name] = (nameCount[name] ?? 0) + 1;
    }
    nameCount.forEach((name, count) {
      if (count > 1) mergedNames.add(name);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Hóa Đơn'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bước 1: Chọn file
              Card(
                color: Colors.blue[50],
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.upload_file, color: Colors.blue, size: 32),
                  title: const Text('Bước 1: Chọn file Excel', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Chọn file Excel (.xlsx) chứa danh sách sản phẩm cần import.'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.file_open),
                    label: const Text('Chọn file'),
                    onPressed: _isLoadingFile ? null : readExcelFile,
                  ),
                ),
              ),
              // Bước 2: Xem trước dữ liệu
              if (_mergedData.isNotEmpty && !_isImporting) ...[
                Card(
                  color: Colors.green[50],
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.preview, color: Colors.green, size: 32),
                    title: const Text('Bước 2: Xem trước dữ liệu', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Tổng số sản phẩm: ${_mergedData.length}'),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: SizedBox(
                    height: 200,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tableWidth = constraints.maxWidth;
                        final colCount = 5;
                        final colWidth = tableWidth / colCount;
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 0,
                            columns: [
                              DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Tên sản phẩm')))),
                              DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Đơn vị tính')))),
                              DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Số lượng')))),
                              DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Đơn giá nhập')))),
                              DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Trạng thái')))),
                            ],
                            rows: _mergedData.map((row) {
                              final isMerged = mergedNames.contains(row['product']?.toString() ?? '');
                              return DataRow(
                                color: isMerged ? MaterialStateProperty.all(Colors.yellow[100]) : null,
                                cells: [
                                  DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['product']?.toString() ?? '')))),
                                  DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['đơn vị tính']?.toString() ?? '')))),
                                  DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['số lượng']?.toString() ?? '')))),
                                  DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['đơn giá']?.toString() ?? '0')))),
                                  DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Row(
                                    children: [
                                      if (isMerged) ...[
                                        const Icon(Icons.warning, color: Colors.orange, size: 18),
                                        const SizedBox(width: 4),
                                        const Text('Đã ghép', style: TextStyle(color: Colors.orange)),
                                      ] else ...[
                                        const Text('Mới', style: TextStyle(color: Colors.green)),
                                      ]
                                    ],
                                  )))),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              // Bước 3: Import vào DB
              if (_mergedData.isNotEmpty) ...[
                Card(
                  color: Colors.orange[50],
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.cloud_upload, color: Colors.orange, size: 32),
                    title: const Text('Bước 3: Import vào hệ thống', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Nhấn nút "Import vào DB" để bắt đầu import dữ liệu.'),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Import vào DB'),
                      onPressed: _isImporting ? null : importToFirebase,
                    ),
                  ),
                ),
              ],
              // Hiển thị tiến trình import nếu đang import
              if (_isImporting) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                Text('Đang import: ${(_progress * 100).toStringAsFixed(1)}%', style: TextStyle(color: Colors.orange)),
              ],
              Text(_status),
              if (_isImporting || _isLoading)
                LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_excelData.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: filterData,
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Tạo sản phẩm từ bộ lọc'),
                    ),
                  const SizedBox(width: 16),
                  if (_importErrors.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Danh sách lỗi:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _importErrors.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.error, color: Colors.red),
                            title: Text(_importErrors[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
              if (_isLoadingFile) ...[
                const SizedBox(height: 32),
                Center(child: Text('Đang xử lý file Excel, vui lòng chờ...', style: TextStyle(fontSize: 16, color: Colors.blue))),
              ],
              // Bước 4: Hiển thị dữ liệu công ty
              if (_companyData.isNotEmpty) ...[
                Card(
                  color: Colors.purple[50],
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.business, color: Colors.purple, size: 32),
                    title: const Text('Bước 4: Dữ liệu công ty', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Tổng số công ty: ${_companyData.length}'),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: SizedBox(
                    height: 200,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tableWidth = constraints.maxWidth;
                        final colCount = 3;
                        final colWidth = tableWidth / colCount;
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 0,
                            columns: [
                              DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Tên người bán')))),
                              DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Địa chỉ bên bán')))),
                              DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Mã số thuế')))),
                            ],
                            rows: _companyData.map((company) {
                              return DataRow(
                                cells: [
                                  DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(company['name'] ?? '')))),
                                  DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(company['address'] ?? '')))),
                                  DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(company['tax_code'] ?? '')))),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563eb), // Màu xanh dương
                    foregroundColor: Colors.white, // Màu chữ và icon
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  icon: const Icon(Icons.business),
                  label: const Text('Import dữ liệu công ty'),
                  onPressed: () async {
                    await _createCompaniesAndGetMap(_companyData);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tạo dữ liệu công ty hoàn tất!')),
                    );
                  },
                ),
              ],
              // Bước 5: Hiển thị danh sách các hóa đơn
              Card(
                color: Colors.purple[50],
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.receipt, color: Colors.purple, size: 32),
                  title: const Text('Bước 5: Danh sách hóa đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Tổng số hóa đơn: ${_mergedData.length}'),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: SizedBox(
                  height: 300,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tableWidth = constraints.maxWidth;
                      final colCount = 15;
                      final colWidth = tableWidth / colCount;
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columnSpacing: 0,
                          horizontalMargin: 0,
                          columns: [
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Số HĐ')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Ngày HĐ')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Ký hiệu')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Mẫu số')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Tên người bán')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Mã số thuế')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Địa chỉ')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Sản phẩm')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Đơn vị tính')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Số lượng')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Đơn giá')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Tiền chiết khấu')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Tax-able')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Tax rate')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Thuế GTGT')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Tổng giảm trừ khác')))),
                            DataColumn(label: SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text('Tổng tiền thanh toán')))),
                          ],
                          rows: _excelData.map((row) {
                            return DataRow(
                              cells: [
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['số hóa đơn']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['ngày hóa đơn']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['ký hiệu']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['mẫu số']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['tên người bán']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['mã số thuế']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['địa chỉ bên bán']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['product']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['đơn vị tính']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['số lượng']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['đơn giá']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['tiền chiết khấu']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['tax-able']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['tax rate']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['thuế GTGT']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['tổng giảm trừ khác']?.toString() ?? '')))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row['tổng tiền thanh toán']?.toString() ?? '')))),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563eb),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Import đơn hàng vào hệ thống'),
                onPressed: () async {
                  print('Import button pressed');
                  print('Excel data length: [32m${_excelData.length}[0m');
                  int orderCount = 0;
                  int itemCount = 0;
                  List<String> errorLogs = [];
                  Map<String, DocumentReference> orderRefs = {};
                  Map<String, String> companyTaxToId = {};
                  Map<String, String> productNameToId = {};

                  // 1. Lấy map company tax_code -> company_id
                  final companySnapshot = await FirebaseFirestore.instance.collection('companies').get();
                  print('Company snapshot: ${companySnapshot.docs.length}');
                  for (var doc in companySnapshot.docs) {
                    final taxCode = doc['tax_code']?.toString().trim() ?? '';
                    if (taxCode.isNotEmpty) {
                      companyTaxToId[taxCode] = doc.id;
                    }
                  }
                  print('companyTaxToId: $companyTaxToId');
                  // 2. Lấy map product name -> product_id
                  final productSnapshot = await FirebaseFirestore.instance.collection('products').get();
                  print('Product snapshot: ${productSnapshot.docs.length}');
                  for (var doc in productSnapshot.docs) {
                    String name = '';
                    if (doc.data().containsKey('trade_name')) {
                      name = doc['trade_name']?.toString() ?? '';
                    } else if (doc.data().containsKey('internal_name')) {
                      name = doc['internal_name']?.toString() ?? '';
                    }
                    if (name.isNotEmpty) {
                      productNameToId[name] = doc.id;
                    }
                  }
                  print('productNameToId: $productNameToId');

                  for (final row in _excelData) {
                    final invoiceNumber = row['số hóa đơn']?.toString() ?? '';
                    if (invoiceNumber.isEmpty) continue;
                    final taxCode = row['mã số thuế']?.toString() ?? '';
                    final companyId = companyTaxToId[taxCode];
                    if (companyId == null) {
                      print('Không tìm thấy công ty với mã số thuế: $taxCode (HĐ: $invoiceNumber)');
                      errorLogs.add('Không tìm thấy công ty với mã số thuế: $taxCode (HĐ: $invoiceNumber)');
                      continue;
                    }
                    // 3. Tìm hoặc tạo order
                    if (!orderRefs.containsKey(invoiceNumber)) {
                      final orderQuery = await FirebaseFirestore.instance
                          .collection('order')
                          .where('invoice_number', isEqualTo: invoiceNumber)
                          .limit(1)
                          .get();
                      DocumentReference orderRef;
                      if (orderQuery.docs.isEmpty) {
                        print('Tạo mới order cho HĐ: $invoiceNumber');
                        orderRef = await FirebaseFirestore.instance.collection('order').add({
                          'invoice_number': invoiceNumber,
                          'created_date': row['ngày hóa đơn'] ?? '',
                          'company_id': companyId,
                          'sub_total': double.tryParse(row['sub_total']?.toString() ?? '0') ?? 0,
                          'total_discounts': double.tryParse(row['tổng giảm trừ khác']?.toString() ?? '0') ?? 0,
                          'tax': double.tryParse(row['thuế GTGT']?.toString() ?? '0') ?? 0,
                          'total': double.tryParse(row['tổng tiền thanh toán']?.toString() ?? '0') ?? 0,
                          'item_count': 0, // sẽ cập nhật sau
                          'order_items_list': [], // sẽ cập nhật sau
                          // ... các trường khác nếu cần
                        });
                        orderCount++;
                      } else {
                        print('Order đã tồn tại cho HĐ: $invoiceNumber');
                        orderRef = orderQuery.docs.first.reference;
                      }
                      orderRefs[invoiceNumber] = orderRef;
                    }
                    final orderRef = orderRefs[invoiceNumber]!;

                    // 4. Lấy product_id
                    final productName = row['product']?.toString() ?? '';
                    final productId = productNameToId[productName];
                    if (productId == null) {
                      print('Không tìm thấy sản phẩm: $productName (HĐ: $invoiceNumber)');
                      errorLogs.add('Không tìm thấy sản phẩm: $productName (HĐ: $invoiceNumber)');
                      continue;
                    }
                    // 5. Tạo order_item
                    final quantity = double.tryParse(row['số lượng']?.toString() ?? '0') ?? 0;
                    final price = double.tryParse(row['đơn giá']?.toString() ?? '0') ?? 0;
                    final discount = double.tryParse(row['tiền chiết khấu']?.toString() ?? '0') ?? 0;
                    final taxRate = double.tryParse(row['tax rate']?.toString() ?? '0') ?? 0;
                    final taxable = (row['tax-able']?.toString().toLowerCase() == 'true' || row['tax-able']?.toString() == '1');
                    final subTotal = quantity * price;
                    final total = subTotal - discount + (taxable ? subTotal * taxRate / 100 : 0);
                    print('Tạo order_item: product=$productName, product_id=$productId, quantity=$quantity, price=$price, total=$total');
                    await orderRef.collection('order_items').add({
                      'product_id': productId,
                      'quantity': quantity,
                      'price': price,
                      'sub_total': subTotal,
                      'discount_amount': discount,
                      'tax_rate': taxRate,
                      'taxable': taxable,
                      'total': total,
                    });
                    itemCount++;
                  }
                  // 6. Hiển thị log
                  print('Import xong: $orderCount đơn hàng, $itemCount sản phẩm. Lỗi: ${errorLogs.length}');
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Kết quả import'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Đã import $orderCount đơn hàng, $itemCount sản phẩm.'),
                            if (errorLogs.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text('Lỗi:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ...errorLogs.map((e) => Text(e, style: const TextStyle(color: Colors.red))),
                            ]
                          ],
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 