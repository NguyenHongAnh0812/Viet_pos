import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/product_service.dart';
import 'dart:io';

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
  List<List<dynamic>> _excelData = [];
  List<List<dynamic>> _filteredData = [];
  List<List<dynamic>> _mergedData = [];
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

      print('Tổng số dòng trong file: ${sheet.rows.length}');

      // Lấy header và tìm vị trí các cột cần thiết
      final headers = sheet.rows.first.map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '').toList();
      print('Headers: $headers');

      final productIndex = headers.indexWhere((h) => h.contains('product'));
      final unitIndex = headers.indexWhere((h) => h.contains('đơn vị tính'));
      final quantityIndex = headers.indexWhere((h) => h.contains('số lượng'));
      final toImportIndex = headers.indexWhere((h) => h.contains('to import'));
      final unitPriceIndex = headers.indexWhere((h) => h.contains('đơn giá'));
      print('Đơn giá: $unitPriceIndex');

      print('Vị trí các cột:');
      print('Product: $productIndex');
      print('Đơn vị tính: $unitIndex');
      print('Số lượng: $quantityIndex');
      print('To import: $toImportIndex');

      if (productIndex == -1 || unitIndex == -1 || quantityIndex == -1 || toImportIndex == -1) {
        throw Exception('Không tìm thấy một hoặc nhiều cột cần thiết (Product, Đơn vị tính, Số lượng, To import)');
      }

      // Đọc dữ liệu và lọc theo To import = true
      final Map<String, List<dynamic>> mergedProducts = {};
      final Map<String, double> mergedTotalAmount = {};
      int rowCount = 0;
      int skippedRows = 0;
      int invalidToImport = 0;
      int emptyNameOrUnit = 0;
      int invalidQuantity = 0;

      // Đếm số lần xuất hiện của mỗi sản phẩm
      final Map<String, int> productAppearCount = {};
      for (var row in sheet.rows.skip(1)) {
        if (row.length <= toImportIndex) {
          print('Dòng [1m${rowCount + 1}[0m: Không đủ cột (${row.length} < $toImportIndex)');
          skippedRows++;
          continue;
        }

        final toImport = row[toImportIndex]?.value?.toString().trim().toLowerCase() ?? '';
        if (toImport != 'true') {
          invalidToImport++;
          continue;
        }

        final name = row[productIndex]?.value?.toString().trim() ?? '';
        // Bỏ qua nếu tên sản phẩm rỗng hoặc bằng '0'
        if (name.isEmpty || name == '0') {
          print('Dòng [1m${rowCount + 1}[0m: Tên sản phẩm trống hoặc bằng 0 (name="$name")');
          emptyNameOrUnit++;
          continue;
        }
        final unit = row[unitIndex]?.value?.toString().trim() ?? '';
        final quantityStr = row[quantityIndex]?.value?.toString().replaceAll(',', '') ?? '';
        final quantity = double.tryParse(quantityStr) ?? 0;

        if (name.isEmpty) {
          print('Dòng ${rowCount + 1}: Tên sản phẩm trống');
          emptyNameOrUnit++;
          continue;
        }

        // Loại bỏ text trong dấu ngoặc đơn
        final cleanName = name.replaceAll(RegExp(r'\([^)]*\)'), '').trim();

        // Nếu đơn vị tính trống thì để '', số lượng không hợp lệ thì để 0
        final unitPriceStr = unitPriceIndex != -1 && row.length > unitPriceIndex ? row[unitPriceIndex]?.value?.toString().replaceAll(',', '') ?? '' : '';
        final unitPrice = double.tryParse(unitPriceStr) ?? 0;

        if (!mergedProducts.containsKey(cleanName)) {
          mergedProducts[cleanName] = [cleanName, unit, quantity];
          mergedTotalAmount[cleanName] = unitPrice * quantity;
        } else {
          mergedProducts[cleanName]![2] = (mergedProducts[cleanName]![2] as double) + quantity;
          mergedTotalAmount[cleanName] = (mergedTotalAmount[cleanName] ?? 0) + unitPrice * quantity;
        }
        rowCount++;

        if (cleanName.isNotEmpty && cleanName != '0') {
          productAppearCount[cleanName] = (productAppearCount[cleanName] ?? 0) + 1;
        }
      }

      print('\nThống kê đọc file:');
      print('Tổng số dòng: [1m${sheet.rows.length}[0m');
      print('Số dòng bỏ qua (không đủ cột): $skippedRows');
      print('Số dòng không có To import = true: $invalidToImport');
      print('Số dòng tên/đơn vị tính trống: $emptyNameOrUnit');
      print('Số dòng số lượng không hợp lệ: $invalidQuantity');
      print('Số dòng hợp lệ: $rowCount');
      print('Số sản phẩm sau khi gộp: ${mergedProducts.length}');

      if (mergedProducts.isEmpty) {
        throw Exception('Không tìm thấy dữ liệu hợp lệ trong file Excel');
      }

      // Khi tạo _mergedData, nếu sản phẩm chỉ có 1 dòng thì đơn giá giữ nguyên, nếu nhiều dòng thì tính trung bình gia quyền
      _mergedData = mergedProducts.values.map((row) {
        final name = row[0].toString();
        final totalQuantity = (row[2] as double);
        final totalAmount = mergedTotalAmount[name] ?? 0;
        final count = productAppearCount[name] ?? 1;
        double avgCostPrice;
        if (count == 1) {
          avgCostPrice = totalQuantity > 0 ? (totalAmount / totalQuantity) : 0;
        } else {
          avgCostPrice = totalQuantity > 0 ? (totalAmount / totalQuantity) : 0;
        }
        return [row[0], row[1], row[2], avgCostPrice];
      }).toList();

      setState(() {
        _mergedData = _mergedData;
        _status = 'Đã lọc và gộp ${_mergedData.length} sản phẩm từ $rowCount dòng hợp lệ (Tổng: ${sheet.rows.length} dòng)';
        _isLoading = false;
        _isLoadingFile = false;
      });

    } catch (e) {
      print('Lỗi khi đọc file: $e');
      setState(() {
        _status = 'Lỗi khi đọc file: $e';
        _isLoading = false;
        _isLoadingFile = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingFile = false;
      });
    }
  }

  Future<void> filterData() async {
    if (_excelData.isEmpty) {
      setState(() => _status = 'Không có dữ liệu để lọc');
      return;
    }

    setState(() {
      _status = 'Đang lọc dữ liệu...';
      _mergedData = [];
    });

    try {
      // Tạo map để gộp các sản phẩm trùng tên
      final Map<String, List<dynamic>> mergedProducts = {};

      // Lọc và gộp dữ liệu
      for (var row in _excelData) {
        if (row.length < 3) continue;

        final name = row[0].toString().trim();
        final unit = row[1].toString().trim();
        final quantity = double.tryParse(row[2].toString().replaceAll(',', '')) ?? 0;

        if (name.isEmpty || unit.isEmpty) continue;

        if (!mergedProducts.containsKey(name)) {
          mergedProducts[name] = [name, unit, quantity];
        } else {
          // Cộng dồn số lượng cho sản phẩm trùng tên
          mergedProducts[name]![2] = (mergedProducts[name]![2] as double) + quantity;
        }
      }

      // Chuyển map thành list
      _mergedData = mergedProducts.values.toList();

      setState(() {
        _status = 'Đã lọc và gộp ${_mergedData.length} sản phẩm';
      });
    } catch (e) {
      setState(() {
        _status = 'Lỗi khi lọc dữ liệu: $e';
      });
    }
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
        allProducts[doc['commonName'] as String] = doc;
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
          final name = row[0].toString();
          final unit = row[1].toString();
          final quantity = double.tryParse(row[2].toString()) ?? 0;
          final costPrice = double.tryParse(row[3].toString()) ?? 0;

          try {
            if (allProducts.containsKey(name)) {
              final doc = allProducts[name]!;
              final currentStock = (doc['stock'] ?? 0).toDouble();
              batch.update(doc.reference, {
                'stock': currentStock + quantity,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              updatedCount++;
            } else {
              final productData = {
                'name': name,
                'commonName': name,
                'unit': unit,
                'stock': quantity,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
                'category': 'Khác',
                'description': '',
                'usage': '',
                'ingredients': '',
                'notes': '',
                'salePrice': 0,
                'isActive': true,
                'tags': [],
                'cost_price': costPrice,
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
    } catch (e) {
      setState(() {
        _isImporting = false;
        _status = 'Lỗi khi import: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tạo danh sách tên sản phẩm bị ghép
    final Set<String> mergedNames = {};
    final Map<String, int> nameCount = {};
    for (var row in _mergedData) {
      final name = row[0].toString();
      nameCount[name] = (nameCount[name] ?? 0) + 1;
    }
    nameCount.forEach((name, count) {
      if (count > 1) mergedNames.add(name);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import data'),
      ),
      body: Padding(
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
                            final isMerged = mergedNames.contains(row[0].toString());
                            return DataRow(
                              color: isMerged ? MaterialStateProperty.all(Colors.yellow[100]) : null,
                              cells: [
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row[0].toString())))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row[1].toString())))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row[2].toString())))),
                                DataCell(SizedBox(width: colWidth, child: Align(alignment: Alignment.centerLeft, child: Text(row.length > 3 ? row[3].toStringAsFixed(0) : '0')))),
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
          ],
        ),
      ),
    );
  }
} 