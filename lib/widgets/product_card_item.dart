import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../services/product_category_service.dart';
import '../services/product_category_relation_service.dart';
import '../widgets/common/design_system.dart';
import '../screens/products/product_detail_screen.dart';

class ProductCardItem extends StatefulWidget {
  final Product product;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback? onTap;

  const ProductCardItem({
    Key? key,
    required this.product,
    required this.isSelected,
    required this.onSelectionChanged,
    this.onTap,
  }) : super(key: key);

  @override
  State<ProductCardItem> createState() => _ProductCardItemState();
}

class _ProductCardItemState extends State<ProductCardItem> {
  final ProductCategoryService _categoryService = ProductCategoryService();
  final ProductCategoryRelationService _productCategoryService = ProductCategoryRelationService();
  List<String> _categoryNames = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categoryIds = await _productCategoryService.getCategoryIdsForProduct(widget.product.id);
      final categories = await _categoryService.getCategories().first;
      
      final categoryNames = <String>[];
      for (final categoryId in categoryIds) {
        final category = categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => ProductCategory(id: '', name: 'Unknown'),
        );
        if (category.name.isNotEmpty) {
          categoryNames.add(category.name);
        }
      }
      
      if (mounted) {
        setState(() {
          _categoryNames = categoryNames;
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
      }
    }
  }

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
        onTap: widget.onTap,
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
                    Text(widget.product.internalName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    if (widget.product.tradeName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(widget.product.tradeName, style: const TextStyle(color: Colors.black87), semanticsLabel: 'Tên thương mại'),
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
                          if ((widget.product.barcode ?? '').isNotEmpty)
                            Text('Mã vạch: ${widget.product.barcode}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if ((widget.product.sku ?? '').isNotEmpty)
                            Text('SKU: ${widget.product.sku}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if (widget.product.unit.isNotEmpty)
                            Text('Đơn vị: ${widget.product.unit}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if (widget.product.description.isNotEmpty)
                            Text('Mô tả: ${widget.product.description}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if (widget.product.usage.isNotEmpty)
                            Text('Công dụng: ${widget.product.usage}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if (widget.product.ingredients.isNotEmpty)
                            Text('Thành phần: ${widget.product.ingredients}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          if (widget.product.notes.isNotEmpty)
                            Text('Ghi chú: ${widget.product.notes}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          Text('Giá nhập: ${formatCurrency(widget.product.costPrice)}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          Text('Giá bán: ${formatCurrency(widget.product.salePrice)}', style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold)),
                          //Text('Trạng thái: ${widget.product.status == 'active' ? 'Còn bán' : 'Ngừng bán'}', style: TextStyle(fontSize: 13, color: widget.product.status == 'active' ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                          Text('Ngày tạo: ${widget.product.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(widget.product.createdAt) : '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('Ngày cập nhật: ${widget.product.updatedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(widget.product.updatedAt) : '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (_categoryNames.isNotEmpty)
                          Chip(
                            label: Text(_categoryNames.join(', '), style: const TextStyle(fontSize: 13)),
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ...widget.product.tags.map((tag) => Chip(
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
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        tooltip: 'Xóa sản phẩm',
                        onPressed: () {
                          // Handle delete action
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        tooltip: 'Sửa sản phẩm',
                        onPressed: () {
                          // Handle edit action
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(widget.product.salePrice),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Số lượng: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('${widget.product.stockSystem}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if ((widget.product.stockSystem ?? 0) < 60)
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