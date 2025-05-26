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
                        // Nút Bộ lọc
                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () {setState(() {isFilterOpen = !isFilterOpen;});},
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.filter_alt_outlined, size: 18),
                                const SizedBox(width: 4),
                                const Text('Bộ lọc'),
                                const SizedBox(width: 4),
                                Icon(isFilterOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Nút Sắp xếp custom
                        SizedBox(
                          height: 44,
                          child: PopupMenuButton<String>(
                            onSelected: (String newValue) {
                              setState(() {sortOption = newValue;});
                            },
                            offset: const Offset(0, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                enabled: false,
                                child: Text('Sắp xếp theo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                              ),
                              ...sortOptions.map((option) {
                                final isSelected = sortOption == option['key'];
                                return PopupMenuItem<String>(
                                  value: option['key'],
                                  child: Row(
                                    children: [
                                      Icon(option['icon'], size: 18, color: Colors.black),
                                      const SizedBox(width: 8),
                                      Text(option['label'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF3a6ff8),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text('Đang chọn', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(5),
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              height: 44,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(sortOptions.firstWhere((o) => o['key'] == sortOption)['icon'], size: 18),
                                  const SizedBox(width: 4),
                                  Text('Sắp xếp', style: TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bộ lọc chi tiết
                  if (isFilterOpen)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                        elevation: 0,
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Danh mục
                              Text('Danh mục sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                decoration: InputDecoration(
                                  hintText: 'Tất cả danh mục',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                items: allCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                                onChanged: (v) => setState(() => selectedCategory = v!),
                              ),
                              const SizedBox(height: 24),
                              // Khoảng giá
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Khoảng giá', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  Text(
                                    '${numberFormat.format(priceRange.start)}đ - ${numberFormat.format(priceRange.end)}đ',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const _CustomBlueThumbShape(),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  activeTrackColor: Color(0xFF3a6ff8),
                                  inactiveTrackColor: Color(0xFF4CAF50),
                                  thumbColor: Colors.white,
                                  overlayColor: Color(0xFF3a6ff8).withOpacity(0.15),
                                ),
                                child: RangeSlider(
                                  values: priceRange,
                                  min: 3500,
                                  max: 65000,
                                  divisions: 100,
                                  onChanged: (RangeValues values) {
                                    setState(() {priceRange = values;});
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Tồn kho
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  Text(
                                    '${stockRange.start.round()} - ${stockRange.end.round()} sản phẩm',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const _CustomBlueThumbShape(),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  activeTrackColor: Color(0xFF3a6ff8),
                                  inactiveTrackColor: Color(0xFF4CAF50),
                                  thumbColor: Colors.white,
                                  overlayColor: Color(0xFF3a6ff8).withOpacity(0.15),
                                ),
                                child: RangeSlider(
                                  values: stockRange,
                                  min: 3,
                                  max: 120,
                                  divisions: 117,
                                  onChanged: (RangeValues values) {
                                    setState(() {stockRange = values;});
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Trạng thái
                              Text('Trạng thái sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'Tất cả',
                                    groupValue: status,
                                    onChanged: (v) => setState(() => status = v!),
                                  ),
                                  const Text('Tất cả'),
                                  const SizedBox(width: 16),
                                  Radio<String>(
                                    value: 'Còn bán',
                                    groupValue: status,
                                    onChanged: (v) => setState(() => status = v!),
                                  ),
                                  const Text('Còn bán'),
                                  const SizedBox(width: 16),
                                  Radio<String>(
                                    value: 'Ngừng bán',
                                    groupValue: status,
                                    onChanged: (v) => setState(() => status = v!),
                                  ),
                                  const Text('Ngừng bán'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Tags
                              Text('Tags', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: allTags.map((tag) {
                                  final isSelected = selectedTags.contains(tag);
                                  return FilterChip(
                                    label: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {selectedTags.add(tag);}
                                        else {selectedTags.remove(tag);}
                                      });
                                    },
                                    backgroundColor: isSelected ? Color(0xFF3a6ff8) : Colors.transparent,
                                    side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    showCheckmark: false,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              // Nút xóa bộ lọc
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
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text('Xóa bộ lọc'),
                                ),
                              ),
                            ],
                          ),
                        ),
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

                      if (sortedProducts.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(
                            child: Text(
                              'Không tìm thấy sản phẩm nào',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                            ),
                          ),
                        );
                      }
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

// Thêm class custom thumb shape cho slider
class _CustomBlueThumbShape extends RoundSliderThumbShape {
  const _CustomBlueThumbShape({double enabledThumbRadius = 10.0, double disabledThumbRadius = 10.0})
      : super(enabledThumbRadius: enabledThumbRadius, disabledThumbRadius: disabledThumbRadius);

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
    final double radius = isEnabled ? (enabledThumbRadius ?? 10.0) : (disabledThumbRadius ?? 10.0);
    final Paint fillPaint = Paint()..color = sliderTheme.thumbColor ?? Colors.white;
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF3a6ff8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);
  }
} 