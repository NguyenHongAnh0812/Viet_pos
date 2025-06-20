import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../services/product_category_service.dart';
import '../services/product_service.dart';
import 'add_product_category_screen.dart';
import '../widgets/common/design_system.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_category_detail_screen.dart';

class ProductCategoryScreen extends StatefulWidget {
  final Function(MainPage)? onNavigate;
  const ProductCategoryScreen({super.key, this.onNavigate});

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
  
  // Duration for all animations
  static const Duration animDuration = Duration(milliseconds: 200);

  void _toggleExpand(String categoryId) {
    setState(() {
      if (_expandedCategories.contains(categoryId)) {
        _expandedCategories.remove(categoryId);
      } else {
        _expandedCategories.add(categoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh mục sản phẩm',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddProductCategoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm danh mục'),
                    style: primaryButtonStyle,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Table container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: borderColor)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 40), // Space for arrow/bullet
                          Expanded(
                            child: Row(
                              children: const [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Tên danh mục',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 24),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    'Số sản phẩm',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(width: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Category List
                    StreamBuilder<List<ProductCategory>>(
                      stream: FirebaseFirestore.instance
                          .collection('categories')
                          .snapshots()
                          .map((snapshot) => snapshot.docs
                              .map((doc) => ProductCategory.fromFirestore(doc))
                              .toList()),
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
                              child: Text('Error: ${snapshot.error}'),
                            ),
                          );
                        }

                        final categories = snapshot.data ?? [];
                        
                        // Build tree structure
                        final Map<String?, List<ProductCategory>> categoryTree = {};
                        for (var category in categories) {
                          final parentId = category.parentId;
                          categoryTree.putIfAbsent(parentId, () => []).add(category);
                        }

                        // Build list items starting with root categories
                        final rootCategories = categoryTree[null] ?? [];
                        
                        if (rootCategories.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Chưa có danh mục nào'),
                            ),
                          );
                        }

                        return Column(
                          children: _buildCategoryItems(rootCategories, categoryTree, 0),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryItems(
    List<ProductCategory> categories,
    Map<String?, List<ProductCategory>> categoryTree,
    int level,
  ) {
    final List<Widget> items = [];

    for (var category in categories) {
      final children = categoryTree[category.id] ?? [];
      final hasChildren = children.isNotEmpty;
      final isExpanded = _expandedCategories.contains(category.id);

      items.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCategoryRow(category, level, categoryTree),
            if (hasChildren)
              AnimatedSize(
                duration: animDuration,
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: ClipRect(
                  child: AnimatedContainer(
                    duration: animDuration,
                    height: isExpanded ? null : 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildCategoryItems(children, categoryTree, level + 1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return items;
  }

  Widget _buildCategoryRow(
    ProductCategory category,
    int level,
    Map<String?, List<ProductCategory>> categoryTree,
  ) {
    final hasChildren = (categoryTree[category.id] ?? []).isNotEmpty;
    final isExpanded = _expandedCategories.contains(category.id);
    final isChild = level > 0;

    return StreamBuilder<int>(
      stream: FirebaseFirestore.instance
          .collection('product_category')
          .where('category_id', isEqualTo: category.id)
          .snapshots()
          .map((snapshot) => snapshot.docs.length),
      builder: (context, snapshot) {
        final productCount = snapshot.data ?? 0;
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (hasChildren) {
                _toggleExpand(category.id);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductCategoryDetailScreen(category: category),
                  ),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.only(
                left: 24.0 + (level * 32.0),
                right: 24.0,
                top: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor.withOpacity(0.5)),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Center(
                      child: hasChildren && !isChild
                        ? AnimatedRotation(
                            duration: animDuration,
                            turns: isExpanded ? 0.25 : 0,
                            child: Icon(
                              Icons.keyboard_arrow_right,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                          )
                        : isChild
                          ? Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (category.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  category.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 120,
                          child: Text(
                            productCount.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 