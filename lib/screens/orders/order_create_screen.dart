import 'package:flutter/material.dart';
import '../../widgets/common/design_system.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../screens/customers/add_customer_screen.dart';
import '../../screens/customers/customer_detail_screen.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../models/payment.dart';
import '../../services/product_service.dart';
import '../../services/customer_service.dart';
import '../../services/order_service.dart';
import '../../widgets/invoice_qr_code.dart';
import '../../services/app_payment_setting_service.dart';
import '../../models/app_payment_setting.dart';
import 'qr_scanner_screen.dart';

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({super.key});

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Services
  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();
  final OrderService _orderService = OrderService();
  
  // Real data
  List<Product> _allProducts = [];
  List<Product> _searchResults = [];
  final List<_CartItem> _cart = [];
  List<Customer> _allCustomers = [];
  
  // Customer selection
  Customer? selectedCustomer;
  bool isRetailCustomer = true;
  final TextEditingController _customerController = TextEditingController();
  List<Customer> _customerSearchResults = [];

  // Payment
  String paymentMethod = 'Chuyển khoản';

  // UI management
  final GlobalKey _searchFieldKey = GlobalKey();
  OverlayEntry? _searchOverlay;
  
  // Loading states
  bool _productsLoading = true;
  bool _customersLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadProducts(),
      _loadCustomers(),
    ]);
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getProducts().first;
      if (mounted) {
        setState(() {
          _allProducts = products;
          _productsLoading = false;
        });
      }
    } catch (e) {
      print('Error loading products: $e');
      if (mounted) {
        setState(() => _productsLoading = false);
      }
    }
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await _customerService.getCustomers().first;
      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _customersLoading = false;
        });
      }
    } catch (e) {
      print('Error loading customers: $e');
      if (mounted) {
        setState(() => _customersLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
        _removeSearchOverlay();
      } else {
        _searchResults = _allProducts
            .where((p) => p.tradeName.toLowerCase().contains(query) || 
                         p.internalName.toLowerCase().contains(query))
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
        _customerSearchResults = _allCustomers
            .where((c) => (c.name ?? '').toLowerCase().contains(query) || (c.phone ?? '').contains(query))
            .toList();
      }
    });
  }

  void _addToCart(Product product) {
    setState(() {
      final idx = _cart.indexWhere((item) => item.product.name == (product.tradeName.isNotEmpty ? product.tradeName : product.internalName));
      if (idx == -1) {
        final cartItem = _CartItem(
          product: _Product(
            name: product.tradeName.isNotEmpty ? product.tradeName : product.internalName,
            price: product.salePrice.toInt(),
            stock: product.stockSystem,
          ),
          quantity: 1,
        );
        _cart.add(cartItem);
      } else {
        // Tăng số lượng
        final item = _cart[idx];
        _cart[idx] = item.copyWith(
          quantity: item.quantity + 1,
        );
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
      final newQuantity = (item.quantity + delta).clamp(1, 999); // Giới hạn stock
      _cart[index] = item.copyWith(
        quantity: newQuantity,
      );
    });
  }

  double get _total => _cart.fold(0, (sum, item) => sum + item.totalPrice);

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
                      final productName = product.tradeName.isNotEmpty ? product.tradeName : product.internalName;
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
                                    Text(productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatCurrency(product.salePrice.toInt()),
                                      style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Text('Kho: ${product.stockSystem}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
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
    final selected = await showModalBottomSheet<Product>(
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

  // 2. Thêm hàm quét QR code
  void _openQRScanner() async {
    final qrCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    
    if (qrCode != null) {
      // Tìm sản phẩm theo mã QR
      final product = _findProductByQRCode(qrCode);
      if (product != null) {
        _addToCart(product);
        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm ${product.tradeName.isNotEmpty ? product.tradeName : product.internalName} vào giỏ hàng'),
              backgroundColor: mainGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Hiển thị thông báo không tìm thấy sản phẩm
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy sản phẩm với mã QR này'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // 3. Hàm tìm sản phẩm theo mã QR
  Product? _findProductByQRCode(String qrCode) {
    try {
      // Tìm kiếm theo barcode, SKU, hoặc ID sản phẩm
      return _allProducts.firstWhere(
        (product) => 
          (product.barcode?.toLowerCase() == qrCode.toLowerCase()) ||
          (product.sku?.toLowerCase() == qrCode.toLowerCase()) ||
          (product.id.toLowerCase() == qrCode.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _OrderHeader(
                        onSearchTap: _openProductSearchModal,
                        onQRScanTap: _openQRScanner,
                        showBack: _cart.isNotEmpty,
                      ),
                      _CustomerSection(
                        customer: selectedCustomer,
                        onSelectCustomer: (customer) {
                          setState(() {
                            selectedCustomer = customer;
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
                                onIncrease: () => _changeQuantity(index, 1),
                                onDecrease: () => _changeQuantity(index, -1),
                                onDiscountChanged: (discountAmount, isPercentage) {
                                  setState(() {
                                    _cart[index] = item.copyWith(
                                      discountAmount: discountAmount.toDouble(),
                                      isPercentageDiscount: isPercentage,
                                    );
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
        ),
      ),
      bottomNavigationBar: _cart.isNotEmpty
          ? _OrderBottomBar(
              total: _cart.fold(0.0, (sum, item) => sum + item.totalPrice).toInt(),
              qty: _cart.fold(0, (sum, item) => sum + item.quantity),
              onContinue: () {
                if (selectedCustomer == null) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Thông báo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Vui lòng chọn khách hàng trước khi tiếp tục.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Đóng',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderPaymentScreen(
                        total: _cart.fold(0.0, (sum, item) => sum + item.totalPrice).toInt(),
                        cart: List<_CartItem>.from(_cart),
                        customer: selectedCustomer!,
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
  final VoidCallback onQRScanTap;
  final bool showBack;
  const _OrderHeader({required this.onSearchTap, required this.onQRScanTap, this.showBack = false});
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
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: onSearchTap,
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tên, mã sản phẩm',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                  // QR Scanner button positioned on the right
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF16A34A)),
                        onPressed: onQRScanTap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerSection extends StatelessWidget {
  final Customer? customer;
  final Function(Customer?)? onSelectCustomer;
  const _CustomerSection({this.customer, this.onSelectCustomer});
  @override
  Widget build(BuildContext context) {
    // Nếu đã chọn khách hàng
    if (customer != null) {
      final c = customer!;
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
              onSelectCustomer!(result is Customer ? result : null);
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
                  child: Text(c.name ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
            onSelectCustomer!(result is Customer ? result : null);
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
                     SizedBox(
             width: 120,
             height: 120,
             child: SvgPicture.string(
               '''<svg width="120" height="120" viewBox="0 0 120 120" fill="none"><circle cx="60" cy="60" r="50" fill="#F0F4F0" opacity="0.6"></circle><path d="M35 45 L85 45 L82 75 L38 75 Z" fill="none" stroke="#9CCC65" stroke-width="2" rx="2"></path><path d="M35 45 L30 35 L25 35" stroke="#9CCC65" stroke-width="2.5" stroke-linecap="round" fill="none"></path><line x1="45" y1="50" x2="45" y2="70" stroke="#AED581" stroke-width="1.5"></line><line x1="55" y1="50" x2="55" y2="70" stroke="#AED581" stroke-width="1.5"></line><line x1="65" y1="50" x2="65" y2="70" stroke="#AED581" stroke-width="1.5"></line><line x1="75" y1="50" x2="75" y2="70" stroke="#AED581" stroke-width="1.5"></line><line x1="40" y1="55" x2="80" y2="55" stroke="#AED581" stroke-width="1.5"></line><line x1="40" y1="65" x2="80" y2="65" stroke="#AED581" stroke-width="1.5"></line><circle cx="45" cy="85" r="4" fill="#9CCC65"></circle><circle cx="75" cy="85" r="4" fill="#9CCC65"></circle><rect x="48" y="52" width="6" height="4" rx="1" fill="#C8E6C9"></rect><rect x="58" y="58" width="4" height="6" rx="1" fill="#C8E6C9"></rect><circle cx="70" cy="60" r="2" fill="#C8E6C9"></circle></svg>''',
               width: 120,
               height: 120,
             ),
           ),
          const SizedBox(height: 24),
          const Text(
            'Tìm kiếm sản phẩm để bắt đầu!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: mainGreen),
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
  final Function(double discountAmount, bool isPercentage) onDiscountChanged;
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
                            '${_formatCurrency(item.finalPrice.toInt())}/đơn vị',
                            style: const TextStyle(color: Color(0xFF16A34A), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          if (item.discountAmount > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${_formatCurrency(item.product.price)}/đơn vị',
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
                  _formatCurrency(item.totalPrice.toInt()),
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
        originalPrice: item.product.price.toInt(),
        onDiscountChanged: onDiscountChanged,
      ),
    );
  }
}

class _DiscountDialog extends StatefulWidget {
  final int originalPrice;
  final Function(double discountAmount, bool isPercentage) onDiscountChanged;
  
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
  double _discountAmount = 0;

  @override
  void initState() {
    super.initState();
    _discountController.addListener(_onDiscountChanged);
  }

  void _onDiscountChanged() {
    String value = _discountController.text.replaceAll('.', '').replaceAll('đ', '');
    double doubleValue = double.tryParse(value) ?? 0;
    
    if (_isPercentage) {
      if (doubleValue > 100) doubleValue = 100;
      _discountController.value = TextEditingValue(
        text: doubleValue.toString(),
        selection: TextSelection.collapsed(offset: doubleValue.toString().length),
      );
    } else {
      // Giới hạn chiết khấu không vượt quá giá gốc
      if (doubleValue > widget.originalPrice) {
        doubleValue = widget.originalPrice.toDouble();
      }
      // Định dạng tiền tệ khi nhập số tiền
      String formatted = _formatCurrency(doubleValue);
      _discountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length - 1),
      );
    }
    
    setState(() {
      _discountAmount = doubleValue;
    });
  }

  String _formatCurrency(double amount) {
    final s = amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$sđ';
  }

  double get _finalPrice {
    if (_isPercentage) {
      return widget.originalPrice - (widget.originalPrice * _discountAmount / 100);
    } else {
      return widget.originalPrice - _discountAmount;
    }
  }

  bool get _isValidDiscount {
    return _finalPrice >= 0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: !_isPercentage ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('VNĐ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: !_isPercentage ? const Color(0xFF16A34A) : Colors.black)),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _isPercentage ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('%', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _isPercentage ? const Color(0xFF16A34A) : Colors.black)),
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
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF16A34A)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                suffixText: _isPercentage ? '%' : 'đ',
              ),
            ),
            const SizedBox(height: 16),
            // Hiển thị giá mới
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isValidDiscount ? Colors.white : const Color(0xFFFFEBEE),
                border: Border.all(
                  color: _isValidDiscount ? const Color(0xFFE0E0E0) : Colors.red,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giá sau chiết khấu:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _isValidDiscount ? Colors.black : Colors.red,
                    ),
                  ),
                  Text(
                    _formatCurrency(_finalPrice),
                    style: TextStyle(
                      color: _isValidDiscount ? const Color(0xFF16A34A) : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (!_isValidDiscount) ...[
              const SizedBox(height: 8),
              Text(
                'Chiết khấu quá lớn! Giá sau chiết khấu không được âm.',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
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
                    onPressed: _isValidDiscount ? () {
                      widget.onDiscountChanged(_discountAmount, _isPercentage);
                      Navigator.pop(context);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValidDiscount ? const Color(0xFF16A34A) : Colors.grey,
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
  double discountAmount;
  bool isPercentageDiscount;
  _CartItem({
    required this.product,
    this.quantity = 1,
    this.discountAmount = 0.0,
    this.isPercentageDiscount = false,
  });
  
  double get finalPrice {
    if (isPercentageDiscount) {
      return product.price - (product.price * discountAmount / 100);
    } else {
      return product.price - discountAmount;
    }
  }
  
  double get totalPrice => finalPrice * quantity;
  
  _CartItem copyWith({
    _Product? product,
    int? quantity,
    double? discountAmount,
    bool? isPercentageDiscount,
  }) {
    return _CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
      isPercentageDiscount: isPercentageDiscount ?? this.isPercentageDiscount,
    );
  }
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
  const CustomerDetailDialog({super.key, required this.customer});

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
  final List<Product> allProducts;
  const _ProductSearchModal({super.key, required this.allProducts});

  @override
  State<_ProductSearchModal> createState() => _ProductSearchModalState();
}

class _ProductSearchModalState extends State<_ProductSearchModal> {
  final TextEditingController _controller = TextEditingController();
  List<Product> _results = [];

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
        _results = widget.allProducts.where((p) => 
          p.tradeName.toLowerCase().contains(query) || 
          p.internalName.toLowerCase().contains(query)
        ).toList();
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
                  final productName = product.tradeName.isNotEmpty ? product.tradeName : product.internalName;
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
                                Text(productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  _formatCurrency(product.salePrice.toInt()),
                                  style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Text('Kho: ${product.stockSystem}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
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
  final Customer? selectedCustomer;
  const CustomerPickerScreen({super.key, this.selectedCustomer});

  @override
  State<CustomerPickerScreen> createState() => _CustomerPickerScreenState();
}

class _CustomerPickerScreenState extends State<CustomerPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CustomerService _customerService = CustomerService();
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await _customerService.getCustomers().first;
      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _filteredCustomers = customers;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading customers: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCustomers = _allCustomers;
      } else {
        _filteredCustomers = _allCustomers.where((c) => 
          (c.name ?? '').toLowerCase().contains(query) || 
          (c.phone ?? '').contains(query)
        ).toList();
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
                        // Tạo customer retail
                        final retailCustomer = Customer(
                          id: 'retail',
                          name: 'Khách lẻ',
                          phone: '',
                        );
                        Navigator.pop(context, retailCustomer);
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
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                        );
                        // Nếu có customer mới được thêm, tự động chọn và trở về
                        if (result is Customer) {
                          Navigator.pop(context, result);
                        }
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
                      builder: (_) => CustomerDetailScreen(
                        customerId: selected.id,
                        onSuccess: () {
                          // Refresh customer data if needed
                        },
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
                            if (selected.companyId != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Công ty: ${selected.companyId}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                              ),
                            if (selected.address != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(selected.address!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
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
                          if (c.companyId != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 24, top: 2),
                              child: Text('Công ty: ${c.companyId}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            ),
                          if (c.address != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 24, top: 2),
                              child: Text(c.address!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
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
  const OrderDetailSummary({super.key, required this.cart});
  @override
  Widget build(BuildContext context) {
    int totalQty = cart.fold(0, (sum, item) => sum + item.quantity);
    double totalAmount = cart.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);
    double totalDiscount = cart.fold(0.0, (sum, item) => sum + item.discountAmount * item.quantity);
    double totalPay = cart.fold(0.0, (sum, item) => sum + item.totalPrice);
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
              Text(_formatCurrency(totalAmount.toInt())),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Tổng chiết khấu')),
              Text('-${_formatCurrency(totalDiscount.toInt())}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Tổng thanh toán')),
              Text(_formatCurrency(totalPay.toInt()), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderPaymentScreen extends StatefulWidget {
  final int total;
  final List<_CartItem> cart;
  final Customer customer;
  const OrderPaymentScreen({super.key, required this.total, required this.cart, required this.customer});
  @override
  State<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends State<OrderPaymentScreen> {
  int selectedPercent = 100;
  String? paymentMethod;
  final List<int> percents = [30, 50, 80, 100];
  bool _loading = false;

  int get selectedAmount {
    return ((widget.total * selectedPercent / 100).round() / 1000).round() * 1000;
  }

  String _formatCurrency(int amount) {
    final s = amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$sđ';
  }

  Future<void> _handlePayment() async {
    if (paymentMethod == null) return;
    setState(() => _loading = true);
    try {
      // 1. Tạo orderCode
      final orderService = OrderService();
      final orderCode = await orderService.generateOrderCode();
      
      // 2. Tính toán tổng tiền, chiết khấu, ...
      final totalAmount = widget.cart.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);
      final discountAmount = widget.cart.fold(0.0, (sum, item) => sum + item.discountAmount * item.quantity);
      final finalAmount = widget.cart.fold(0.0, (sum, item) => sum + item.totalPrice);
      
      // 3. Tạo Order object
      final order = Order(
        id: '',
        customerId: widget.customer.id,
        orderCode: orderCode,
        orderType: 'retail',
        createdBy: '', // TODO: lấy user hiện tại nếu có
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalAmount: totalAmount,
        discountAmount: discountAmount,
        finalAmount: finalAmount,
        paymentStatus: selectedAmount >= finalAmount ? 'paid' : 'partial',
        status: 'active',
        note: null,
        customerName: widget.customer.name,
        customerPhone: widget.customer.phone,
      );
      
      // 4. Tạo OrderItem objects từ cart
      final orderItems = widget.cart.map((cartItem) => OrderItem(
        id: '',
        orderId: '', // Sẽ được set trong service
        productId: cartItem.product.name, // TODO: Thêm productId vào _Product
        productName: cartItem.product.name,
        price: cartItem.product.price.toDouble(),
        quantity: cartItem.quantity,
        discountAmount: cartItem.discountAmount,
        isPercentageDiscount: cartItem.isPercentageDiscount,
        finalPrice: cartItem.finalPrice,
        totalPrice: cartItem.totalPrice,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();
      
      // 5. Tạo Payment object
      final payment = Payment.create(
        orderId: '',
        amount: selectedAmount.toDouble(),
        method: paymentMethod!,
        status: 'completed',
        reference: 'REF${DateTime.now().millisecondsSinceEpoch}',
        note: 'Thanh toán ${paymentMethod == 'cash' ? 'tiền mặt' : 'chuyển khoản'}',
      );
      
      // 6. Lưu order với separate collections
      final orderId = await orderService.createOrder(
        order: order,
        items: orderItems,
        payment: payment,
      );
      
      setState(() => _loading = false);
      // 7. Chuyển sang màn hình xác nhận/thành công
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderPaymentConfirmScreen(
              amount: selectedAmount,
              paymentMethod: paymentMethod!,
              order: order.copyWith(id: orderId),
              customer: widget.customer,
              orderItems: orderItems,
              payment: payment.copyWith(orderId: orderId),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lỗi'),
          content: Text('Không thể lưu đơn hàng: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tổng đơn hàng
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
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
                        const Text('Tổng đơn hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        Text(_formatCurrency(widget.total), style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                  ),
                ),
                // Chọn số tiền thanh toán
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chọn số tiền thanh toán', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 14),
                        Column(
                          children: [
                            Row(
                              children: [
                                for (int i = 0; i < 2; i++)
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(left: i == 0 ? 0 : 8, bottom: 8),
                                      child: OutlinedButton(
                                        onPressed: () => setState(() => selectedPercent = percents[i]),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: selectedPercent == percents[i] ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0), width: 1.5),
                                          backgroundColor: selectedPercent == percents[i] ? const Color(0xFFE8F5E9) : Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              '${percents[i]}%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: selectedPercent == percents[i] ? const Color(0xFF16A34A) : Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              percents[i] == 100
                                                ? _formatCurrency(((widget.total * percents[i] / 100).round() / 1000).round() * 1000)
                                                : '~${_formatCurrency(((widget.total * percents[i] / 100).round() / 1000).round() * 1000)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: selectedPercent == percents[i] ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Row(
                              children: [
                                for (int i = 2; i < 4; i++)
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(left: i == 2 ? 0 : 8),
                                      child: OutlinedButton(
                                        onPressed: () => setState(() => selectedPercent = percents[i]),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: selectedPercent == percents[i] ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0), width: 1.5),
                                          backgroundColor: selectedPercent == percents[i] ? const Color(0xFFE8F5E9) : Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              '${percents[i]}%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: selectedPercent == percents[i] ? const Color(0xFF16A34A) : Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              percents[i] == 100
                                                ? _formatCurrency(((widget.total * percents[i] / 100).round() / 1000).round() * 1000)
                                                : '~${_formatCurrency(((widget.total * percents[i] / 100).round() / 1000).round() * 1000)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: selectedPercent == percents[i] ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        if (selectedPercent != 100)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Còn lại', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                                Text(
                                  _formatCurrency(widget.total - selectedAmount),
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 17),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Chọn phương thức thanh toán
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chọn phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => paymentMethod = 'Tiền mặt'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: paymentMethod == 'Tiền mặt' ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0), width: 1.5),
                                  backgroundColor: paymentMethod == 'Tiền mặt' ? const Color(0xFFE8F5E9) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: Text('Tiền mặt', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black, fontSize: 14)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => paymentMethod = 'Chuyển khoản'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: paymentMethod == 'Chuyển khoản' ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0), width: 1.5),
                                  backgroundColor: paymentMethod == 'Chuyển khoản' ? const Color(0xFFE8F5E9) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: Text('Chuyển khoản', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black, fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
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
            onPressed: paymentMethod == null ? null : _handlePayment,
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
  final Order order;
  final Customer customer;
  final List<OrderItem> orderItems;
  final Payment payment;
  
  const OrderPaymentConfirmScreen({
    super.key, 
    required this.amount, 
    required this.paymentMethod,
    required this.order,
    required this.customer,
    required this.orderItems,
    required this.payment,
  });
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (paymentMethod == 'Chuyển khoản')
                FutureBuilder<AppPaymentSetting?>(
                  future: AppPaymentSettingService().getSetting(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    
                    final setting = snapshot.data;
                    if (setting == null || setting.bankCode.isEmpty || setting.bankAccount.isEmpty) {
                      return Container(
                        width: 350,
                        margin: const EdgeInsets.only(bottom: 32),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'Chưa cấu hình VietQR',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Vui lòng cấu hình thông tin ngân hàng trong Cài đặt > Cài đặt VietQR',
                              style: TextStyle(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // Tạo URL VietQR động
                    final qrUrl = 'https://img.vietqr.io/image/${setting.bankCode}-${setting.bankAccount}-compact2.png'
                        '?amount=$amount'
                        '&addInfo=Thanh+toan+don+${order.orderCode}';
                    
                    return Container(
                      width: 350,
                      margin: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        children: [
                          Image.network(
                            qrUrl,
                            width: 300,
                            height: 300,
                            errorBuilder: (context, error, stack) => const Text('Không tải được QR'),
                          ),
                        ],
                      ),
                    );
                  },
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
                MaterialPageRoute(builder: (_) => OrderInvoiceScreen(
                  order: order,
                  customer: customer,
                  orderItems: orderItems,
                  payment: payment,
                )),
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
  final Order order;
  final Customer customer;
  final List<OrderItem> orderItems;
  final Payment payment;
  
  const OrderInvoiceScreen({
    super.key, 
    required this.order, 
    required this.customer, 
    required this.orderItems, 
    required this.payment
  });
  
  String _formatCurrency(int amount) {
    final s = amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$sđ';
  }
  
  String _formatCurrencyDouble(double amount) {
    final s = amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$sđ';
  }
  
  Widget _orderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${item.price.toInt() != item.finalPrice.toInt() ? _formatCurrencyDouble(item.price) : ''}${item.price.toInt() != item.finalPrice.toInt() ? ' × ' : ''}${item.quantity}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                if (item.discountAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.isPercentageDiscount
                        ? 'Giảm: ${item.discountAmount.toStringAsFixed(0)}%'
                        : 'Giảm: ${_formatCurrencyDouble(item.discountAmount)}',
                      style: const TextStyle(color: Color(0xFF16A34A), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
          Text(_formatCurrencyDouble(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // Custom heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '#${order.orderCode}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Color(0xFF222B45),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
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
                         
                          const SizedBox(height: 8),
                          Image.asset(
                                'assets/images/logo.png',
                                width: 150,

                                fit: BoxFit.contain,
                              ),
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
                          
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Ngày tạo:', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                                    Text('${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year} - ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 15)),
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
                          Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'Tên: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: customer.name),
                            ]),
                          ),
                          // Chỉ hiển thị SĐT nếu không phải khách lẻ (có customerType khác 'individual')
                          if (customer.customerType != 'individual' && customer.phone != null && customer.phone!.isNotEmpty)
                            Text.rich(
                              TextSpan(children: [
                                const TextSpan(text: 'SĐT: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: customer.phone),
                              ]),
                            ),
                          if (customer.address != null)
                            Text.rich(
                              TextSpan(children: [
                                const TextSpan(text: 'Địa chỉ: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: customer.address!),
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
                          ...orderItems.map((item) => Column(
                            children: [
                              _orderItem(item),
                              if (item != orderItems.last) const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            ],
                          )),
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
                            children: [
                              const Text('Phương thức:'),
                              Text(payment.method, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng tiền hàng:'),
                              Text(_formatCurrencyDouble(order.totalAmount)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng chiết khấu:'),
                              Text('-${_formatCurrencyDouble(order.discountAmount)}', style: const TextStyle(color: Colors.red)),
                            ],
                          ),

                           const SizedBox(height: 8),     
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Số tiền đã thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(_formatCurrencyDouble(payment.amount), style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Đã thanh toán:'),
                              Text(_formatCurrencyDouble(payment.amount)),
                            ],
                          ),
                             const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Còn lại:'),
                              Text(_formatCurrencyDouble(order.finalAmount - payment.amount), style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
            // Nút tạo đơn hàng mới vẫn ở dưới cùng
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Tạo đơn hàng mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
      // Xóa AppBar và bottomNavigationBar cũ
    );
  }
}

 