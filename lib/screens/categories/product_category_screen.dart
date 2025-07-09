import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

import '../../services/product_category_service.dart';
import '../../services/product_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product_category.dart';
import '../../widgets/common/design_system.dart';
import 'add_product_category_screen.dart';

class ProductCategoryScreen extends StatefulWidget {
  final Function(MainPage)? onNavigate;
  final Function(ProductCategory)? onCategorySelected;
  const ProductCategoryScreen({super.key, this.onNavigate, this.onCategorySelected});

  @override
  State<ProductCategoryScreen> createState() => _ProductCategoryScreenState();
}

class _ProductCategoryScreenState extends State<ProductCategoryScreen> with SingleTickerProviderStateMixin {
  final _categoryService = ProductCategoryService();
  final _productService = ProductService();
  final _productCategoryLinkService = ProductCategoryLinkService();
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  String sortOption = 'name_asc';
  final Set<String> _expandedCategories = {};
  // Thêm biến quản lý trạng thái loading và count từng category
  final Map<String, int?> _productCounts = {};
  // Thêm biến stream
  late final Stream<List<ProductCategory>> _categoryStream;
  
  // Duration for all animations
  static const Duration animDuration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _categoryStream = FirebaseFirestore.instance
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromFirestore(doc))
            .toList());
  }

  void _toggleExpand(String categoryId) async {
    setState(() {
      if (_expandedCategories.contains(categoryId)) {
        _expandedCategories.remove(categoryId);
      } else {
        _expandedCategories.add(categoryId);
      }
    });
    // Nếu chưa có count thì load, nhưng không hiện loading nữa
    if (!_productCounts.containsKey(categoryId)) {
      final count = await _getProductCountForCategory(categoryId);
      setState(() {
        _productCounts[categoryId] = count;
      });
    }
  }

  // Hàm lấy count cho 1 category
  Future<int> _getProductCountForCategory(String categoryId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('product_categories')
        .where('category_id', isEqualTo: categoryId)
        .get();
    final productIds = snapshot.docs.map((doc) => doc.data()['product_id']).toList();
    print('[DEBUG] Category $categoryId: count=${snapshot.docs.length}, productIds=$productIds');
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        centerTitle: true,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (widget.onNavigate != null) {
              widget.onNavigate!(MainPage.moreDashboard); // hoặc MainPage.home tuỳ app của bạn
            }
          },
        ),
        title: const Text(
          'Danh mục sản phẩm',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: appBackground,
      body: Container(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<List<ProductCategory>>(
              stream: _categoryStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error:  {snapshot.error}', style: bodySmall.copyWith(color: Colors.red)),
                    ),
                  );
                }
                var categories = snapshot.data ?? [];
                // Apply search filter
                if (searchText.isNotEmpty) {
                  categories = categories.where((c) => c.name.toLowerCase().contains(searchText.toLowerCase())).toList();
                }
                // Build tree structure
                final Map<String?, List<ProductCategory>> categoryTree = {};
                for (var category in categories) {
                  final parentId = category.parentId;
                  categoryTree.putIfAbsent(parentId, () => []).add(category);
                }
                // Load count cho tất cả category nếu chưa có (chỉ 1 lần khi categories thay đổi)
                _preloadAllProductCounts(categories);
                final rootCategories = categoryTree[null] ?? [];
                if (categories.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Không có danh mục nào phù hợp', style: bodySmall),
                    ),
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  children: _buildCategoryCards(rootCategories, categoryTree, 0),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4CAF50),
        shape: const CircleBorder(),
        onPressed: () async {
          // Mở trang thêm danh mục mới
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductCategoryScreen(
                onBack: () => Navigator.pop(context, true),
              ),
            ),
          );
          // Nếu thêm thành công, có thể reload lại dữ liệu nếu cần
          if (result == true) {
            setState(() {}); // Gọi lại build để reload stream nếu cần
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Widget> _buildCategoryCards(
    List<ProductCategory> categories,
    Map<String?, List<ProductCategory>> categoryTree,
    int level,
  ) {
    final List<Widget> items = [];
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final children = categoryTree[category.id] ?? [];
      final hasChildren = children.isNotEmpty;
      final isExpanded = _expandedCategories.contains(category.id);
      final productCount = _productCounts[category.id];
      items.add(
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: level == 0 ? Border.all(color: const Color(0xFFE0E0E0)) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (hasChildren) {
                        _toggleExpand(category.id);
                      } else {
                        if (widget.onCategorySelected != null) {
                          widget.onCategorySelected!(category);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Chọn: \'${category.name}\'')),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (hasChildren)
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                              color: Colors.grey[700],
                              size: 26,
                            ),
                          if (!hasChildren)
                            SizedBox(width: 2),
                          SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              category.name ?? '',
                              style: responsiveTextStyle(
                                context,
                                bodyLarge.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
                                body.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48, // Đặt width cố định cho phần count để thẳng hàng
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (_productCounts[category.id] ?? 0).toString(),
                                  style: responsiveTextStyle(
                                    context,
                                    labelLarge.copyWith(color: const Color(0xFF43A047), fontWeight: FontWeight.w600),
                                    labelMedium.copyWith(color: const Color(0xFF43A047), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasChildren && isExpanded)
                    Container(
                      padding: const EdgeInsets.only(left: 32, right: 0, bottom: 8),
                      child: Column(
                        children: _buildCategoryCards(children, categoryTree, level + 1),
                      ),
                    ),
                ],
              ),
            ),
            if (level == 0 && i < categories.length - 1)
              SizedBox(height: 16), // Use spacing from design system if available
          ],
        ),
      );
    }
    return items;
  }

  // Thay thế FutureBuilder bằng preload count chỉ 1 lần
  void _preloadAllProductCounts(List<ProductCategory> categories) {
    for (var category in categories) {
      if (!_productCounts.containsKey(category.id)) {
        _getProductCountForCategory(category.id).then((count) {
          if (mounted) {
            setState(() {
              _productCounts[category.id] = count;
            });
          }
        });
      }
    }
  }
} 