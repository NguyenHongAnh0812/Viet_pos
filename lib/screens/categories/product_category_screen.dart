import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

import '../../services/product_category_service.dart';
import '../../services/product_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product_category.dart';
import '../../widgets/common/design_system.dart';

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
        .collection('product_category')
        .where('category_id', isEqualTo: categoryId)
        .get();
    return snapshot.docs.length;
  }

  Future<void> _createSampleCategoryTree() async {
    // Tạo cây mẫu: Thuốc (root) > Vitamin > Vitamin B, Kháng sinh, Thuốc giảm đau
    final rootId = (await _categoryService.addCategory(ProductCategory(id: '', name: 'Thuốc', description: 'Danh mục thuốc chính')));
    final snapshot = await _categoryService.getCategories().first;
    final rootCat = snapshot.firstWhere((c) => c.name == 'Thuốc');
    await _categoryService.addCategory(ProductCategory(id: '', name: 'Vitamin', description: 'Vitamin và khoáng chất', parentId: rootCat.id));
    await _categoryService.addCategory(ProductCategory(id: '', name: 'Kháng sinh', description: 'Thuốc kháng sinh', parentId: rootCat.id));
    await _categoryService.addCategory(ProductCategory(id: '', name: 'Thuốc giảm đau', description: 'Thuốc giảm đau, hạ sốt', parentId: rootCat.id));
    // Thêm 1 cấp con cho Vitamin
    final vitaminCat = (await _categoryService.getCategories().first).firstWhere((c) => c.name == 'Vitamin');
    await _categoryService.addCategory(ProductCategory(id: '', name: 'Vitamin B', description: 'Vitamin nhóm B', parentId: vitaminCat.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tạo cây danh mục mẫu!'), backgroundColor: Colors.green),
      );
    }
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
              widget.onNavigate!(MainPage.dashboard); // hoặc MainPage.home tuỳ app của bạn
            }
          },
        ),
        title: const Text(
          'Danh mục sản phẩm',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.account_tree, color: Colors.white),
            tooltip: 'Tạo cây danh mục mẫu',
            onPressed: _createSampleCategoryTree,
          ),
        ],
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
                      child: Text('Error:  {snapshot.error}'),
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
                final rootCategories = categoryTree[null] ?? [];
                if (categories.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Không có danh mục nào phù hợp'),
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
        onPressed: () {
          if (widget.onNavigate != null) {
            widget.onNavigate!(MainPage.addProductCategory);
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
    for (var category in categories) {
      final children = categoryTree[category.id] ?? [];
      final hasChildren = children.isNotEmpty;
      final isExpanded = _expandedCategories.contains(category.id);
      final productCount = _productCounts[category.id];
      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                  padding: level == 0
                      ? const EdgeInsets.symmetric(horizontal: 20, vertical: 18)
                      : const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Row(
                    children: [
                      if (hasChildren)
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                          color: Colors.grey[700],
                          size: 26,
                        ),
                      if (!hasChildren)
                        const SizedBox(width: 2),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          category.name ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (_productCounts[category.id] ?? 0).toString(),
                          style: const TextStyle(
                            color: Color(0xFF43A047),
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasChildren && isExpanded)
                Container(
                  padding: const EdgeInsets.only(left: 32, right: 8, bottom: 8),
                  child: Column(
                    children: _buildCategoryCards(children, categoryTree, level + 1),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return items;
  }

  // Xoá hàm _getProductCounts cũ
} 