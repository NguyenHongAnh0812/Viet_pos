import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../models/inventory_session.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/design_system.dart';

class InventoryHistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const InventoryHistoryScreen({super.key, this.onBack});

  @override
  State<InventoryHistoryScreen> createState() => _InventoryHistoryScreenState();
}

class _InventoryHistoryScreenState extends State<InventoryHistoryScreen> {
  final _inventoryService = InventoryService();
  int? _selectedYear;
  int? _selectedMonth;
  String _search = '';
  final _searchController = TextEditingController();
  final Map<String, bool> _expandedMap = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 1400),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 4),
                  const Text('Lịch sử kiểm kê', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Xem các phiên kiểm kê trước đây', style: TextStyle(color: textSecondary)),
              const SizedBox(height: 20),
              designSystemCard(
                child: _buildFilterPanel(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: designSystemCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSessionList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    final now = DateTime.now();
    final years = List.generate(6, (i) => now.year - i);
    final months = List.generate(12, (i) => i + 1);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_today, size: 20, color: Colors.black54),
              SizedBox(width: 8),
              Text('Lọc theo thời gian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedYear,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả các năm')),
                    ...years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))),
                  ],
                  onChanged: (v) => setState(() => _selectedYear = v),
                  decoration: const InputDecoration(labelText: 'Năm', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedMonth,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả các tháng')),
                    ...months.map((m) => DropdownMenuItem(value: m, child: Text('Tháng $m'))),
                  ],
                  onChanged: (v) => setState(() => _selectedMonth = v),
                  decoration: const InputDecoration(labelText: 'Tháng', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Tìm kiếm',
                    hintText: 'Tìm kiếm phiên kiểm kê...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String getQuarter(DateTime date) {
    final month = date.month;
    if (month <= 3) return 'Quý 1';
    if (month <= 6) return 'Quý 2';
    if (month <= 9) return 'Quý 3';
    return 'Quý 4';
  }

  Widget _buildSessionList() {
    return StreamBuilder<List<InventorySession>>(
      stream: _inventoryService.getAllSessions(),
      builder: (context, snapshot) {
        final sessions = (snapshot.data ?? [])
            .where((s) {
              final matchYear = _selectedYear == null || s.createdAt.year == _selectedYear;
              final matchMonth = _selectedMonth == null || s.createdAt.month == _selectedMonth;
              final matchSearch = _search.isEmpty || s.note.toLowerCase().contains(_search.toLowerCase());
              return matchYear && matchMonth && matchSearch;
            })
            .toList();
        if (sessions.isEmpty) {
          return const Center(child: Text('Không có phiên kiểm kê nào.', style: TextStyle(color: Colors.black54)));
        }
        return ListView.separated(
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, i) => _buildSessionPanel(sessions[i]),
        );
      },
    );
  }

  void _showExportSuccess(BuildContext context) {
    final overlay = Overlay.of(context);
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => DesignSystemSnackbar(
        message: 'Xuất dữ liệu thành công',
        icon: Icons.check_circle,
        onDismissed: () => entry?.remove(),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry?.remove());
  }

  Widget _buildSessionPanel(InventorySession session) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(session.createdAt);
    final diffCount = session.products.where((p) => p.diff != 0).length;
    final expanded = _expandedMap[session.id] ?? false;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () {
              setState(() {
                _expandedMap[session.id] = !expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kiểm kê ngày $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 2),
                        Text('${session.products.length} sản phẩm', style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  if (diffCount > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 12, top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text('Có chênh lệch', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(width: 8),
                  Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 28, color: Colors.black54),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Xuất dữ liệu'),
                      onPressed: () {
                        _showExportSuccess(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (session.note.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6EA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ghi chú:', style: TextStyle(color: Colors.pink[800], fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(session.note, style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),
                  const Text('Danh sách sản phẩm kiểm kê:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...session.products.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: Text('Hệ thống', style: TextStyle(color: Colors.black54))),
                            Expanded(child: Text('Thực tế', style: TextStyle(color: Colors.black54))),
                            Expanded(child: Text('Chênh lệch', style: TextStyle(color: Colors.black54))),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: Text('${p.systemQty}', style: const TextStyle(fontWeight: FontWeight.w500))),
                            Expanded(child: Text('${p.actualQty}', style: const TextStyle(fontWeight: FontWeight.w500))),
                            Expanded(child: Text('${p.diff > 0 ? '+' : ''}${p.diff}', style: TextStyle(color: p.diff == 0 ? Colors.black : Colors.red, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
} 