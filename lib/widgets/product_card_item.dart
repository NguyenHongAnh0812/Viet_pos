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
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    if (product.commonName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(product.commonName, style: const TextStyle(color: Colors.black87)),
                      ),
                    if ((product.barcode ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Mã vạch: ${product.barcode}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (product.category.isNotEmpty)
                          Chip(
                            label: Text(product.category, style: const TextStyle(fontSize: 13)),
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ...product.tags.map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 13)),
                              backgroundColor: Colors.grey[100],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            )).toList(),
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
                      Text('${product.stock}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if ((product.stock ?? 0) < 60)
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