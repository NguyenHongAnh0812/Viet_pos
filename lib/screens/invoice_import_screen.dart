import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/product_service.dart';

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

  Future<void> readExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) return;

      setState(() {
        _status = 'Đang đọc file...';
        _excelData = [];
        _filteredData = [];
        _mergedData = [];
        _showFilteredData = false;
        _showMergedData = false;
      });

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        setState(() => _status = 'Không thể đọc file');
        return;
      }

      final excelFile = Excel.decodeBytes(bytes);
      final sheet = excelFile.tables.keys.first;
      final rows = excelFile.tables[sheet]!.rows;

      if (rows.isEmpty) {
        setState(() => _status = 'File không có dữ liệu');
        return;
      }

      // Chuyển đổi dữ liệu Excel thành List
      _excelData = rows.map((row) {
        return row.map((cell) => cell?.value?.toString() ?? '').toList();
      }).toList();

      // In thông tin chi tiết
      print('\n=== THÔNG TIN FILE EXCEL ===');
      print('Tên file: ${result.files.first.name}');
      print('Số dòng: ${_excelData.length}');
      print('Số cột: ${_excelData.isNotEmpty ? _excelData[0].length : 0}');
      
      print('\n=== DỮ LIỆU EXCEL ===');
      for (var i = 0; i < _excelData.length; i++) {
        print('Dòng ${i + 1}: ${_excelData[i]}');
      }

      setState(() {
        _status = 'Đã đọc ${_excelData.length} dòng từ file';
      });

    } catch (e) {
      print('Error reading Excel file: $e');
      setState(() {
        _status = 'Lỗi khi đọc file: $e';
      });
    }
  }

  void filterData() {
    if (_excelData.isEmpty) return;

    // Tìm vị trí các cột cần lọc
    final headers = _excelData[0];
    final dienGiaiIndex = headers.indexWhere((h) => h.toString().contains('Tên thương mại'));
    final donViTinhIndex = headers.indexWhere((h) => h.toString().contains('Đơn vị tính'));
    final soLuongIndex = headers.indexWhere((h) => h.toString().contains('Số lượng'));
    final toImportIndex = headers.indexWhere((h) => h.toString().contains('To import'));

    if (dienGiaiIndex == -1 || donViTinhIndex == -1 || soLuongIndex == -1 || toImportIndex == -1) {
      setState(() {
        _status = 'Không tìm thấy một hoặc nhiều cột cần thiết (Tên thương mại, Đơn vị tính, Số lượng, To import)';
      });
      return;
    }

    // Lọc dữ liệu và loại bỏ tiêu đề
    _filteredData = _excelData.skip(1).where((row) {
      if (row.length <= dienGiaiIndex || row.length <= donViTinhIndex || row.length <= soLuongIndex || row.length <= toImportIndex) {
        return false;
      }
      final toImport = row[toImportIndex]?.toString().trim().toLowerCase() ?? '';
      return toImport == 'true' && row[dienGiaiIndex]?.toString().trim().isNotEmpty == true;
    }).map((row) {
      // Loại bỏ text trong dấu ngoặc đơn
      String dienGiai = row[dienGiaiIndex]?.toString().trim() ?? '';
      dienGiai = dienGiai.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
      
      return [
        dienGiai,
        row[donViTinhIndex]?.toString() ?? '',
        row[soLuongIndex]?.toString() ?? '',
      ];
    }).toList();

    // Gộp các sản phẩm trùng tên
    final Map<String, List<dynamic>> mergedMap = {};
    for (var row in _filteredData) {
      final name = row[0].toString();
      final unit = row[1].toString();
      final quantity = double.tryParse(row[2].toString().replaceAll(',', '')) ?? 0;

      if (mergedMap.containsKey(name)) {
        // Cập nhật số lượng nếu đã tồn tại
        final existingRow = mergedMap[name]!;
        final existingQuantity = double.tryParse(existingRow[2].toString().replaceAll(',', '')) ?? 0;
        existingRow[2] = (existingQuantity + quantity).toString();
      } else {
        // Thêm mới nếu chưa tồn tại
        mergedMap[name] = [name, unit, quantity.toString()];
      }
    }

    _mergedData = mergedMap.values.toList();

    setState(() {
      _showFilteredData = true;
      _showMergedData = true;
      _status = 'Đã lọc được ${_filteredData.length} dòng, gộp thành ${_mergedData.length} sản phẩm';
    });

    // In dữ liệu đã lọc và gộp
    print('\n=== DỮ LIỆU ĐÃ LỌC VÀ GỘP ===');
    print('Tên thương mại | Đơn vị tính | Số lượng');
    for (var row in _mergedData) {
      print('${row[0]} | ${row[1]} | ${row[2]}');
    }
  }

  Future<void> importToFirebase() async {
    if (_mergedData.isEmpty) {
      setState(() => _status = 'Không có dữ liệu để import');
      return;
    }

    setState(() {
      _isImporting = true;
      _status = 'Đang import dữ liệu...';
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final productsRef = FirebaseFirestore.instance.collection('products');

      for (var row in _mergedData) {
        final productData = {
          'commonName': row[0].toString(),
          'unit': row[1].toString(),
          'invoiceStock': double.tryParse(row[2].toString().replaceAll(',', '')) ?? 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          // Các trường khác để trống
          'name': '',
          'code': '',
          'barcode': '',
          'category': '',
          'description': '',
          'price': 0,
          'cost': 0,
          'minStock': 0,
          'maxStock': 0,
          'supplier': '',
          'location': '',
          'status': 'active',
          'images': [],
          'tags': [],
        };

        // Tạo document mới với ID tự động
        final docRef = productsRef.doc();
        batch.set(docRef, productData);
      }

      // Commit batch
      await batch.commit();

      setState(() {
        _status = 'Đã import thành công ${_mergedData.length} sản phẩm';
      });

      // Quay lại trang trước (danh sách sản phẩm)
      if (mounted) {
        Navigator.pop(context);
      }

      // In thông tin chi tiết về quá trình import
      print('\n=== THÔNG TIN IMPORT ===');
      print('Số lượng sản phẩm đã import: ${_mergedData.length}');
      for (var row in _mergedData) {
        print('Đã import: ${row[0]} (${row[1]}) - Số lượng: ${row[2]}');
      }

    } catch (e) {
      print('Error importing to Firebase: $e');
      setState(() {
        _status = 'Lỗi khi import: $e';
      });
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đọc File Excel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_status),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: readExcelFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Chọn file Excel'),
                ),
                const SizedBox(width: 16),
                if (_excelData.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: filterData,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Tạo sản phẩm từ bộ lọc'),
                  ),
                const SizedBox(width: 16),
                if (_mergedData.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _isImporting ? null : importToFirebase,
                    icon: const Icon(Icons.save),
                    label: Text(_isImporting ? 'Đang import...' : 'Import vào DB'),
                  ),
              ],
            ),
            if (_excelData.isNotEmpty && !_showFilteredData) ...[
              const SizedBox(height: 16),
              const Text('Dữ liệu gốc:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: _excelData.isNotEmpty
                          ? List.generate(
                              _excelData[0].length,
                              (index) => DataColumn(
                                label: Text('Cột ${index + 1}'),
                              ),
                            )
                          : [],
                      rows: _excelData.map((row) {
                        return DataRow(
                          cells: row.map((cell) {
                            return DataCell(Text(cell.toString()));
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
            if (_showFilteredData && !_showMergedData) ...[
              const SizedBox(height: 16),
              const Text('Dữ liệu đã lọc:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Tên thương mại')),
                        DataColumn(label: Text('Đơn vị tính')),
                        DataColumn(label: Text('Số lượng')),
                      ],
                      rows: _filteredData.map((row) {
                        return DataRow(
                          cells: row.map((cell) {
                            return DataCell(Text(cell.toString()));
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
            if (_showMergedData) ...[
              const SizedBox(height: 16),
              const Text('Dữ liệu đã gộp:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Tên thương mại')),
                        DataColumn(label: Text('Đơn vị tính')),
                        DataColumn(label: Text('Số lượng')),
                      ],
                      rows: _mergedData.map((row) {
                        // Kiểm tra xem sản phẩm này có bị gộp không
                        final isMerged = _filteredData.where((r) => r[0] == row[0]).length > 1;
                        
                        return DataRow(
                          color: isMerged ? MaterialStateProperty.all(Colors.yellow.shade100) : null,
                          cells: [
                            DataCell(
                              Text(
                                row[0].toString(),
                                style: TextStyle(
                                  fontWeight: isMerged ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            DataCell(Text(row[1].toString())),
                            DataCell(
                              Text(
                                row[2].toString(),
                                style: TextStyle(
                                  fontWeight: isMerged ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 