import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../services/product_category_service.dart';
import '../services/product_service.dart';
import 'add_product_category_screen.dart';
import '../widgets/common/design_system.dart';

class ProductCategoryScreen extends StatefulWidget {
  final Function(MainPage)? onNavigate;
  const ProductCategoryScreen({super.key, this.onNavigate});

  @override
  State<ProductCategoryScreen> createState() => _ProductCategoryScreenState();
}

class _ProductCategoryScreenState extends State<ProductCategoryScreen> {
  final _categoryService = ProductCategoryService();
  final _productService = ProductService();
    final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  String sortOption = 'name_asc';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                if (isMobile) ...[
                  // Heading
                  const Text('Danh mục sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (widget.onNavigate != null) {
                          widget.onNavigate!(MainPage.addProductCategory);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm danh mục'),
                      style: primaryButtonStyle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextField(
                      controller: _searchController,
                      decoration: searchInputDecoration(
                        hint: 'Tìm kiếm danh mục...'
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (v) => setState(() => searchText = v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ShopifyDropdown<String>(
                      items: const [
                        'name_asc',
                        'name_desc',
                        'product_count_desc',
                        'product_count_asc',
                      ],
                      value: sortOption,
                      getLabel: (key) {
                        switch (key) {
                          case 'name_asc':
                            return 'Tên: A-Z';
                          case 'name_desc':
                            return 'Tên: Z-A';
                          case 'product_count_desc':
                            return 'Số sản phẩm: Nhiều nhất';
                          case 'product_count_asc':
                            return 'Số sản phẩm: Ít nhất';
                          default:
                            return key;
                        }
                      },
                      onChanged: (v) => setState(() => sortOption = v ?? sortOption),
                      hint: 'Sắp xếp',
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Desktop: heading, back, add button cùng 1 dòng
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 4),
                      const Text('Danh mục sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                      const Spacer(),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (widget.onNavigate != null) {
                              widget.onNavigate!(MainPage.addProductCategory);
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm danh mục'),
                          style: primaryButtonStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: TextField(
                          controller: _searchController,
                          decoration: searchInputDecoration(
                            hint: 'Tìm danh mục',
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (v) => setState(() => searchText = v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: ShopifyDropdown<String>(
                          items: const [
                            'name_asc',
                            'name_desc',
                            'product_count_desc',
                            'product_count_asc',
                          ],
                          value: sortOption,
                          getLabel: (key) {
                            switch (key) {
                              case 'name_asc':
                                return 'Tên: A-Z';
                              case 'name_desc':
                                return 'Tên: Z-A';
                              case 'product_count_desc':
                                return 'Số sản phẩm: Nhiều nhất';
                              case 'product_count_asc':
                                return 'Số sản phẩm: Ít nhất';
                              default:
                                return key;
                            }
                          },
                          onChanged: (v) => setState(() => sortOption = v ?? sortOption),
                          hint: 'Sắp xếp',
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                // Danh sách danh mục giữ nguyên
                StreamBuilder<List<ProductCategory>>(
                  stream: _categoryService.getCategories(),
                  builder: (context, catSnapshot) {
                    if (catSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var categories = catSnapshot.data ?? [];
                    if (searchText.isNotEmpty) {
                      categories = categories.where((c) => c.name.toLowerCase().contains(searchText.toLowerCase())).toList();
                    }
                    return StreamBuilder<List<Product>>(
                      stream: _productService.getProducts(),
                      builder: (context, prodSnapshot) {
                        final products = prodSnapshot.data ?? [];
                        if (sortOption == 'name_asc') {
                          categories.sort((a, b) => a.name.compareTo(b.name));
                        } else if (sortOption == 'name_desc') {
                          categories.sort((a, b) => b.name.compareTo(a.name));
                        } else if (sortOption == 'product_count_desc') {
                          categories.sort((a, b) {
                            final countA = products.where((p) => p.category == a.name).length;
                            final countB = products.where((p) => p.category == b.name).length;
                            return countB.compareTo(countA);
                          });
                        } else if (sortOption == 'product_count_asc') {
                          categories.sort((a, b) {
                            final countA = products.where((p) => p.category == a.name).length;
                            final countB = products.where((p) => p.category == b.name).length;
                            return countA.compareTo(countB);
                          });
                        }
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 600;
                            if (isMobile) {
                              // Mobile style: card list
                              return Column(
                                children: [
                                  ...categories.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final cat = entry.value;
                                    final count = products.where((p) => p.category == cat.name).length;
                                    return _CategoryCardItem(
                                      name: cat.name,
                                      count: count,
                                      isLast: idx == categories.length - 1,
                                      onTap: () {
                                        if (widget.onNavigate != null) widget.onNavigate!(MainPage.productCategory);
                                      },
                                    );
                                  }),
                                ],
                              );
                            } else {
                              // Desktop/tablet: table style
                              return Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                      child: Row(
                                        children: const [
                                          Expanded(
                                            flex: 7,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text('Tên danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textSecondary)),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: Text('Số sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textSecondary)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    ...categories.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final cat = entry.value;
                                      final count = products.where((p) => p.category == cat.name).length;
                                      return _CategoryTableRow(
                                        name: cat.name,
                                        count: count,
                                        isLast: idx == categories.length - 1,
                                        onTap: () {
                                          if (widget.onNavigate != null) widget.onNavigate!(MainPage.productCategory);
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryTableRow extends StatefulWidget {
  final String name;
  final int count;
  final bool isLast;
  final VoidCallback onTap;
  const _CategoryTableRow({required this.name, required this.count, required this.isLast, required this.onTap});
  @override
  State<_CategoryTableRow> createState() => _CategoryTableRowState();
}
class _CategoryTableRowState extends State<_CategoryTableRow> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _hover ? appBackground : Colors.white,
            border: widget.isLast ? null : const Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.center,
                  child: Text('${widget.count}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCardItem extends StatefulWidget {
  final String name;
  final int count;
  final bool isLast;
  final VoidCallback onTap;
  const _CategoryCardItem({required this.name, required this.count, required this.isLast, required this.onTap});
  @override
  State<_CategoryCardItem> createState() => _CategoryCardItemState();
}
class _CategoryCardItemState extends State<_CategoryCardItem> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: _hover ? appBackground : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 6),
                    Text('${widget.count} sản phẩm', style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
} 