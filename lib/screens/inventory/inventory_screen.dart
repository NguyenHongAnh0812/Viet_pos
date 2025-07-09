import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';

import '../../services/product_category_service.dart';

import '../../services/product_service.dart';

import '../../models/product.dart';
import '../../models/inventory_session.dart';

import 'inventory_create_session_screen.dart';

import '../../widgets/main_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/design_system.dart';
import '../../utils/inventory_status_mapper.dart';
import 'inventory_detail_screen.dart';
import 'inventory_confirm_screen.dart';
import 'inventory_history_screen.dart';

class InventoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onViewHistory;
  const InventoryScreen({super.key, this.onBack, this.onViewHistory});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  final List<String> _tabs = ['Tất cả', 'Phiếu tạm', 'Đã kiểm kê', 'Đã cập nhật tồn kho'];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  // TODO: Replace with real data/models
  final List<Map<String, dynamic>> _products = [
    {'name': 'Amoxicillin 250mg', 'commonName': 'Amoxicillin', 'systemQty': 120, 'actualQty': null, 'checked': false},
    {'name': 'Enrofloxacin 50mg', 'commonName': 'Enrofloxacin', 'systemQty': 5, 'actualQty': null, 'checked': false},
    {'name': 'Meloxicam 1.5mg', 'commonName': 'Meloxicam', 'systemQty': 80, 'actualQty': null, 'checked': false},
    {'name': 'Miconazole Cream 2%', 'commonName': 'Miconazole', 'systemQty': 3, 'actualQty': null, 'checked': false},
    {'name': 'Vitamin B Complex', 'commonName': 'B Complex', 'systemQty': 45, 'actualQty': null, 'checked': false},
  ];
  bool _saving = false;
  final bool _showHistory = false;
  final bool _showFilter = false;
  String? _selectedCategory;
  final String _selectedStatus = 'Tất cả trạng thái';
  final List<String> _categoryOptions = ['Tất cả danh mục', 'Kháng sinh', 'Vitamin', 'Khác']; // TODO: lấy từ service thực tế
  final List<String> _statusOptions = ['Tất cả trạng thái', 'Chưa kiểm kê', 'Đã kiểm kê', 'Lệch số lượng'];
  final _inventoryService = InventoryService();
  final _categoryService = ProductCategoryService();
  final _productService = ProductService();
  final List<Map<String, dynamic>> _scannedProducts = [];
  final Map<String, String> _actualQtyMap = {};
  // Thêm biến để bật/tắt tính năng đồng bộ số lượng thực tế
  final bool _syncStock = false;
  final Map<String, TextEditingController> _qtyControllers = {};
  // Thêm biến để theo dõi trạng thái đã lưu
  final Map<String, bool> _savedProducts = {};
  DateTime? _selectedDate;
  int _selectedTimeFilter = 4; // 0: all, 1: today, 2: yesterday, 3: 7days, 4: this month, 5: last month, 6: custom
  DateTimeRange? _customRange;
  final List<String> _timeFilters = [
    'Toàn thời gian',
    'Hôm nay',
    'Hôm qua',
    '7 ngày qua',
    'Tháng này',
    'Tháng trước',
    'Tuỳ chỉnh',
  ];
  bool _hasActiveSession = false;

  void _showDatePicker() async {
    final picked = await showModalBottomSheet<DateTime?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        DateTime tempDate = _selectedDate ?? DateTime.now();
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Chọn ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                CalendarDatePicker(
                  initialDate: tempDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  onDateChanged: (date) {
                    tempDate = date;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, tempDate),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                        child: const Text('Chọn', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showTimeFilterPanel() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lọc theo thời gian', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    ...List.generate(_timeFilters.length, (i) => ListTile(
                      title: Text(_timeFilters[i], style: const TextStyle(fontSize: 15)),
                      trailing: _selectedTimeFilter == i ? const Icon(Icons.check, color: Color(0xFF16A34A)) : null,
                      onTap: () => Navigator.pop(context, i),
                    )),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (selected != null) {
      if (selected == 6) {
        // Tuỳ chỉnh: show date range picker
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
          initialDateRange: _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
        );
        if (picked != null) {
          setState(() {
            _selectedTimeFilter = selected;
            _customRange = picked;
          });
        }
      } else {
        setState(() {
          _selectedTimeFilter = selected;
        });
      }
    }
  }

  bool _matchTimeFilter(DateTime date) {
    final now = DateTime.now();
    switch (_selectedTimeFilter) {
      case 1: // Hôm nay
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case 2: // Hôm qua
        final yesterday = now.subtract(const Duration(days: 1));
        return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
      case 3: // 7 ngày qua
        return date.isAfter(now.subtract(const Duration(days: 7))) && date.isBefore(now.add(const Duration(days: 1)));
      case 4: // Tháng này
        return date.year == now.year && date.month == now.month;
      case 5: // Tháng trước
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return date.year == lastMonth.year && date.month == lastMonth.month;
      case 6: // Tuỳ chỉnh
        if (_customRange == null) return true;
        return date.isAfter(_customRange!.start.subtract(const Duration(days: 1))) && date.isBefore(_customRange!.end.add(const Duration(days: 1)));
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      floatingActionButton: FloatingActionButton(
        backgroundColor: mainGreen,
        elevation: 8,
        onPressed: () async {
          // Kiểm tra trực tiếp trên Firestore
          final snapshot = await FirebaseFirestore.instance
              .collection('inventory_sessions')
              .where('status', whereIn: ['draft', 'checked'])
              .limit(1)
              .get();
          if (snapshot.docs.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chỉ được phép có 1 phiên kiểm kê ở trạng thái nháp hoặc đang kiểm kê!')),
            );
            return;
          }
          // Nếu không có, cho phép tạo mới
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InventoryCreateSessionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        shape: const CircleBorder(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Column(
            children: [
              // AppBar xanh
              Container(
                color: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Kiểm kê kho', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.white),
                      onPressed: _showTimeFilterPanel,
                    ),
                  ],
                ),
              ),
              // Search box
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên phiếu kiểm kê để tìm kiếm',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: const Color(0xFFF6F7F8),
                  ),
                  onChanged: (v) => setState(() {}),
                ),
              ),
              // Tab filter
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(_tabs.length, (i) {
                    final selected = _tabIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => _tabIndex = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _tabs[i],
                              style: TextStyle(
                                color: selected ? const Color(0xFF16A34A) : const Color(0xFF374151),
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (selected)
                              Container(
                                height: 2,
                                width: 32,
                                color: const Color(0xFF16A34A),
                              )
                            else
                              const SizedBox(height: 2),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Danh sách kiểm kê
              Expanded(
                child: StreamBuilder<List<InventorySession>>(
                  stream: _inventoryService.getAllSessions(),
                  builder: (context, snapshot) {
                    final allSessions = snapshot.data ?? [];
                    // Kiểm tra có phiên active không trên toàn bộ session
                    _hasActiveSession = allSessions.any((s) => s.status == 'draft' || s.status == 'checked');
                    // Sau đó mới filter theo tab để hiển thị
                    final sessions = allSessions.where((s) {
                          final matchSearch = _searchController.text.isEmpty || s.note.toLowerCase().contains(_searchController.text.toLowerCase());
                          final matchTime = _matchTimeFilter(s.createdAt);
                          // Lọc theo tab
                          if (_tabIndex == 1) return s.status == 'draft' && matchSearch && matchTime;
                          if (_tabIndex == 2) return s.status == 'checked' && matchSearch && matchTime;
                          if (_tabIndex == 3) return s.status == 'updated' && matchSearch && matchTime;
                          return matchSearch && matchTime;
                    }).toList();
                    if (sessions.isEmpty) {
                      return const Center(child: Text('Không có phiên kiểm kê nào.', style: TextStyle(color: Colors.black54)));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) => _buildInventoryCard(context, sessions[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, InventorySession session) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('inventory_items')
          .where('session_id', isEqualTo: session.id)
          .get(),
      builder: (context, snapshot) {
        int totalCount = 0;
        int checkedCount = 0;
        if (snapshot.hasData) {
          final items = snapshot.data!.docs;
          totalCount = items.length;
          checkedCount = items.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['checked'] ?? false) == true;
          }).length;
        }
        final percent = totalCount == 0 ? 0 : (checkedCount / totalCount * 100).round();
        // Xác định màu và icon trạng thái
        String chipText = InventoryStatusMapper.getStatusDisplayText(session.status);
        Color chipColor;
        IconData chipIcon;
        if (session.status == 'updated') {
          chipColor = const Color(0xFF16A34A);
          chipIcon = Icons.check_circle;
        } else if (session.status == 'checked') {
          chipColor = const Color(0xFF2563eb);
          chipIcon = Icons.assignment_turned_in;
        } else {
          chipColor = const Color(0xFF9CA3AF);
          chipIcon = Icons.insert_drive_file;
        }
        return GestureDetector(
          onTap: () {
            final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
            if (mainLayoutState != null) {
              if (session.status == 'updated') {
                mainLayoutState.openInventoryHistory(session.id);
              } else if (session.status == 'checked') {
                mainLayoutState.openInventoryConfirm(session.id);
              } else {
                mainLayoutState.openInventoryDetail(session.id);
              }
            } else {
              if (session.status == 'updated') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InventoryHistoryScreen(sessionId: session.id),
                  ),
                );
              } else if (session.status == 'checked') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InventoryConfirmScreen(sessionId: session.id),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InventoryDetailScreen(sessionId: session.id),
                  ),
                );
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.note.isNotEmpty ? session.note : 'Phiên kiểm kê',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF222B45)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: chipColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(chipIcon, color: chipColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            chipText,
                            style: TextStyle(color: chipColor, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text('Ngày tạo: ${session.createdAt.day}/${session.createdAt.month}/${session.createdAt.year}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text('Người tạo: ${session.createdBy}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Tiến độ: ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    Text('$checkedCount/$totalCount sản phẩm ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('($percent%)', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: totalCount == 0 ? 0 : checkedCount / totalCount,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có sản phẩm nào để kiểm kê',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code_scanner_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có sản phẩm nào được quét',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(p['commonName'], style: const TextStyle(fontSize: 13, color: Colors.black54)),
                if (p['actualQty'] == null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Chưa kiểm kê', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500, fontSize: 12)),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Text('${p['systemQty']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          SizedBox(
            width: 140,
            child: TextFormField(
              initialValue: p['actualQty']?.toString() ?? '',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
              onChanged: (v) {
                setState(() {
                  p['actualQty'] = int.tryParse(v);
                  p['checked'] = v.isNotEmpty;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return StreamBuilder<List<InventorySession>>(
      stream: _inventoryService.getSessionsByMonth(DateTime.now()),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return const Text('Chưa có lịch sử kiểm kê tháng này.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sessions.map((s) => ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text('${s.createdAt.day.toString().padLeft(2, '0')}/${s.createdAt.month.toString().padLeft(2, '0')}/${s.createdAt.year} - ${s.createdBy}'),
            subtitle: Text('${s.products.length} sản phẩm, ${s.products.where((p) => p.diff != 0).length} sản phẩm lệch số lượng'),
            trailing: TextButton(
              onPressed: () => _showSessionDetail(context, s),
              child: const Text('Xem chi tiết'),
            ),
          )).toList(),
        );
      },
    );
  }

  Future<void> _saveInventorySession() async {
    setState(() => _saving = true);
    final now = DateTime.now();
    // Lấy danh sách sản phẩm thực tế
    final products = await _productService.getProducts().first;
    final sessionProducts = <InventoryProduct>[];
    for (final p in products) {
      final actualStr = _actualQtyMap[p.id];
      final actualQty = int.tryParse(actualStr ?? '') ?? 0;
      sessionProducts.add(InventoryProduct(
        productId: p.id,
        name: p.tradeName,
        systemQty: p.stockSystem,
        actualQty: actualQty,
        diff: actualQty - p.stockSystem,
      ));
      if (_syncStock && actualStr != null && actualStr.isNotEmpty) {
        await _productService.updateProduct(p.id, p.copyWith(stockSystem: actualQty));
      }
    }
    final session = InventorySession(
      id: '',
      createdAt: now,
      createdBy: 'Chủ cửa hàng', // TODO: lấy user thực tế nếu có auth
      note: _noteController.text.trim(),
      products: sessionProducts,
      status: 'updated',
    );
    await _inventoryService.addSession(session);
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu phiên kiểm kê!')));
  }

  void _showSessionDetail(BuildContext context, InventorySession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Phiên kiểm kê ${session.createdAt.day.toString().padLeft(2, '0')}/${session.createdAt.month.toString().padLeft(2, '0')}/${session.createdAt.year}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Người thực hiện: ${session.createdBy}'),
              Text('Ghi chú: ${session.note}'),
              const SizedBox(height: 8),
              const Text('Sản phẩm kiểm kê:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...session.products.map((p) => Row(
                children: [
                  Expanded(child: Text(p.name)),
                  Text('HT: ${p.systemQty}', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(width: 8),
                  Text('TT: ${p.actualQty}', style: const TextStyle(color: Colors.blue)),
                  const SizedBox(width: 8),
                  if (p.diff != 0)
                    Text('Lệch: ${p.diff > 0 ? '+' : ''}${p.diff}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  void _onFindBarcode() async {
    final code = _barcodeController.text.trim();
    if (code.isEmpty) return;
    // TODO: Tìm sản phẩm theo barcode từ Firestore
    // Hiện popup nhập số lượng, sau đó thêm vào _scannedProducts
    // Demo: thêm sản phẩm giả
    final demo = {
      'name': 'Demo Product',
      'commonName': 'Demo',
      'actualQty': 1,
    };
    final qty = await showDialog<int>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: '1');
        return AlertDialog(
          title: const Text('Nhập số lượng thực tế'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Số lượng'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, int.tryParse(controller.text) ?? 1),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
    if (qty != null) {
      setState(() {
        _scannedProducts.add({...demo, 'actualQty': qty});
        _barcodeController.clear();
      });
    }
  }

  Future<void> _saveProductQuantity(String productId, int newQuantity) async {
    try {
      // Lấy thông tin sản phẩm hiện tại
      final products = await _productService.getProducts().first;
      final product = products.firstWhere((p) => p.id == productId);
      
      // Tạo bản sao của sản phẩm với số lượng mới và cập nhật updatedAt
      final updatedProduct = product.copyWith(
        stockSystem: newQuantity,
        updatedAt: DateTime.now(),
      );
      
      // Cập nhật sản phẩm
      await _productService.updateProduct(productId, updatedProduct);
      
      setState(() {
        // Cập nhật UI sau khi lưu thành công
        _actualQtyMap[productId] = '$newQuantity';
        _savedProducts[productId] = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật số lượng thành công!')),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật số lượng: $e')),
      );
    }
  }

  void syncQtyController(String key, String value) {
    if (!_qtyControllers.containsKey(key) || _qtyControllers[key] == null) {
      _qtyControllers[key] = TextEditingController(text: value);
    } else if (_qtyControllers[key]!.text != value) {
      _qtyControllers[key]!.text = value;
      _qtyControllers[key]!.selection = TextSelection.collapsed(offset: value.length);
    }
  }
}

// Thêm widget popup tìm kiếm hiện đại
class _InventorySearchSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search, color: textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm phiên kiểm kê...',
                    border: InputBorder.none,
                  ),
                  style: h4,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // TODO: Hiển thị kết quả tìm kiếm
          Text('Nhập từ khoá để tìm kiếm phiên kiểm kê', style: bodySmall),
        ],
      ),
    );
  }
} 