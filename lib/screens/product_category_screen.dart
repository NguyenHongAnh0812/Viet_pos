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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onNavigate != null ? () => widget.onNavigate!(MainPage.dashboard) : null,
                ),
                const SizedBox(width: 4),
                const Text('Danh mục sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _categoryService.syncCategoriesFromProducts();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đồng bộ danh mục từ sản phẩm!')));
                  },
                  icon: const Icon(Icons.sync, size: 20),
                  label: const Text('Đồng bộ danh mục từ sản phẩm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onNavigate != null) {
                      widget.onNavigate!(MainPage.addProductCategory);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm danh mục'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3a6ff8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
            child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Tìm theo tên, mã vạch...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onChanged: (v) => setState(() => searchText = v),
                          ),
          ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: sortOption,
                  items: const [
                    DropdownMenuItem(value: 'name_asc', child: Text('Tên: A-Z')),
                    DropdownMenuItem(value: 'name_desc', child: Text('Tên: Z-A')),
                  ],
                  onChanged: (v) => setState(() => sortOption = v!),
                        borderRadius: BorderRadius.circular(8),
                      ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<ProductCategory>>(
                stream: _categoryService.getCategories(),
                builder: (context, catSnapshot) {
                  if (catSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var categories = catSnapshot.data ?? [];
                  if (searchText.isNotEmpty) {
                    categories = categories.where((c) => c.name.toLowerCase().contains(searchText.toLowerCase())).toList();
                  }
                  if (sortOption == 'name_asc') {
                    categories.sort((a, b) => a.name.compareTo(b.name));
                  } else {
                    categories.sort((a, b) => b.name.compareTo(a.name));
                  }
                  return StreamBuilder<List<Product>>(
                    stream: _productService.getProducts(),
                    builder: (context, prodSnapshot) {
                      final products = prodSnapshot.data ?? [];
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
                                  Expanded(child: Text('Tên danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                  Text('Số sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                      ),
                    ),
                            const Divider(height: 1),
                            ...categories.map((cat) {
                              final count = products.where((p) => p.category == cat.name).length;
                              final isDefault = cat.name.trim().toLowerCase() == 'khác';
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: space24, vertical: space12),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(cat.name, style: h4)),
                                    DesignSystemBadge(text: '$count'),
                                    const SizedBox(width: space16),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 14, color: Colors.blue),
                                      tooltip: 'Đổi tên danh mục',
                                      onPressed: () async {
                                        String? errorText;
                                        String? newName = cat.name;
                                        await showDialog<void>(
                                          context: context,
                                          builder: (context) {
                                            final controller = TextEditingController(text: cat.name);
                                            return StatefulBuilder(
                                              builder: (context, setDialogState) {
                                                return AlertDialog(
                                                  title: const Text('Đổi tên danh mục'),
                                                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                                                      TextField(
                                                        controller: controller,
                                                        decoration: InputDecoration(hintText: 'Tên mới', errorText: errorText),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        final input = controller.text.trim();
                                                        if (input.isEmpty) {
                                                          setDialogState(() => errorText = 'Tên không được để trống!');
                                                          return;
                                                        }
                                                        if (categories.any((c) => c.name.toLowerCase() == input.toLowerCase() && c.name != cat.name)) {
                                                          setDialogState(() => errorText = 'Tên danh mục đã tồn tại!');
                                                          return;
                                                        }
                                                        Navigator.pop(context);
                                                        newName = input;
                                                      },
                                                      child: const Text('Lưu'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        );
                                        if (newName?.isNotEmpty == true && newName != cat.name) {
                                          await _categoryService.renameCategory(cat.name, newName!);
                                          setState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đổi tên danh mục!')));
                                        }
                          },
                        ),
                        IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      tooltip: 'Xóa danh mục',
                                      onPressed: isDefault ? () {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa danh mục mặc định!')));
                                      } : () async {
                                        final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xác nhận xóa'),
                                            content: Text('Bạn có chắc muốn xóa danh mục "${cat.name}"?\nTất cả sản phẩm thuộc danh mục này sẽ được chuyển về "Khác".'),
                                actions: [
                                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                                  ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Xóa'),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  ),
                                ],
                              ),
                            );
                                        if (confirm == true) {
                                          await _categoryService.deleteCategory(cat.name);
                                          setState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa danh mục!')));
                                        }
                          },
                        ),
                      ],
                    ),
                              );
                            }).toList(),
                          ],
                  ),
                );
              },
                  );
                },
              ),
            ),
          ],
          ),
      ),
    );
  }
} 