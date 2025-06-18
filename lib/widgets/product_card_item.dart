import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';

class ProductCardItem extends StatelessWidget {
  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  const ProductCardItem({super.key, required this.product, this.onEdit, this.onDelete, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin sản phẩm
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.internalName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    if (product.tradeName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(product.tradeName, style: const TextStyle(color: Colors.black87), semanticsLabel: 'Tên thương mại'),
                      ),
                    // Ô nội dung chi tiết
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((product.barcode ?? '').isNotEmpty)
                            Text('Mã vạch: ${product.barcode}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if ((product.sku ?? '').isNotEmpty)
                            Text('SKU: ${product.sku}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if (product.unit.isNotEmpty)
                            Text('Đơn vị: ${product.unit}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if (product.description.isNotEmpty)
                            Text('Mô tả: ${product.description}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if (product.usage.isNotEmpty)
                            Text('Công dụng: ${product.usage}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if (product.ingredients.isNotEmpty)
                            Text('Thành phần: ${product.ingredients}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if (product.notes.isNotEmpty)
                            Text('Ghi chú: ${product.notes}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          Text('Giá nhập: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(product.costPrice)}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          Text('Giá bán: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(product.salePrice)}', style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold)),
                          //Text('Trạng thái: ${product.status == 'active' ? 'Còn bán' : 'Ngừng bán'}', style: TextStyle(fontSize: 13, color: product.status == 'active' ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                          Text('Ngày tạo: ${product.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(product.createdAt) : '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('Ngày cập nhật: ${product.updatedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(product.updatedAt) : '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (product.categoryIds.isNotEmpty)
                          Chip(
                            label: Text(product.categoryIds.join(', '), style: const TextStyle(fontSize: 13)),
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ...product.tags.map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 13)),
                              backgroundColor: Colors.grey[100],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              // Giá, số lượng, badge, nút
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: 'Xóa sản phẩm',
                          onPressed: onDelete,
                        ),
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          tooltip: 'Sửa sản phẩm',
                          onPressed: onEdit,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(product.salePrice),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Số lượng: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('${product.stockSystem}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if ((product.stockSystem ?? 0) < 60)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Sắp hết', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 