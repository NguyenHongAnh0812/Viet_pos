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
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
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
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(MainPage.addProductCategory);
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm danh mục'),
                        style: primaryButtonStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Search and Sort Controls
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      children: [
                        // Search bar
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => searchText = value),
                            decoration: searchInputDecoration(hint: 'Tìm kiếm danh mục...'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Sort dropdown
                        SizedBox(
                          width: 200,
                          child: ShopifyDropdown<String>(
                            value: sortOption,
                            items: const [
                              'name_asc', 
                              'name_desc', 
                              'products_desc', 
                              'products_asc', 
                              'date_desc', 
                              'date_asc'
                            ],
                            getLabel: (value) {
                              switch (value) {
                                case 'name_asc': return 'Tên: A-Z';
                                case 'name_desc': return 'Tên: Z-A';
                                case 'products_desc': return 'Số sản phẩm: Nhiều nhất';
                                case 'products_asc': return 'Số sản phẩm: Ít nhất';
                                case 'date_desc': return 'Ngày tạo: Mới nhất';
                                case 'date_asc': return 'Ngày tạo: Cũ nhất';
                                default: return '';
                              }
                            },
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => sortOption = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
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

                            var categories = snapshot.data ?? [];
                            
                            // Apply search filter
                            if (searchText.isNotEmpty) {
                              categories = categories.where((c) => c.name.toLowerCase().contains(searchText.toLowerCase())).toList();
                            }
                            
                            // Fetch product counts for sorting if needed
                            return FutureBuilder<Map<String, int>>(
                              future: _getProductCounts(categories),
                              builder: (context, productCountSnapshot) {
                                if (productCountSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final productCounts = productCountSnapshot.data ?? {};

                                // Apply sorting
                                categories.sort((a, b) {
                                  switch (sortOption) {
                                    case 'name_asc':
                                      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                                    case 'name_desc':
                                      return b.name.toLowerCase().compareTo(a.name.toLowerCase());
                                    case 'products_desc':
                                      return (productCounts[b.id] ?? 0).compareTo(productCounts[a.id] ?? 0);
                                    case 'products_asc':
                                      return (productCounts[a.id] ?? 0).compareTo(productCounts[b.id] ?? 0);
                                    case 'date_desc':
                                      final dateA = a.createdAt?.toDate() ?? DateTime(1970);
                                      final dateB = b.createdAt?.toDate() ?? DateTime(1970);
                                      return dateB.compareTo(dateA);
                                    case 'date_asc':
                                      final dateA = a.createdAt?.toDate() ?? DateTime(1970);
                                      final dateB = b.createdAt?.toDate() ?? DateTime(1970);
                                      return dateA.compareTo(dateB);
                                    default:
                                      return 0;
                                  }
                                });

                                // Build tree structure
                                final Map<String?, List<ProductCategory>> categoryTree = {};
                                for (var category in categories) {
                                  // Only add search results and their parents
                                  if (searchText.isNotEmpty) {
                                    categoryTree.putIfAbsent(category.parentId, () => []).add(category);
                                  } else {
                                    final parentId = category.parentId;
                                    categoryTree.putIfAbsent(parentId, () => []).add(category);
                                  }
                                }

                                // Build list items starting with root categories
                                final rootCategories = categoryTree[null] ?? [];
                                
                                if (categories.isEmpty) { // Changed from rootCategories.isEmpty
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text('Không có danh mục nào phù hợp'),
                                    ),
                                  );
                                }
                                
                                if (searchText.isNotEmpty) {
                                  // Flatten list for search results
                                  return Column(
                                    children: _buildCategoryItems(categories, {}, 0, productCounts),
                                  );
                                }

                                return Column(
                                  children: _buildCategoryItems(rootCategories, categoryTree, 0, productCounts),
                                );
                              },
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
        ),
      ),
    );
  }

  List<Widget> _buildCategoryItems(
    List<ProductCategory> categories,
    Map<String?, List<ProductCategory>> categoryTree,
    int level,
    Map<String, int> productCounts,
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
            _buildCategoryRow(category, level, categoryTree, productCounts),
            if (hasChildren && searchText.isEmpty) // Don't show children expansion in search
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
                      children: _buildCategoryItems(children, categoryTree, level + 1, productCounts),
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
    Map<String, int> productCounts,
  ) {
    final hasChildren = (categoryTree[category.id] ?? []).isNotEmpty;
    final isExpanded = _expandedCategories.contains(category.id);
    final isChild = level > 0;
    
    final productCount = productCounts[category.id] ?? 0;

    return InkWell(
      onTap: () {
        if (hasChildren) {
          _toggleExpand(category.id);
        } else {
          if (widget.onCategorySelected != null) {
            widget.onCategorySelected!(category);
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor)),
        ),
        padding: EdgeInsets.only(left: 24.0 + (level * 32.0), right: 24, top: 12, bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: hasChildren && searchText.isEmpty // No expand icon in search results
                  ? IconButton(
                      icon: Icon(
                        isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => _toggleExpand(category.id),
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
                          category.name ?? '',
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
    );
  }

  Future<Map<String, int>> _getProductCounts(List<ProductCategory> categories) async {
    final Map<String, int> counts = {};
    for (var category in categories) {
      final snapshot = await FirebaseFirestore.instance
          .collection('product_category')
          .where('category_id', isEqualTo: category.id)
          .get();
      counts[category.id] = snapshot.docs.length;
    }
    return counts;
  }
} 