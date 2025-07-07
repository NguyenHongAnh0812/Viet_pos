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
  String _search = '';
  final _searchController = TextEditingController();
  int _tabIndex = 0;
  final List<String> _tabs = ['Tất cả', 'Phiếu tạm', 'Đã kiểm kê', 'Đã cập nhật tồn kho'];
  DateTime? _selectedDate;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
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
                    onPressed: _showDatePicker,
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
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            // Tab filter
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_tabs.length, (i) {
                  final selected = _tabIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF16A34A) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _tabs[i],
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF16A34A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                  final sessions = (snapshot.data ?? [])
                      .where((s) {
                        final matchSearch = _search.isEmpty || s.note.toLowerCase().contains(_search.toLowerCase());
                        // Lọc theo tab
                        if (_tabIndex == 1) return s.status == 'draft' && matchSearch;
                        if (_tabIndex == 2) return s.status == 'checked' && matchSearch;
                        if (_tabIndex == 3) return s.status == 'updated' && matchSearch;
                        return matchSearch;
                      })
                      .toList();
                  if (sessions.isEmpty) {
                    return const Center(child: Text('Không có phiên kiểm kê nào.', style: TextStyle(color: Colors.black54)));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) => _buildSessionCard(sessions[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(InventorySession session) {
    final dateStr = DateFormat('d/M/yyyy').format(session.createdAt);
    final percent = session.totalCount == 0 ? 0 : (session.checkedCount / session.totalCount * 100).round();
    Color chipColor;
    String chipText;
    if (session.status == 'updated') {
      chipColor = const Color(0xFF16A34A);
      chipText = 'Đã cập nhật tồn kho';
    } else if (session.status == 'checked') {
      chipColor = const Color(0xFF2563eb);
      chipText = 'Đã kiểm kê';
    } else {
      chipColor = const Color(0xFF9CA3AF);
      chipText = 'Phiếu tạm';
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(session.note, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  chipText,
                  style: TextStyle(color: chipColor, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text('Ngày tạo: $dateStr', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.person, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text('Người tạo: ${session.createdBy}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Tiến độ: ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              Text('${session.checkedCount}/${session.totalCount} sản phẩm ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('($percent%)', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: session.totalCount == 0 ? 0 : session.checkedCount / session.totalCount,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(chipColor),
            ),
          ),
        ],
      ),
    );
  }
} 