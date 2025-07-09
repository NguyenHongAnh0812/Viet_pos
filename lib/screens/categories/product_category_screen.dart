import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

import '../../services/product_category_service.dart';
import '../../services/product_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product_category.dart';
import '../../widgets/common/design_system.dart';
import 'add_product_category_screen.dart';
import 'edit_product_category_screen.dart';


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
        backgroundColor: mainGreen,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (widget.onNavigate != null) {
              widget.onNavigate!(MainPage.moreDashboard);
            }
          },
        ),
        title: Text(
          'Danh mục sản phẩm',
          style: h3.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree, color: Colors.white),
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
        backgroundColor: mainGreen,
        shape: const CircleBorder(),
        onPressed: () async {
          // Mở trang thêm danh mục mới
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductCategoryScreen(
                onBack: () => Navigator.pop(context), // Sửa lại, không trả về true
              ),
            ),
          );
          // Nếu thêm thành công, có thể reload lại dữ liệu nếu cần
          if (result == true) {
            // Reset product counts để load lại số lượng sản phẩm cho danh mục mới
            setState(() {
              _productCounts.clear();
            });
            // Force reload counts cho tất cả categories sau khi thêm mới
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _categoryStream.first.then((categories) {
                if (mounted) {
                  _forceReloadAllCounts(categories);
                }
              });
            });
            showSuccessSnackBar(context, 'Đã thêm danh mục thành công!');
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
                borderRadius: BorderRadius.circular(borderRadiusMedium),
                border: level == 0 ? Border.all(color: borderColor) : null,
                boxShadow: level == 0 ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(borderRadiusMedium),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon theo level
                          Icon(
                            level == 0 ? Icons.category : Icons.subdirectory_arrow_right,
                            color: level == 0 ? mainGreen : textSecondary,
                            size: level == 0 ? 20 : 16,
                          ),
                          const SizedBox(width: 12),
                          // Tiêu đề + badge: bấm vào sẽ sang màn hình sửa
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProductCategoryScreen(
                                      category: category,
                                      onBack: () => Navigator.pop(context), // Sửa lại, không trả về true
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  setState(() {
                                    _productCounts.clear();
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _categoryStream.first.then((categories) {
                                      if (mounted) {
                                        _forceReloadAllCounts(categories);
                                      }
                                    });
                                  });
                                  showSuccessSnackBar(context, 'Đã cập nhật danh mục thành công!');
                                }
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      category.name ?? '',
                                      style: bodyLarge.copyWith(
                                        color: level == 0 ? textPrimary : textSecondary,
                                        fontWeight: level == 0 ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: mainGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _productCounts.containsKey(category.id)
                                        ? Text(
                                            _productCounts[category.id].toString(),
                                            style: labelMedium.copyWith(
                                              color: mainGreen,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        : SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(mainGreen),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Mũi tên expand/collapse (nếu có con)
                          if (hasChildren)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _toggleExpand(category.id),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                    color: textSecondary,
                                    size: 20,
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
                      padding: const EdgeInsets.only(left: 20, right: 0, bottom: 8),
                      child: Column(
                        children: _buildCategoryCards(children, categoryTree, level + 1),
                      ),
                    ),
                ],
              ),
            ),
            if (level == 0 && i < categories.length - 1)
              const SizedBox(height: space16),
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

  // Force reload counts cho tất cả categories
  void _forceReloadAllCounts(List<ProductCategory> categories) {
    for (var category in categories) {
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