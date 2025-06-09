import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as ex;
import 'dart:html' as html;
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/product_list_card.dart';
import '../screens/add_product_screen.dart';
import '../widgets/common/design_system.dart';

class LowStockProductsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final void Function(Product)? onEditProduct;
  const LowStockProductsScreen({super.key, this.onBack, this.onEditProduct});

  @override
  State<LowStockProductsScreen> createState() => _LowStockProductsScreenState();
}

class _LowStockProductsScreenState extends State<LowStockProductsScreen> {
  final _productService = ProductService();
  bool _exporting = false;

  Future<void> _exportToExcel(List<Product> products) async {
    setState(() => _exporting = true);
    final excel = ex.Excel.createExcel();
    final sheet = excel['Sheet1'];
    final headers = [
      'Tên danh pháp',
      'Tên thường gọi',
      'Danh mục',
      'Mã vạch',
      'SKU',
      'Tags',
      'Giá bán',
      'Số lượng',
    ];
    sheet.appendRow(headers);
    for (final p in products) {
      sheet.appendRow([
        p.name,
        p.commonName,
        p.category,
        p.barcode ?? '',
        p.sku ?? '',
        p.tags.join(', '),
        p.salePrice,
        p.stock,
      ]);
    }
    final fileBytes = excel.encode()!;
    final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'Danh sách sản phẩm sắp hết hàng.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
    setState(() => _exporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Báo cáo đã được tải xuống\nDanh sách sản phẩm sắp hết hàng.xlsx'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editProduct(Product product) async {
    if (widget.onEditProduct != null) {
      widget.onEditProduct!(product);
    }
  }

  void _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _productService.deleteProduct(product.id);
      OverlayEntry? entry;
      entry = OverlayEntry(
        builder: (_) => DesignSystemSnackbar(
          message: 'Đã xóa sản phẩm!',
          icon: Icons.check_circle,
          onDismissed: () => entry?.remove(),
        ),
      );
      Overlay.of(context).insert(entry);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack ?? () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Sản phẩm sắp hết hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
                    SizedBox(height: 2),
                    Text('Danh sách sản phẩm cần nhập thêm (số lượng < 60)', style: TextStyle(fontSize: 15, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _exporting ? null : () async {
                    final products = await _productService.getProducts().first;
                    final lowStock = products.where((p) => (p.stock ?? 0) < 60).toList();
                    await _exportToExcel(lowStock);
                  },
                  icon: const Icon(Icons.file_download),
                  label: const Text('Xuất báo cáo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0.5,
                    side: const BorderSide(color: Colors.black12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _productService.getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final products = (snapshot.data ?? []).where((p) => (p.stock ?? 0) < 60).toList();
                  if (products.isEmpty) {
                    return const Center(child: Text('Không có sản phẩm nào sắp hết hàng.'));
                  }
                  return ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, idx) {
                      final p = products[idx];
                      return ProductListCard(
                        product: p,
                        onEdit: () => _editProduct(p),
                        onDelete: () => _deleteProduct(p),
                        onTap: null,
                      );
                    },
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