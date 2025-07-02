import 'package:flutter/material.dart';
import '../../widgets/common/design_system_update.dart';
import '../../widgets/common/design_system.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../screens/customers/add_customer_screen.dart';
import '../../screens/customers/customer_detail_screen.dart';

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({Key? key}) : super(key: key);

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<_Product> _allProducts = [
    _Product(name: 'Vitamin tổng hợp cho mèo', price: 200000, stock: 15),
    _Product(name: 'Kháng sinh Amoxicillin', price: 120000, stock: 8),
    _Product(name: 'Sữa tắm cho chó', price: 90000, stock: 22),
    _Product(name: 'Thuốc nhỏ tai', price: 50000, stock: 5),
  ];
  List<_Product> _searchResults = [];
  List<_CartItem> _cart = [];

  // Khách hàng
  bool isRetailCustomer = true;
  final TextEditingController _customerController = TextEditingController();
  _CustomerInfo? _selectedCustomer;

  // Thanh toán
  String paymentMethod = 'Chuyển khoản';

  List<String> _mockCustomers = [
    'Nguyễn Văn A',
    'Trần Thị B',
    'Lê Văn C',
    'Phạm Thị D',
    'Ngô Văn E',
  ];
  List<String> _customerSearchResults = [];

  // 1. Thêm biến quản lý OverlayEntry và GlobalKey cho TextField
  final GlobalKey _searchFieldKey = GlobalKey();
  OverlayEntry? _searchOverlay;

  // Thêm biến selectedDemoCustomer và truyền vào _CustomerSection
  CustomerDemo? selectedDemoCustomer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
        _removeSearchOverlay();
      } else {
        _searchResults = _allProducts
            .where((p) => p.name.toLowerCase().contains(query))
            .toList();
        if (_searchResults.isNotEmpty) {
          _showSearchOverlay();
        } else {
          _removeSearchOverlay();
        }
      }
    });
  }

  void _onCustomerSearchChanged() {
    final query = _customerController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _customerSearchResults = [];
      } else {
        _customerSearchResults = _mockCustomers.where((c) => c.toLowerCase().contains(query)).toList();
      }
    });
  }

  void _addToCart(_Product product) {
    setState(() {
      final idx = _cart.indexWhere((item) => item.product.name == product.name);
      if (idx == -1) {
        _cart.add(_CartItem(product: product, quantity: 1));
      } else {
        _cart[idx].quantity++;
      }
      _searchController.clear();
      _searchResults = [];
    });
  }
 
  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _changeQuantity(int index, int delta) {
    setState(() {
      final item = _cart[index];
      item.quantity = (item.quantity + delta).clamp(1, item.product.stock);
    });
  }

  int get _total => _cart.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  @override
  void dispose() {
    _searchController.dispose();
    _customerController.dispose();
    _removeSearchOverlay();
    super.dispose();
  }

  void _removeSearchOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  void _showSearchOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeSearchOverlay();
      final renderBox = _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
      final offset = renderBox?.localToGlobal(Offset.zero);
      final width = renderBox?.size.width ?? MediaQuery.of(context).size.width;
      final top = (offset?.dy ?? 0) + (renderBox?.size.height ?? 0);
      _searchOverlay = OverlayEntry(
        builder: (context) => Stack(
          children: [
            // Lớp nền xám mờ phủ toàn màn hình
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeSearchOverlay,
                child: Container(
                  color: Colors.grey[200],
                ),
              ),
            ),
            // Dropdown nổi đúng vị trí dưới input
            Positioned(
              left: 0,
              right: 0,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: width,
                  constraints: const BoxConstraints(maxHeight: 320),
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (context, index) {
                      final product = _searchResults[index];
                      return InkWell(
                        onTap: () {
                          _addToCart(product);
                          _removeSearchOverlay();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatCurrency(product.price),
                                      style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Text('Kho: ${product.stock}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      Overlay.of(context).insert(_searchOverlay!);
    });
  }

  // 1. Thêm hàm mở modal tìm kiếm sản phẩm
  void _openProductSearchModal() async {
    final selected = await showModalBottomSheet<_Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[200],
      builder: (context) => _ProductSearchModal(
        allProducts: _allProducts,
      ),
    );
    if (selected != null) {
      _addToCart(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _OrderHeader(
                    onSearchTap: _openProductSearchModal,
                    showBack: _cart.isNotEmpty,
                  ),
                  _CustomerSection(
                    customer: _selectedCustomer,
                    selectedDemoCustomer: selectedDemoCustomer,
                    onSelectCustomer: (customer) {
                      setState(() {
                        selectedDemoCustomer = customer;
                      });
                    },
                  ),
                ],
              ),
            ),
            Container(height: 3, color: const Color(0xFFF0F4F0)),
            Expanded(
              child: _cart.isEmpty
                  ? const _EmptyCartIllustration()
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: _cart.length + 1, // +1 cho block chi tiết đơn hàng
                      itemBuilder: (context, index) {
                        if (index < _cart.length) {
                          final item = _cart[index];
                          return _CartItemWidget(
                            item: item,
                            onRemove: () => setState(() => _cart.removeAt(index)),
                            onIncrease: () => setState(() => item.quantity = (item.quantity + 1).clamp(1, item.product.stock)),
                            onDecrease: () => setState(() => item.quantity = (item.quantity - 1).clamp(1, item.product.stock)),
                            onDiscountChanged: (discountAmount, isPercentage) {
                              setState(() {
                                item.discountAmount = discountAmount;
                                item.isPercentageDiscount = isPercentage;
                              });
                            },
                          );
                        } else {
                          // Chỉ render 1 lần block chi tiết đơn hàng ở cuối danh sách
                          return OrderDetailSummary(cart: _cart);
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _cart.isNotEmpty
          ? _OrderBottomBar(
              total: _cart.fold(0, (sum, item) => sum + item.totalPrice),
              qty: _cart.fold(0, (sum, item) => sum + item.quantity),
              onContinue: () {
                if (selectedDemoCustomer == null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Thông báo'),
                      content: const Text('Vui lòng chọn khách hàng trước khi tiếp tục.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderPaymentScreen(
                        total: _cart.fold(0, (sum, item) => sum + item.totalPrice),
                      ),
                    ),
                  );
                }
              },
            )
          : null,
    );
  }
}

class _OrderHeader extends StatelessWidget {
  final VoidCallback onSearchTap;
  final bool showBack;
  const _OrderHeader({required this.onSearchTap, this.showBack = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // nền trắng
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  // Xóa hết item trong giỏ
                  final state = context.findAncestorStateOfType<_OrderCreateScreenState>();
                  state?._cart.clear();
                  state?.setState(() {});
                  // Quay lại màn hình tạo đơn lúc đầu
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            Expanded(
              child: GestureDetector(
                onTap: onSearchTap,
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tên, mã sản phẩm',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.density_medium, color: Color(0xFF16A34A)),
                        onPressed: () {},
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    enabled: false,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerSection extends StatelessWidget {
  final _CustomerInfo? customer;
  final CustomerDemo? selectedDemoCustomer;
  final Function(CustomerDemo?)? onSelectCustomer;
  const _CustomerSection({this.customer, this.selectedDemoCustomer, this.onSelectCustomer});
  @override
  Widget build(BuildContext context) {
    // Nếu đã chọn khách demo hoặc khách lẻ
    if (selectedDemoCustomer != null) {
      final c = selectedDemoCustomer!;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16), // tăng bottom
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CustomerPickerScreen(selectedCustomer: c)),
            );
            if (onSelectCustomer != null) {
              onSelectCustomer!(result is CustomerDemo ? result : null);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.person_add_alt, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    }
    // Nếu chưa chọn khách hàng
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16), // tăng bottom
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerPickerScreen()),
          );
          if (onSelectCustomer != null) {
            onSelectCustomer!(result is CustomerDemo ? result : null);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.person_add_alt, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCartIllustration extends StatelessWidget {
  const _EmptyCartIllustration();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SVG custom giỏ hàng trống
          SizedBox(
            width: 120,
            height: 120,
            child: SvgPicture.string(_cartSvg),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tìm kiếm sản phẩm để bắt đầu!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
          ),
        ],
      ),
    );
  }
}

const String _cartSvg = '''
<svg width="120" height="120" viewBox="0 0 120 120" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="60" r="60" fill="#F0F4F0"/>
  <rect x="34" y="54" width="52" height="28" rx="8" stroke="#9CCC65" stroke-width="3" fill="#fff"/>
  <rect x="42" y="62" width="16" height="8" rx="2" fill="#C8E6C9"/>
  <rect x="62" y="62" width="12" height="8" rx="2" fill="#C8E6C9"/>
  <rect x="80" y="62" width="8" height="8" rx="2" fill="#C8E6C9"/>
  <rect x="50" y="74" width="12" height="5" rx="2" fill="#F0F4F0"/>
  <rect x="62" y="74" width="12" height="5" rx="2" fill="#F0F4F0"/>
  <rect x="80" y="74" width="8" height="5" rx="2" fill="#F0F4F0"/>
  <circle cx="46" cy="92" r="6" stroke="#9CCC65" stroke-width="3" fill="#fff"/>
  <circle cx="86" cy="92" r="6" stroke="#9CCC65" stroke-width="3" fill="#fff"/>
  <rect x="58" y="44" width="12" height="14" rx="4" stroke="#9CCC65" stroke-width="2" fill="#fff"/>
  <rect x="62" y="36" width="4" height="10" rx="2" fill="#9CCC65"/>
  <path d="M40 54L64 44L88 54" stroke="#9CCC65" stroke-width="2" fill="none"/>
  <g opacity="0.2">
    <rect x="36" y="56" width="48" height="24" fill="#9CCC65"/>
  </g>
</svg>
''';

class _CartItemWidget extends StatelessWidget {
  final _CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final Function(int discountAmount, bool isPercentage) onDiscountChanged;
  const _CartItemWidget({
    required this.item, 
    required this.onRemove, 
    required this.onIncrease, 
    required this.onDecrease,
    required this.onDiscountChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onRemove(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Xóa',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            autoClose: true,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medical_services, color: Color(0xFF16A34A), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _formatCurrency(item.finalPrice) + '/đơn vị',
                            style: const TextStyle(color: Color(0xFF16A34A), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          if (item.discountAmount > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              _formatCurrency(item.product.price) + '/đơn vị',
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showDiscountDialog(context),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.local_offer_outlined, size: 16, color: Color(0xFF43A047)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onDecrease,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.remove, size: 16, color: Colors.black87),
                        ),
                      ),
                      Container(
                        width: 28,
                        alignment: Alignment.center,
                        child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      InkWell(
                        onTap: onIncrease,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.add, size: 16, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(item.totalPrice),
                  style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _DiscountDialog(
        originalPrice: item.product.price,
        onDiscountChanged: onDiscountChanged,
      ),
    );
  }
}

class _DiscountDialog extends StatefulWidget {
  final int originalPrice;
  final Function(int discountAmount, bool isPercentage) onDiscountChanged;
  
  const _DiscountDialog({
    required this.originalPrice,
    required this.onDiscountChanged,
  });

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  final TextEditingController _discountController = TextEditingController();
  bool _isPercentage = false;
  int _discountAmount = 0;

  @override
  void initState() {
    super.initState();
    _discountController.addListener(_onDiscountChanged);
  }

  void _onDiscountChanged() {
    String value = _discountController.text.replaceAll('.', '').replaceAll('đ', '');
    int intValue = int.tryParse(value) ?? 0;
    if (_isPercentage) {
      if (intValue > 100) intValue = 100;
      _discountController.value = TextEditingValue(
        text: intValue.toString(),
        selection: TextSelection.collapsed(offset: intValue.toString().length),
      );
    } else {
      // Định dạng tiền tệ khi nhập số tiền
      String formatted = _formatCurrency(intValue);
      _discountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length - 1),
      );
    }
    setState(() {
      _discountAmount = intValue;
    });
  }

  String _formatCurrency(int amount) {
    final s = amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$sđ';
  }

  int get _finalPrice {
    if (_isPercentage) {
      return widget.originalPrice - (widget.originalPrice * _discountAmount ~/ 100);
    } else {
      return widget.originalPrice - _discountAmount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                const Text('Chiết khấu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Toggle VNĐ/%
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isPercentage = false;
                      _discountController.text = _discountAmount > 0 ? _formatCurrency(_discountAmount) : '';
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isPercentage ? const Color(0xFFE8F5E9) : Colors.white,
                        border: Border.all(color: !_isPercentage ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('VNĐ', style: TextStyle(fontWeight: FontWeight.bold, color: !_isPercentage ? const Color(0xFF16A34A) : Colors.black)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isPercentage = true;
                      _discountController.text = _discountAmount > 0 ? _discountAmount.toString() : '';
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isPercentage ? const Color(0xFFE8F5E9) : Colors.white,
                        border: Border.all(color: _isPercentage ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('%', style: TextStyle(fontWeight: FontWeight.bold, color: _isPercentage ? const Color(0xFF16A34A) : Colors.black)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isPercentage ? 'Phần trăm chiết khấu' : 'Số tiền chiết khấu',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: _isPercentage ? '%' : 'đ',
              ),
            ),
            const SizedBox(height: 16),
            // Hiển thị giá mới
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Giá sau chiết khấu:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    _formatCurrency(_finalPrice),
                    style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onDiscountChanged(_discountAmount, _isPercentage);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                    child: const Text('Áp dụng', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  final List<_CartItem> cart;
  const _PaymentSummaryCard({required this.cart});
  @override
  Widget build(BuildContext context) {
    // TODO: build payment summary UI
    return Container();
  }
}

class _OrderBottomBar extends StatelessWidget {
  final int total;
  final int qty;
  final VoidCallback? onContinue;
  const _OrderBottomBar({required this.total, required this.qty, this.onContinue});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text('Tổng đơn hàng:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 15)),
                const SizedBox(width: 4),
                Text(_formatCurrency(total), style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                elevation: 0,
              ),
              child: const Text('Tiếp tục', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(int amount) {
  final s = amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$sđ';
}

// Demo models
class _CartItem {
  final _Product product;
  int quantity;
  int discountAmount;
  bool isPercentageDiscount;
  _CartItem({
    required this.product, 
    this.quantity = 1, 
    this.discountAmount = 0, 
    this.isPercentageDiscount = false,
  });
  
  int get finalPrice {
    if (isPercentageDiscount) {
      return product.price - (product.price * discountAmount ~/ 100);
    } else {
      return product.price - discountAmount;
    }
  }
  
  int get totalPrice => finalPrice * quantity;
}
class _Product {
  final String name;
  final int price;
  final int stock;
  _Product({required this.name, required this.price, required this.stock});
}
class _CustomerInfo {
  final String name;
  final String phone;
  final String? company;
  _CustomerInfo({required this.name, required this.phone, this.company});
}

// Thêm widget dialog chi tiết/chỉnh sửa khách hàng
class CustomerDetailDialog extends StatefulWidget {
  final _CustomerInfo customer;
  const CustomerDetailDialog({Key? key, required this.customer}) : super(key: key);

  @override
  State<CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends State<CustomerDetailDialog> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController birthdayController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController noteController;
  late TextEditingController companyController;
  late TextEditingController taxController;
  late TextEditingController companyAddressController;
  late TextEditingController invoiceEmailController;
  String gender = 'Chị';
  String customerType = 'Hộ gia đình';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.customer.name);
    phoneController = TextEditingController(text: widget.customer.phone);
    birthdayController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();
    noteController = TextEditingController();
    companyController = TextEditingController(text: widget.customer.company ?? '');
    taxController = TextEditingController();
    companyAddressController = TextEditingController();
    invoiceEmailController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    birthdayController.dispose();
    emailController.dispose();
    addressController.dispose();
    noteController.dispose();
    companyController.dispose();
    taxController.dispose();
    companyAddressController.dispose();
    invoiceEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text('Chỉnh sửa khách hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông tin cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'Anh',
                                groupValue: gender,
                                onChanged: (val) => setState(() => gender = val!),
                              ),
                              const Text('Anh'),
                              Radio<String>(
                                value: 'Chị',
                                groupValue: gender,
                                onChanged: (val) => setState(() => gender = val!),
                              ),
                              const Text('Chị'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: 'Họ và tên *'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            decoration: const InputDecoration(labelText: 'Số điện thoại *', hintText: 'Nhập số điện thoại'),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: birthdayController,
                            readOnly: false,
                            decoration: const InputDecoration(labelText: 'Ngày sinh', hintText: 'mm/dd/yyyy'),
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Địa chỉ'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: 'Ghi chú'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Hộ gia đình',
                          groupValue: customerType,
                          onChanged: (val) => setState(() => customerType = val!),
                        ),
                        const Text('Hộ gia đình'),
                        const SizedBox(width: 12),
                        Radio<String>(
                          value: 'Doanh nghiệp',
                          groupValue: customerType,
                          onChanged: (val) => setState(() => customerType = val!),
                        ),
                        const Text('Doanh nghiệp'),
                      ],
                    ),
                    if (customerType == 'Doanh nghiệp') ...[
                      TextField(
                        controller: companyController,
                        decoration: const InputDecoration(labelText: 'Tên tổ chức *'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: taxController,
                        decoration: const InputDecoration(labelText: 'Mã số thuế *'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: companyAddressController,
                        decoration: const InputDecoration(labelText: 'Địa chỉ tổ chức'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: invoiceEmailController,
                        decoration: const InputDecoration(labelText: 'Email nhận hóa đơn'),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                _CustomerInfo(
                                  name: nameController.text,
                                  phone: phoneController.text,
                                  company: companyController.text.isNotEmpty ? companyController.text : null,
                                ),
                              );
                            },
                            child: const Text('Lưu thay đổi'),
                          ),
                        ),
                      ],
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
}

// 2. Tạo widget modal tìm kiếm sản phẩm
class _ProductSearchModal extends StatefulWidget {
  final List<_Product> allProducts;
  const _ProductSearchModal({Key? key, required this.allProducts}) : super(key: key);

  @override
  State<_ProductSearchModal> createState() => _ProductSearchModalState();
}

class _ProductSearchModalState extends State<_ProductSearchModal> {
  final TextEditingController _controller = TextEditingController();
  List<_Product> _results = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final query = _controller.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _results = [];
      } else {
        _results = widget.allProducts.where((p) => p.name.toLowerCase().contains(query)).toList();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SafeArea(
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: top + 20, left: 16, right: 16, bottom: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Tìm sản phẩm...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _controller.clear(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                itemBuilder: (context, index) {
                  final product = _results[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop(product);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  _formatCurrency(product.price),
                                  style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Text('Kho: ${product.stock}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Thêm màn CustomerPickerScreen
class CustomerDemo {
  final String name;
  final String phone;
  final String? company;
  final int pendingInvoices;
  CustomerDemo({required this.name, required this.phone, this.company, this.pendingInvoices = 0});
}

class CustomerPickerScreen extends StatefulWidget {
  final CustomerDemo? selectedCustomer;
  const CustomerPickerScreen({Key? key, this.selectedCustomer}) : super(key: key);

  @override
  State<CustomerPickerScreen> createState() => _CustomerPickerScreenState();
}

class _CustomerPickerScreenState extends State<CustomerPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<CustomerDemo> _allCustomers;
  List<CustomerDemo> _filteredCustomers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _allCustomers = [
      CustomerDemo(name: 'Anh Nguyễn Văn An', phone: '0987888027', company: 'Công ty TNHH ABC'),
      CustomerDemo(name: 'Anh Đặng Quang Hải', phone: '0935295184', pendingInvoices: 1),
      CustomerDemo(name: 'Chị Tạ Thu Mai', phone: '0929255833'),
      CustomerDemo(name: 'Anh Phan Văn Nam', phone: '0970671202', company: 'Công ty TNHH GHI'),
      CustomerDemo(name: 'Chị Lưu Thị Oanh', phone: '0979335303'),
      CustomerDemo(name: 'Anh Cao Minh Phúc', phone: '0984642028'),
      CustomerDemo(name: 'Anh Võ Văn Rồng', phone: '0947191017', company: 'Công ty TNHH ABC'),
      CustomerDemo(name: 'Anh Nguyễn Văn An 2', phone: '0989821552', company: 'Công ty TNHH XYZ'),
      CustomerDemo(name: 'Anh Đặng Quang Hải 2', phone: '0908040458'),
      CustomerDemo(name: 'Chị Tạ Thu Mai 2', phone: '0936430149'),
      CustomerDemo(name: 'Anh Phan Văn Nam 2', phone: '0961811018', company: 'Công ty TNHH ABC'),
      CustomerDemo(name: 'Chị Lưu Thị Oanh 2', phone: '0946608872'),
      CustomerDemo(name: 'Anh Cao Minh Phúc 2', phone: '0998871366'),
      CustomerDemo(name: 'Anh Nguyễn Văn An 3', phone: '0991160345', company: 'Công ty TNHH DEF', pendingInvoices: 3),
      CustomerDemo(name: 'Anh Đặng Quang Hải 3', phone: '0919897526'),
      CustomerDemo(name: 'Anh Ngô Văn Inh 3', phone: '0910014555', company: 'Công ty TNHH ABC', pendingInvoices: 2),
    ];
    _filteredCustomers = _allCustomers;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCustomers = [];
      } else {
        _filteredCustomers = _allCustomers.where((c) => c.name.toLowerCase().contains(query) || c.phone.contains(query)).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedCustomer;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Khách hàng', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'SĐT/Tên',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
            ),
          ),
          // Hai nút trên cùng một dòng, chỉ hiện khi không search
          if (_searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, CustomerDemo(name: 'Khách lẻ', phone: ''));
                      },
                      icon: const Icon(Icons.person_outline, color: Colors.black),
                      label: const Text('Khách lẻ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: const Text('Khách hàng mới', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Hiển thị block thông tin khách hàng đã chọn, chỉ khi KHÔNG phải khách lẻ
          if (selected != null && selected.name != 'Khách lẻ')
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddCustomerScreen(
                        // Truyền thông tin khách hàng sang form
                        key: UniqueKey(),
                        // Ví dụ: initialName: selected.name, initialPhone: selected.phone, initialCompany: selected.company, ...
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0F5D8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${selected.name} - ${selected.phone}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            if (selected.company != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(selected.company!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('791 Đường ABC, Quận 12, TP.HCM', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Center(
                        child: Icon(Icons.chevron_right, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_searchQuery.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCustomers.length,
                itemBuilder: (context, index) {
                  final c = _filteredCustomers[index];
                  return InkWell(
                    onTap: () => Navigator.pop(context, c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                        color: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${c.name} - ${c.phone}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                            ],
                          ),
                          if (c.company != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 24, top: 2),
                              child: Text(c.company!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            ),
                          if (c.pendingInvoices > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 24, top: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.receipt_long, size: 14, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text('Hóa đơn chờ thanh toán (${c.pendingInvoices})', style: const TextStyle(fontSize: 13, color: Colors.red)),
                                ],
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
      backgroundColor: const Color(0xFFF9FAFB),
    );
  }
}

// Block Chi tiết đơn hàng
class OrderDetailSummary extends StatelessWidget {
  final List<_CartItem> cart;
  const OrderDetailSummary({required this.cart});
  @override
  Widget build(BuildContext context) {
    int totalQty = cart.fold(0, (sum, item) => sum + item.quantity);
    int totalAmount = cart.fold(0, (sum, item) => sum + item.product.price * item.quantity);
    int totalDiscount = cart.fold(0, (sum, item) => sum + (item.product.price - item.finalPrice) * item.quantity);
    int totalPay = cart.fold(0, (sum, item) => sum + item.totalPrice);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Text('Tổng số lượng')),
              Text('$totalQty'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Tổng tiền hàng')),
              Text(_formatCurrency(totalAmount)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Tổng chiết khấu')),
              Text('-' + _formatCurrency(totalDiscount)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Tổng thanh toán')),
              Text(_formatCurrency(totalPay), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderPaymentScreen extends StatefulWidget {
  final int total;
  const OrderPaymentScreen({Key? key, required this.total}) : super(key: key);
  @override
  State<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends State<OrderPaymentScreen> {
  int selectedPercent = 100;
  String? paymentMethod;
  final List<int> percents = [30, 50, 80, 100];

  int get selectedAmount {
    return ((widget.total * selectedPercent / 100).round() / 1000).round() * 1000;
  }

  String _formatCurrency(int amount) {
    final s = amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$sđ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Thanh toán', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF6F7F8),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng đơn hàng', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(_formatCurrency(widget.total), style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Chọn số tiền thanh toán', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 12),
                        child: OutlinedButton(
                          onPressed: () => setState(() => selectedPercent = percents[0]),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: selectedPercent == percents[0] ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                            backgroundColor: selectedPercent == percents[0] ? const Color(0xFFE8F5E9) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Column(
                            children: [
                              Text('${percents[0]}%', style: TextStyle(fontWeight: FontWeight.bold, color: selectedPercent == percents[0] ? const Color(0xFF16A34A) : Colors.black)),
                              const SizedBox(height: 2),
                              Text('~${_formatCurrency(((widget.total * percents[0] / 100).round() / 1000).round() * 1000)}', style: TextStyle(fontSize: 13, color: selectedPercent == percents[0] ? const Color(0xFF16A34A) : Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8, bottom: 12),
                        child: OutlinedButton(
                          onPressed: () => setState(() => selectedPercent = percents[1]),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: selectedPercent == percents[1] ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                            backgroundColor: selectedPercent == percents[1] ? const Color(0xFFE8F5E9) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Column(
                            children: [
                              Text('${percents[1]}%', style: TextStyle(fontWeight: FontWeight.bold, color: selectedPercent == percents[1] ? const Color(0xFF16A34A) : Colors.black)),
                              const SizedBox(height: 2),
                              Text('~${_formatCurrency(((widget.total * percents[1] / 100).round() / 1000).round() * 1000)}', style: TextStyle(fontSize: 13, color: selectedPercent == percents[1] ? const Color(0xFF16A34A) : Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () => setState(() => selectedPercent = percents[2]),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: selectedPercent == percents[2] ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                            backgroundColor: selectedPercent == percents[2] ? const Color(0xFFE8F5E9) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Column(
                            children: [
                              Text('${percents[2]}%', style: TextStyle(fontWeight: FontWeight.bold, color: selectedPercent == percents[2] ? const Color(0xFF16A34A) : Colors.black)),
                              const SizedBox(height: 2),
                              Text('~${_formatCurrency(((widget.total * percents[2] / 100).round() / 1000).round() * 1000)}', style: TextStyle(fontSize: 13, color: selectedPercent == percents[2] ? const Color(0xFF16A34A) : Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: OutlinedButton(
                          onPressed: () => setState(() => selectedPercent = percents[3]),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: selectedPercent == percents[3] ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                            backgroundColor: selectedPercent == percents[3] ? const Color(0xFFE8F5E9) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Column(
                            children: [
                              Text('${percents[3]}%', style: TextStyle(fontWeight: FontWeight.bold, color: selectedPercent == percents[3] ? const Color(0xFF16A34A) : Colors.black)),
                              const SizedBox(height: 2),
                              Text('~${_formatCurrency(((widget.total * percents[3] / 100).round() / 1000).round() * 1000)}', style: TextStyle(fontSize: 13, color: selectedPercent == percents[3] ? const Color(0xFF16A34A) : Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text('Chọn phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => paymentMethod = 'Tiền mặt'),
                    icon: Icon(Icons.attach_money, color: paymentMethod == 'Tiền mặt' ? const Color(0xFF16A34A) : Colors.black),
                    label: Text('Tiền mặt', style: TextStyle(fontWeight: FontWeight.bold, color: paymentMethod == 'Tiền mặt' ? const Color(0xFF16A34A) : Colors.black)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: paymentMethod == 'Tiền mặt' ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                      backgroundColor: paymentMethod == 'Tiền mặt' ? const Color(0xFFE8F5E9) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => paymentMethod = 'Chuyển khoản'),
                    icon: Icon(Icons.account_balance, color: paymentMethod == 'Chuyển khoản' ? const Color(0xFF16A34A) : Colors.black),
                    label: Text('Chuyển khoản', style: TextStyle(fontWeight: FontWeight.bold, color: paymentMethod == 'Chuyển khoản' ? const Color(0xFF16A34A) : Colors.black)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: paymentMethod == 'Chuyển khoản' ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                      backgroundColor: paymentMethod == 'Chuyển khoản' ? const Color(0xFFE8F5E9) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: paymentMethod == null ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderPaymentConfirmScreen(
                    amount: selectedAmount,
                    paymentMethod: paymentMethod!,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: paymentMethod == null ? const Color(0xFFBFEAD2) : const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('Thanh toán (${_formatCurrency(selectedAmount)})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class OrderPaymentConfirmScreen extends StatelessWidget {
  final int amount;
  final String paymentMethod;
  const OrderPaymentConfirmScreen({Key? key, required this.amount, required this.paymentMethod}) : super(key: key);
  String _formatCurrency(int amount) {
    final s = amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$sđ';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Xác nhận thanh toán', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF6F7F8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (paymentMethod == 'Chuyển khoản')
              Container(
                width: 160,
                height: 160,
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EBEE),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(child: Text('QR Code', style: TextStyle(color: Colors.black54))),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF16A34A)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Số tiền cần thanh toán:', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_formatCurrency(amount), style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const OrderInvoiceScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Hoàn tất & xem hoá đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class OrderInvoiceScreen extends StatelessWidget {
  const OrderInvoiceScreen({Key? key}) : super(key: key);
  String _formatCurrency(int amount) {
    final s = amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$sđ';
  }
  Widget _orderItem(String name, int qty, int price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('1 x ${_formatCurrency(price)}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
          Text(_formatCurrency(price), style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Hóa đơn', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.black),
                  onPressed: () {},
                  splashRadius: 22,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: IconButton(
                  icon: const Icon(Icons.download_outlined, color: Colors.black),
                  onPressed: () {},
                  splashRadius: 22,
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF6F7F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thông tin cửa hàng
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.inventory_2, color: Color(0xFF16A34A), size: 32),
                  ),
                  const SizedBox(height: 8),
                  const Text('VetPharm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Text('Nhà thuốc thú y', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  // Line phân cách giống các block khác, có padding 2 bên
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ),
                  // Mã hóa đơn và ngày tạo (căn đều 2 bên, label trái, value phải)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Mã hóa đơn:', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                            Text('#1751428257965', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Ngày tạo:', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                            Text('02/07/2025 - 10:50', style: TextStyle(fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Thông tin khách hàng
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.person_outline, size: 18, color: Color(0xFF16A34A)),
                      SizedBox(width: 6),
                      Text('Thông tin khách hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 10),
                  const Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Tên: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Nguyễn Văn An'),
                    ]),
                  ),
                  const Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'SĐT: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '0978513848'),
                    ]),
                  ),
                  const Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Địa chỉ: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '95 Đường ABC, Quận 9, TP.HCM'),
                    ]),
                  ),
                ],
              ),
            ),
            // Chi tiết đơn hàng (style lại từng item, line giữa các item)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.receipt_long, size: 18, color: Color(0xFF16A34A)),
                      SizedBox(width: 6),
                      Text('Chi tiết đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  _orderItemStyled('Thuốc tẩy giun cho chó Bayer Drontal Plus', 1, 275702),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  _orderItemStyled('Thuốc nhỏ mắt thú cưng AntiSeptic Eye Drop', 1, 443226),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  _orderItemStyled('Pate cho mèo Whiskas vị cá ngừ', 1, 308960),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  _orderItemStyled('Calcium bổ sung canxi cho chó con', 1, 186008),
                ],
              ),
            ),
            // Thông tin thanh toán (bỏ hết line, chỉ có line trên dòng Số tiền đã thanh toán)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.credit_card, size: 18, color: Color(0xFF16A34A)),
                      SizedBox(width: 6),
                      Text('Thông tin thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Phương thức:'),
                      Text('Chuyển Khoản', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền hàng:'),
                      Text(_formatCurrency(1233896)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Tổng chiết khấu:'),
                      Text('-20.000đ'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đã thanh toán:'),
                      Text(_formatCurrency(1210000)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Còn lại:'),
                      Text(_formatCurrency(3896)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Số tiền đã thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('1.210.000đ', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const OrderCreateScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Tạo đơn hàng mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

// Thêm hàm helper style cho item
Widget _orderItemStyled(String name, int qty, int price) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('1 x ${_formatCurrency(price)}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            ],
          ),
        ),
        Text(_formatCurrency(price), style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
} 