import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:intl/intl.dart' show NumberFormat;
import '../widgets/main_layout.dart';

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

final List<Product> mockProducts = [
  Product(
    id: '1',
    name: 'Amoxicillin 250mg',
    description: 'Amoxicillin',
    barcode: '8935001730025',
    tags: ['kháng sinh', 'phổ rộng'],
    price: 3500,
    stock: 120,
    category: 'Kháng sinh',
    isActive: true,
  ),
  Product(
    id: '2',
    name: 'Vitamin C 500mg',
    description: 'Bổ sung vitamin',
    barcode: '8935001730026',
    tags: ['vitamin', 'bổ sung'],
    price: 5000,
    stock: 80,
    category: 'Vitamin',
    isActive: true,
  ),
  Product(
    id: '3',
    name: 'NSAID 100mg',
    description: 'Giảm đau, chống viêm',
    barcode: '8935001730027',
    tags: ['NSAID', 'giảm đau'],
    price: 65000,
    stock: 10,
    category: 'Giảm đau',
    isActive: false,
  ),
  Product(
    id: '4',
    name: 'Quinolone 200mg',
    description: 'Kháng sinh nhóm quinolone',
    barcode: '8935001730028',
    tags: ['kháng sinh', 'quinolone'],
    price: 12000,
    stock: 50,
    category: 'Kháng sinh',
    isActive: true,
  ),
  Product(
    id: '5',
    name: 'Bổ sung kẽm',
    description: 'Hỗ trợ miễn dịch',
    barcode: '8935001730029',
    tags: ['bổ sung'],
    price: 15000,
    stock: 30,
    category: 'Bổ sung',
    isActive: true,
  ),
];

class ProductListScreen extends StatefulWidget {
  final Function(MainPage)? onNavigate;
  const ProductListScreen({super.key, this.onNavigate});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
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

  List<String> get allCategories =>
      ['Tất cả', ...{for (var p in mockProducts) p.category}];
  List<String> get allTags =>
      {for (var p in mockProducts) ...p.tags}.toList();

  List<Product> get filteredProducts {
    List<Product> list = mockProducts.where((p) {
      if (selectedCategory != 'Tất cả' && p.category != selectedCategory) return false;
      if (p.price < priceRange.start || p.price > priceRange.end) return false;
      if (p.stock < stockRange.start || p.stock > stockRange.end) return false;
      if (status == 'Còn bán' && !p.isActive) return false;
      if (status == 'Ngừng bán' && p.isActive) return false;
      if (selectedTags.isNotEmpty && !selectedTags.any((tag) => p.tags.contains(tag))) return false;
      if (searchText.isNotEmpty && !(p.name.toLowerCase().contains(searchText.toLowerCase()) || p.barcode.contains(searchText))) return false;
      return true;
    }).toList();

    switch (sortOption) {
      case 'name_asc':
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'stock_asc':
        list.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'stock_desc':
        list.sort((a, b) => b.stock.compareTo(a.stock));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###', 'vi_VN');
    return Scaffold(
      body: Column(
        children: [
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
          // Thanh tìm kiếm
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
                      filled: false,
                      fillColor: null,
                      isDense: true,
                    ),
                  ),
                  Positioned(
                    right: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          // TODO: Implement barcode scanning
                        },
                        child: Container(
                           width: 28,
                           height: 28,
                           decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                           child: Icon(Icons.qr_code_scanner, color: Colors.blue, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ),
          const SizedBox(height: 16),
          // Bộ lọc và sắp xếp căn đều 2 bên
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            isFilterOpen = !isFilterOpen;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF7F8FA),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          side: BorderSide(color: Colors.grey.shade400, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.filter_list, size: 20),
                            const SizedBox(width: 8),
                            const Text('Bộ lọc'),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          setState(() {
                            sortOption = value;
                          });
                        },
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        color: const Color(0xFFF7F8FA),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('Sắp xếp theo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                            ),
                          ),
                          ...sortOptions.map((opt) => PopupMenuItem<String>(
                                value: opt['key'],
                                child: Row(
                                  children: [
                                    Icon(opt['icon'], size: 18, color: Colors.black54),
                                    const SizedBox(width: 8),
                                    Text(opt['label'], style: const TextStyle(fontSize: 15, color: Colors.black)),
                                    if (sortOption == opt['key']) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text('Đang chọn', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ]
                                  ],
                                ),
                              ))
                        ],
                        child: OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF7F8FA),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sort, size: 20, color: Colors.black),
                              const SizedBox(width: 8),
                              const Text('Sắp xếp', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Card bộ lọc (ẩn/hiện)
          if (isFilterOpen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                margin: const EdgeInsets.only(top: 0, bottom: 0),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Danh mục
                      Text('Danh mục sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.transparent,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(5),
                            style: const TextStyle(fontSize: 13, color: Colors.black),
                            iconSize: 16,
                            dropdownColor: Colors.white,
                            isDense: true,
                            itemHeight: 48,
                            items: allCategories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                        child: Text(c),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => selectedCategory = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Giá
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Khoảng giá', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('${priceRange.start.toInt()}đ - ${priceRange.end.toInt()}đ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const BlueBorderThumbShape(
                            enabledThumbRadius: 9,
                            disabledThumbRadius: 9,
                          ),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: Colors.blue,
                          inactiveTrackColor: Colors.green.shade400,
                          thumbColor: Colors.white,
                          overlayColor: Colors.blue.withOpacity(0.2),
                          activeTickMarkColor: Colors.blue,
                          inactiveTickMarkColor: Colors.green.shade400,
                        ),
                        child: RangeSlider(
                          min: 3500,
                          max: 65000,
                          divisions: 10,
                          values: priceRange,
                          labels: RangeLabels(
                            '${priceRange.start.toInt()}đ',
                            '${priceRange.end.toInt()}đ',
                          ),
                          onChanged: (v) => setState(() => priceRange = v),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tồn kho
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('${stockRange.start.toInt()} - ${stockRange.end.toInt()} sản phẩm', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const BlueBorderThumbShape(
                            enabledThumbRadius: 9,
                            disabledThumbRadius: 9,
                          ),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: Colors.blue,
                          inactiveTrackColor: Colors.green.shade400,
                          thumbColor: Colors.white,
                          overlayColor: Colors.blue.withOpacity(0.2),
                          activeTickMarkColor: Colors.blue,
                          inactiveTickMarkColor: Colors.green.shade400,
                        ),
                        child: RangeSlider(
                          min: 3,
                          max: 120,
                          divisions: 10,
                          values: stockRange,
                          labels: RangeLabels(
                            '${stockRange.start.toInt()}',
                            '${stockRange.end.toInt()}',
                          ),
                          onChanged: (v) => setState(() => stockRange = v),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Trạng thái
                      Text('Trạng thái sản phẩm', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'Tất cả',
                            groupValue: status,
                            onChanged: (v) => setState(() => status = v!),
                          ),
                          const Text('Tất cả'),
                          const SizedBox(width: 32),
                          Radio<String>(
                            value: 'Còn bán',
                            groupValue: status,
                            onChanged: (v) => setState(() => status = v!),
                          ),
                          const Text('Còn bán'),
                          const SizedBox(width: 32),
                          Radio<String>(
                            value: 'Ngừng bán',
                            groupValue: status,
                            onChanged: (v) => setState(() => status = v!),
                          ),
                          const Text('Ngừng bán'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Tags
                      Text('Tags', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allTags
                            .map((tag) => FilterChip(
                                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                                  selected: selectedTags.contains(tag),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedTags.add(tag);
                                      } else {
                                        selectedTags.remove(tag);
                                      }
                                    });
                                  },
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  backgroundColor: Colors.grey[100],
                                  padding: const EdgeInsets.all(0),
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: -2),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                      // Nút xóa bộ lọc căn giữa
                       Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory = 'Tất cả';
                                priceRange = const RangeValues(3500, 65000);
                                stockRange = const RangeValues(3, 120);
                                status = 'Tất cả';
                                selectedTags.clear();
                                searchText = '';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[800],
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade400, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Xoá bộ lọc'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Danh sách sản phẩm
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final p = filteredProducts[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                  ),
                  elevation: 0,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thông tin sản phẩm bên trái
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(p.description, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                              const SizedBox(height: 2),
                              Text('Mã vạch: ${p.barcode}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: p.tags.map((tag) => Chip(
                                  label: Text(tag, style: const TextStyle(fontWeight: FontWeight.w500)),
                                   padding: const EdgeInsets.all(0),
                                   labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: -2),
                                   visualDensity: VisualDensity.compact,
                                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                        // Giá và số lượng căn trái
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${numberFormat.format(p.price)}đ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 22)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text('Số lượng:', style: TextStyle(fontSize: 15, color: Colors.black54)),
                                  const SizedBox(width: 4),
                                  Text('${p.stock}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Nút sửa bên phải
                        Container(
                          margin: const EdgeInsets.only(left: 24),
                          child: Material(
                            color: const Color(0xFFF7F8FA),
                            shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(5),
                              side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black87),
                              onPressed: () {},
                              tooltip: 'Sửa sản phẩm',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 