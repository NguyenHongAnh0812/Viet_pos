import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'package:intl/intl.dart';
import '../add_product_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/design_system.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final void Function(Product)? onEdit;
  final VoidCallback? onBack;
  const ProductDetailScreen({Key? key, required this.product, this.onEdit, this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###', 'vi_VN');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(product.commonName, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                        ],
                      ),
                    ),
                    if (product.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('Đang hoạt động', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 32),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cột trái
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoBlockV2('Mã vạch', product.barcode ?? ''),
                          _infoBlockV2('SKU', product.sku ?? ''),
                          _infoBlockV2('Danh mục', product.category, bold: true),
                          _infoBlockV2('Đơn vị tính', product.unit),
                          const SizedBox(height: 8),
                          const Text('Tags', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: product.tags.map((tag) {
                              final isActiveTag = tag.toLowerCase() == 'đang hoạt động';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActiveTag ? const Color(0xFF3a6ff8) : Colors.transparent,
                                  border: Border.all(color: isActiveTag ? const Color(0xFF3a6ff8) : Colors.grey.shade300, width: 1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isActiveTag ? Colors.white : Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Cột phải
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoBlockV2('Số lượng tồn kho', '${product.stock}', bold: true),
                          _infoBlockV2('Giá nhập', '${numberFormat.format(product.importPrice)}đ'),
                          _infoBlockV2('Giá bán', '${numberFormat.format(product.salePrice)}đ', color: Colors.blue, bold: true),
                          _infoBlockV2('Ngày tạo', _formatDate(product.createdAt)),
                          _infoBlockV2('Cập nhật lần cuối', _formatDate(product.updatedAt)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 32),
                _infoBlock('Mô tả', product.description),
                _infoBlock('Công dụng', product.usage),
                _infoBlock('Thành phần', product.ingredients),
                _infoBlock('Ghi chú', product.notes),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (onEdit != null) {
                          onEdit!(product);
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Sửa sản phẩm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xác nhận xóa sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.name}"? Hành động này không thể hoàn tác.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        // Kiểm tra tồn kho
                        if (product.stock > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Không thể xóa sản phẩm còn tồn kho.')),
                          );
                          return;
                        }
                        // Giả lập kiểm tra đã từng kiểm kê/giao dịch (nếu có trường hasTransaction hoặc hasInventoryHistory)
                        final hasTransaction = false; // TODO: thay bằng logic thực tế nếu có
                        if (hasTransaction) {
                          // Chỉ cho ngừng hoạt động
                          await FirebaseFirestore.instance.collection('products').doc(product.id).update({'isActive': false});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sản phẩm đã được chuyển sang trạng thái ngừng hoạt động.')),
                          );
                          if (onBack != null) onBack!();
                          return;
                        }
                        // Xóa sản phẩm
                        await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xóa sản phẩm thành công!')),
                        );
                        if (onBack != null) onBack!();
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Xóa sản phẩm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: small.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: space4),
          Text(value, style: body),
        ],
      ),
    );
  }

  Widget _infoBlockV2(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: small.copyWith(fontWeight: FontWeight.w500, color: textSecondary)),
          const SizedBox(height: space2),
          Text(
            value,
            style: body.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('HH:mm dd/MM/yyyy').format(date);
  }
} 