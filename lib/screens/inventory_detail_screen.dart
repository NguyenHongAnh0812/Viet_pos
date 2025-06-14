import 'package:flutter/material.dart';
import '../models/inventory_session.dart';
import '../widgets/common/design_system.dart';

class InventoryDetailScreen extends StatefulWidget {
  final InventorySession session;
  const InventoryDetailScreen({Key? key, required this.session}) : super(key: key);

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  late List<TextEditingController> _actualControllers;
  late List<TextEditingController> _noteControllers;

  @override
  void initState() {
    super.initState();
    _actualControllers = widget.session.products.map((p) => TextEditingController(text: p.actualQty.toString())).toList();
    _noteControllers = widget.session.products.map((p) => TextEditingController()).toList();
  }

  int get diffCount => widget.session.products.where((p) => p.diff != 0).length;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: appBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Chi tiết kiểm kê', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin phiên kiểm kê
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.products.isNotEmpty ? session.products.first.name : '', style: h1),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Ngày kiểm kê', style: bodyLarge.copyWith(color: textSecondary)),
                          const SizedBox(width: 8),
                          Text('${session.createdAt.day}/${session.createdAt.month}/${session.createdAt.year}', style: bodyLarge.copyWith(color: textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Người kiểm kê', style: bodyLarge.copyWith(color: textSecondary)),
                          const SizedBox(width: 8),
                          Text(session.createdBy, style: bodyLarge.copyWith(color: textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Số sản phẩm', style: bodyLarge.copyWith(color: textSecondary)),
                          const SizedBox(width: 8),
                          Text('${session.products.length}', style: bodyLarge.copyWith(color: textPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(session.status, style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Số sản phẩm lệch', style: bodyLarge.copyWith(color: textSecondary)),
                        const SizedBox(width: 8),
                        Text('$diffCount', style: bodyLarge.copyWith(color: warningOrange, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (session.note.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mutedBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(session.note, style: bodyLarge.copyWith(color: textPrimary)),
              ),
            // Tìm kiếm
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search, color: textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: cardBackground,
              ),
            ),
            const SizedBox(height: 16),
            // Bảng sản phẩm kiểm kê
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: ListView.builder(
                  itemCount: session.products.length,
                  itemBuilder: (context, i) {
                    final p = session.products[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(p.name, style: bodyLarge.copyWith(color: textPrimary))),
                          Expanded(flex: 2, child: Text('${p.systemQty}', textAlign: TextAlign.center, style: bodyLarge)),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _actualControllers[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              ),
                            ),
                          ),
                          Expanded(flex: 2, child: Text('${p.diff}', textAlign: TextAlign.center, style: bodyLarge.copyWith(color: p.diff != 0 ? warningOrange : textPrimary))),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _noteControllers[i],
                              decoration: InputDecoration(
                                hintText: 'Ghi chú...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: secondaryButtonStyle,
                  child: const Text('Lưu nháp'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: primaryButtonStyle,
                  child: const Text('Hoàn tất kiểm kê'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 