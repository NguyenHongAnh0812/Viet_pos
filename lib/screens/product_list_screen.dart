import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'package:intl/intl.dart' show NumberFormat;
import '../widgets/main_layout.dart';
import 'products/product_detail_screen.dart';

// Custom thumb shape with blue border
class BlueBorderThumbShape extends RoundSliderThumbShape {
  const BlueBorderThumbShape({
    double enabledThumbRadius = 9.0,
    double disabledThumbRadius = 9.0,
  }) : super(enabledThumbRadius: enabledThumbRadius, disabledThumbRadius: disabledThumbRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter? labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
    bool isEnabled = false,
    bool isOnTop = false,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;
    final double radius = isEnabled
        ? (enabledThumbRadius ?? 9.0)
        : (disabledThumbRadius ?? 9.0);
    final Paint fillPaint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white;
    final Paint borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);
  }
}

class ProductListScreen extends StatefulWidget {
  final Function(Product)? onProductTap;
  final Function(MainPage)? onNavigate;
  const ProductListScreen({super.key, this.onProductTap, this.onNavigate});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _productService = ProductService();
  String selectedCategory = 'Tất cả';
  RangeValues priceRange = const RangeValues(3500, 65000);
  RangeValues stockRange = const RangeValues(3, 120);
  String status = 'Tất cả';
  Set<String> selectedTags = {};
  String searchText = '';
  bool isFilterOpen = false;
  String sortOption = 'name_asc';

  final List<Map<String, dynamic>> sortOptions = [
    {
      'key': 'name_asc',
      'label': 'Tên (A → Z)',
      'icon': Icons.arrow_downward,
    },
    {
      'key': 'name_desc',
      'label': 'Tên (Z → A)',
      'icon': Icons.arrow_upward,
    },
    {
      'key': 'price_asc',
      'label': 'Giá: Thấp → Cao',
      'icon': Icons.arrow_downward,
    },
    {
      'key': 'price_desc',
      'label': 'Giá: Cao → Thấp',
      'icon': Icons.arrow_upward,
    },
    {
      'key': 'stock_asc',
      'label': 'Tồn kho: Ít → Nhiều',
      'icon': Icons.arrow_upward,
    },
    {
      'key': 'stock_desc',
      'label': 'Tồn kho: Nhiều → Ít',
      'icon': Icons.arrow_downward,
    },
  ];

  List<String> get allCategories => ['Tất cả', 'Kháng sinh', 'Vitamin', 'Giảm đau', 'Bổ sung', 'Khác'];
  List<String> get allTags => ['kháng sinh', 'phổ rộng', 'vitamin', 'bổ sung', 'NSAID', 'giảm đau', 'quinolone'];

  List<Product> filterProducts(List<Product> products) {
    return products.where((p) {
      if (selectedCategory != 'Tất cả' && p.category != selectedCategory) return false;
      if (p.salePrice < priceRange.start || p.salePrice > priceRange.end) return false;
      if (p.stock < stockRange.start || p.stock > stockRange.end) return false;
      if (status == 'Còn bán' && !p.isActive) return false;
      if (status == 'Ngừng bán' && p.isActive) return false;
      if (selectedTags.isNotEmpty && !selectedTags.any((tag) => p.tags.contains(tag))) return false;
      if (searchText.isNotEmpty && !(p.name.toLowerCase().contains(searchText.toLowerCase()) || 
          (p.barcode != null && p.barcode!.contains(searchText)))) return false;
      return true;
    }).toList();
  }

  List<Product> sortProducts(List<Product> products) {
    switch (sortOption) {
      case 'name_asc':
        products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        products.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'price_asc':
        products.sort((a, b) => a.salePrice.compareTo(b.salePrice));
        break;
      case 'price_desc':
        products.sort((a, b) => b.salePrice.compareTo(a.salePrice));
        break;
      case 'stock_asc':
        products.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'stock_desc':
        products.sort((a, b) => b.stock.compareTo(a.stock));
        break;
    }
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###', 'vi_VN');
    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danh sách sản phẩm', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Quản lý tất cả sản phẩm', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onNavigate?.call(MainPage.addProduct),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm sản phẩm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search and Filter Section
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextField(
                          onChanged: (v) => setState(() => searchText = v),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên, mã vạch...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: () {
                              // TODO: Implement QR scan logic
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Icon(
                                Icons.qr_code_scanner,
                                size: 24,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Filter and Sort Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedButton(
                                onPressed: () {setState(() {isFilterOpen = !isFilterOpen;});},
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Bộ lọc'),
                                    const SizedBox(width: 4),
                                    Icon(isFilterOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                              if (isFilterOpen) ...[
                                const SizedBox(height: 16.0),
                                // Category Filter
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Danh mục',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  value: selectedCategory,
                                  onChanged: (String? newValue) {
                                    setState(() {selectedCategory = newValue!;});
                                  },
                                  items: allCategories.map((String category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16.0),
                                // Price Range
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Khoảng giá', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        thumbShape: const BlueBorderThumbShape(
                                          enabledThumbRadius: 9,
                                          disabledThumbRadius: 9,
                                        ),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                        activeTrackColor: Colors.blue,
                                        inactiveTrackColor: Colors.blue.shade100,
                                        thumbColor: Colors.white,
                                        overlayColor: Colors.blue.withOpacity(0.2),
                                        activeTickMarkColor: Colors.blue,
                                        inactiveTickMarkColor: Colors.blue.shade100,
                                      ),
                                      child: RangeSlider(
                                        values: priceRange,
                                        min: 3500,
                                        max: 65000,
                                        divisions: 100,
                                        labels: RangeLabels(
                                          numberFormat.format(priceRange.start),
                                          numberFormat.format(priceRange.end),
                                        ),
                                        onChanged: (RangeValues values) {
                                          setState(() {priceRange = values;});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                // Stock Range
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Khoảng tồn kho', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        thumbShape: const BlueBorderThumbShape(
                                          enabledThumbRadius: 9,
                                          disabledThumbRadius: 9,
                                        ),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                        activeTrackColor: Colors.green,
                                        inactiveTrackColor: Colors.green.shade100,
                                        thumbColor: Colors.white,
                                        overlayColor: Colors.green.withOpacity(0.2),
                                        activeTickMarkColor: Colors.green,
                                        inactiveTickMarkColor: Colors.green.shade100,
                                      ),
                                      child: RangeSlider(
                                        values: stockRange,
                                        min: 3,
                                        max: 120,
                                        divisions: 117,
                                        labels: RangeLabels(
                                          stockRange.start.round().toString(),
                                          stockRange.end.round().toString(),
                                        ),
                                        onChanged: (RangeValues values) {
                                          setState(() {stockRange = values;});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16.0),
                                // Status
                                Text('Trạng thái', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        title: const Text('Tất cả'),
                                        leading: Radio<String>(
                                          value: 'Tất cả',
                                          groupValue: status,
                                          onChanged: (String? value) {setState(() {status = value!;});},
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        dense: true,
                                      ),
                                    ),
                                    Expanded(
                                      child: ListTile(
                                        title: const Text('Còn bán'),
                                        leading: Radio<String>(
                                          value: 'Còn bán',
                                          groupValue: status,
                                          onChanged: (String? value) {setState(() {status = value!;});},
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        dense: true,
                                      ),
                                    ),
                                    Expanded(
                                      child: ListTile(
                                        title: const Text('Ngừng bán'),
                                        leading: Radio<String>(
                                          value: 'Ngừng bán',
                                          groupValue: status,
                                          onChanged: (String? value) {setState(() {status = value!;});},
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        dense: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16.0),
                                // Tags
                                Text('Tags', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: allTags.map((tag) {
                                    final isSelected = selectedTags.contains(tag);
                                    return FilterChip(
                                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {selectedTags.add(tag);}
                                          else {selectedTags.remove(tag);}
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16.0),
                                // Clear Filter Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedCategory = 'Tất cả';
                                        priceRange = const RangeValues(3500, 65000);
                                        stockRange = const RangeValues(3, 120);
                                        status = 'Tất cả';
                                        selectedTags = {};
                                        searchText = '';
                                        isFilterOpen = false;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                      side: BorderSide(color: Colors.grey.shade400),
                                    ),
                                    child: const Text('Xoá bộ lọc'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        // Sort Button
                        DropdownButton<String>(
                          value: sortOption,
                          icon: Icon(Icons.arrow_drop_down),
                          onChanged: (String? newValue) {
                            setState(() {sortOption = newValue!;});
                          },
                          items: sortOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option['key']!,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(option['label']!),
                                  const SizedBox(width: 4),
                                  Icon(option['icon'], size: 18),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Product List
                  StreamBuilder<List<Product>>(
                    stream: _productService.getProducts(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Lỗi: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final products = snapshot.data ?? [];
                      final filteredProducts = filterProducts(products);
                      final sortedProducts = sortProducts(filteredProducts);

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: sortedProducts.length,
                        itemBuilder: (context, index) {
                          final product = sortedProducts[index];
                          return GestureDetector(
                            onTap: () {
                              if (widget.onProductTap != null) {
                                widget.onProductTap!(product);
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                              elevation: 2.5,
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Phần trái: Thông tin thuốc
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            product.commonName,
                                            style: TextStyle(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Mã vạch: ${product.barcode ?? "N/A"}',
                                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8.0,
                                            runSpacing: 4.0,
                                            children: product.tags.map((tag) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey, width: 1),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(tag, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Phần giữa: Giá và số lượng
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${numberFormat.format(product.salePrice)}đ',
                                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20),
                                            textAlign: TextAlign.left,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Text('Số lượng: ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                                              Text(
                                                '${product.stock}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Phần phải: Nút chỉnh sửa chỉ hiển thị tooltip, không điều hướng
                                    Container(
                                      margin: const EdgeInsets.only(left: 24),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.edit, color: Colors.grey[700], size: 20),
                                          tooltip: 'Chỉnh sửa',
                                          onPressed: null, // Không điều hướng ở đây
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 