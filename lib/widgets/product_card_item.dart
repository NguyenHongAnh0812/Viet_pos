import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../models/product_category.dart';
import '../services/product_category_service.dart';
import '../services/product_category_relation_service.dart';
import '../widgets/common/design_system.dart';

class ProductCardItem extends StatefulWidget {
  final Product product;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback? onTap;

  const ProductCardItem({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onSelectionChanged,
    this.onTap,
  });

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
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh sản phẩm hoặc placeholder
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.white54, size: 32),
              ),
              // Thông tin sản phẩm
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product.tradeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (widget.product.internalName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(widget.product.internalName, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                            ),
                          if ((widget.product.barcode ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(widget.product.barcode!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('Giá bán: ${formatCurrency(widget.product.salePrice)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ],
                      ),
                    ),
                    // Số lượng (chip bo tròn, viền xanh, góc trên phải)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: mainGreen, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${widget.product.stockSystem} ${widget.product.unit}', style: const TextStyle(color: mainGreen, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Border xám nhạt dưới cùng
          Container(
            height: 1,
            color: Colors.grey[200],
            margin: EdgeInsets.only(left: 72), // thẳng hàng với text, không kéo dài dưới avatar
          ),
        ],
      ),
    );
  }
} 