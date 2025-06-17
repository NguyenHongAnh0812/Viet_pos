import 'package:flutter/material.dart';
import '../screens/product_list_screen.dart';
import '../screens/product_category_screen.dart';
import '../screens/add_product_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../models/product.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/low_stock_products_screen.dart';
import '../screens/add_product_category_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/inventory_history_screen.dart';
import 'common/design_system.dart';
import '../screens/style_guide_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/product_service.dart';
import '../screens/invoice_import_list_screen.dart';
import '../screens/invoice_import_screen.dart';
import '../screens/inventory_detail_screen.dart';
import '../screens/inventory_create_session_screen.dart';
import '../screens/distributor_screen.dart';
import '../screens/settings_screen.dart';

// Định nghĩa enum cho các trang
enum MainPage { dashboard, productList, productCategory, addProduct, inventory, report, settings, productDetail, lowStockProducts, addProductCategory, inventoryHistory, styleGuide, invoiceImportList, invoiceImport, inventoryDetail, inventoryCreateSession, distributor }

class MainLayout extends StatefulWidget {
  final Widget? child; // Không cần truyền child nữa, sẽ render theo _currentPage
  const MainLayout({super.key, this.child});

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  bool _sidebarOpen = false;
  int _selectedIndex = 0;
  MainPage _currentPage = MainPage.dashboard;
  MainPage? _previousPage;
  Product? _selectedProduct;
  bool isFilterSidebarOpen = false;

  // Filter state
  List<String> categories = ['Tất cả', 'Kháng sinh', 'Vitamin', 'Bổ sung', 'NSAID'];
  List<String> tags = [
    'antibiotic', 'prescription', 'vitamin', 'supplement', 'flea', 'tick', 'pet care',
    'dewormer', 'injection', 'livestock', 'pain relief', 'anti-inflammatory',
    'anesthetic', 'sedative', 'veterinary', 'analgesic', 'parasiticide', 'poultry'
  ];
  String selectedCategory = 'Tất cả';
  RangeValues priceRange = const RangeValues(0, 1000000);
  RangeValues stockRange = const RangeValues(0, 99999);
  String status = 'Tất cả';
  Set<String> selectedTags = {};

  // Key để rebuild ProductListScreen
  int productListKey = 0;

  String? _selectedInventorySessionId;

  @override
  void initState() {
    super.initState();
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
    });
  }

  void _openFilterSidebar() {
    setState(() {
      isFilterSidebarOpen = true;
    });
  }

  void _closeFilterSidebar() {
    setState(() {
      isFilterSidebarOpen = false;
    });
  }

  void _applyFilter({
    required String category,
    required RangeValues price,
    required RangeValues stock,
    required String statusValue,
    required Set<String> tagsValue,
  }) {
    setState(() {
      selectedCategory = category;
      priceRange = price;
      stockRange = stock;
      status = statusValue;
      selectedTags = tagsValue;
      isFilterSidebarOpen = false;
    });
  }

  void _resetFilter() {
    setState(() {
      selectedCategory = 'Tất cả';
      priceRange = const RangeValues(0, 1000000);
      stockRange = const RangeValues(0, 99999);
      status = 'Tất cả';
      selectedTags.clear();
    });
  }

  // Thêm hàm mới để cập nhật filter ranges
  void updateFilterRanges(List<Product> products) {
    if (products.isNotEmpty) {
      int newMinStock = products.map((p) => p.stockSystem).reduce((a, b) => a < b ? a : b);
      int newMaxStock = products.map((p) => p.stockSystem).reduce((a, b) => a > b ? a : b);
      double newMinPrice = products.map((p) => p.salePrice).reduce((a, b) => a < b ? a : b);
      double newMaxPrice = products.map((p) => p.salePrice).reduce((a, b) => a > b ? a : b);

      // Clamp lại giá trị filter hiện tại để không vượt quá min/max mới
      double newStartPrice = priceRange.start.clamp(newMinPrice, newMaxPrice);
      double newEndPrice = priceRange.end.clamp(newMinPrice, newMaxPrice);
      double newStartStock = stockRange.start.clamp(newMinStock.toDouble(), newMaxStock.toDouble());
      double newEndStock = stockRange.end.clamp(newMinStock.toDouble(), newMaxStock.toDouble());

      setState(() {
        stockRange = RangeValues(newStartStock, newEndStock);
        priceRange = RangeValues(newStartPrice, newEndPrice);
      });
    } else {
      // Nếu không có sản phẩm, min/max là 0-0
      setState(() {
        stockRange = const RangeValues(0, 0);
        priceRange = const RangeValues(0, 0);
      });
    }
  }

  void onSidebarTap(MainPage page) {
    setState(() {
      if (page == MainPage.productList) {
        _resetFilter();
      }
      _previousPage = _currentPage;
      _currentPage = page;
      if (MediaQuery.of(context).size.width < 1024) {
        _sidebarOpen = false;
      }
      if (page != MainPage.inventoryDetail) {
        _selectedInventorySessionId = null;
      }
    });
  }

  // Phương thức quay lại trang trước
  void _goBack() {
    setState(() {
      if (_previousPage != null) {
        _currentPage = _previousPage!;
        _previousPage = null; // Xóa trang trước đó sau khi quay lại
      } else {
        // Nếu không có trang trước, quay về trang mặc định (ví dụ: productList)
        _currentPage = MainPage.productList;
      }
    });
  }

  // Điều hướng mở chi tiết sản phẩm
  void _openProductDetail(Product product) {
    setState(() {
      _previousPage = _currentPage;
      _currentPage = MainPage.addProduct; // Tạm dùng addProduct, sẽ sửa lại bên dưới
      _selectedProduct = product;
      _currentPage = MainPage.productDetail;
    });
  }

  // Điều hướng mở form sửa sản phẩm
  void _openEditProduct(Product product) {
    setState(() {
      _previousPage = _currentPage;
      _currentPage = MainPage.addProduct;
      _selectedProduct = product;
    });
  }

  // Điều hướng mở lại danh sách sản phẩm
  void _openProductList() {
    setState(() {
      // Reset toàn bộ filter về mặc định
      selectedCategory = 'Tất cả';
      priceRange = const RangeValues(0, 1000000);
      stockRange = const RangeValues(0, 99999);
      status = 'Tất cả';
      selectedTags = {};
      _resetFilter();
      _currentPage = MainPage.productList;
      _selectedProduct = null;
      productListKey++;
    });
  }

  void _openLowStockProducts() {
    setState(() {
      _previousPage = _currentPage;
      _currentPage = MainPage.lowStockProducts;
    });
  }

  void reloadProducts() {
    // This method is now empty as the product data is fetched in initState
  }

  void openInventoryDetail(String sessionId) {
    setState(() {
      _selectedInventorySessionId = sessionId;
      _previousPage = _currentPage;
      _currentPage = MainPage.inventoryDetail;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 1024;
              if (isMobile) {
                // MOBILE: Stack + AnimatedSlide
                return Stack(
                  children: [
                    Column(
                      children: [
                        _Header(onMenuPressed: _toggleSidebar),
                        Expanded(child: _buildMainContent()),
                      ],
                    ),
                    if (_sidebarOpen)
                      GestureDetector(
                        onTap: _toggleSidebar,
                        child: Container(color: Colors.black.withOpacity(0.3)),
                      ),
                    AnimatedSlide(
                      offset: _sidebarOpen ? Offset(0, 0) : Offset(-1, 0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                      child: SizedBox(
                        width: 290,
                        child: _Sidebar(
                          isOpen: true,
                          currentPage: _currentPage,
                          onItemTap: onSidebarTap,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // DESKTOP: Row + AnimatedContainer
                return Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 290,
                      child: _Sidebar(
                        isOpen: true,
                        currentPage: _currentPage,
                        onItemTap: onSidebarTap,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _Header(onMenuPressed: _toggleSidebar),
                          Expanded(child: _buildMainContent()),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          bottomNavigationBar: MediaQuery.of(context).size.width < 1024
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NavItem(
                            icon: SvgPicture.asset(
                              'assets/icons/databoard.svg',
                              width: 16,
                              height: 16,
                            ),
                            label: 'Trang chủ',
                            selected: _currentPage == MainPage.dashboard,
                            onTap: () => _onNavTap(0),
                          ),
                          _NavItem(
                            icon: SvgPicture.asset(
                              'assets/icons/inventory.svg',
                              width: 16,
                              height: 16,
                            ),
                            label: 'Kiểm kê',
                            selected: _currentPage == MainPage.inventory,
                            onTap: () => _onNavTap(1),
                          ),
                          _NavCenterButton(
                            icon: Icon(Icons.add, size: 24, color: Colors.white,),
                            label: 'Thêm mới',
                            onTap: () => onSidebarTap(MainPage.addProduct),
                          ),
                          _NavItem(
                            icon: SvgPicture.asset(
                              'assets/icons/products.svg',
                              width: 16,
                              height: 16,
                            ),
                            label: 'Sản phẩm',
                            selected: _currentPage == MainPage.productList,
                            onTap: () => _onNavTap(2),
                          ),
                          _NavItem(
                            icon: SvgPicture.asset(
                              'assets/icons/report.svg',
                              width: 16,
                              height: 16,
                            ),
                            label: 'Báo cáo',
                            selected: _currentPage == MainPage.report,
                            onTap: () => _onNavTap(3),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
        ),
        // Overlay + Sidebar Filter
        if (isFilterSidebarOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeFilterSidebar,
              child: Container(color: Colors.black.withOpacity(0.8)),
            ),
          ),
          AnimatedSlide(
            offset: isFilterSidebarOpen ? Offset(0, 0) : Offset(1, 0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 340,
                child: Material(
                  elevation: 8,
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(0), bottomLeft: Radius.circular(0)),
                  child: SafeArea(
                    child: FilterSidebarContent(
                      onClose: _closeFilterSidebar,
                      categories: categories,
                      tags: tags,
                      selectedCategory: selectedCategory,
                      priceRange: priceRange,
                      stockRange: stockRange,
                      status: status,
                      selectedTags: selectedTags,
                      onApply: _applyFilter,
                      onReset: _resetFilter,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainContent() {
    switch (_currentPage) {
      case MainPage.dashboard:
        return DashboardScreen(
          onViewProductList: () => onSidebarTap(MainPage.productList),
          onViewLowStockProducts: _openLowStockProducts,
        );
      case MainPage.productList:
        return ProductListScreen(
          key: ValueKey('product-list-$productListKey'),
          onProductTap: _openProductDetail,
          onNavigate: onSidebarTap,
          onOpenFilterSidebar: _openFilterSidebar,
          filterCategory: selectedCategory,
          filterPriceRange: priceRange,
          filterStockRange: stockRange,
          filterStatus: status,
          filterTags: selectedTags,
          isLoadingProducts: false,
          onReloadProducts: reloadProducts,
        );
      case MainPage.productCategory:
        return ProductCategoryScreen(
           onNavigate: onSidebarTap,
        );
      case MainPage.addProduct:
        return AddProductScreen(
          product: null,
          isEdit: false,
          onBack: _openProductList,
        );
      case MainPage.productDetail:
        return ProductDetailScreen(
          product: _selectedProduct!,
          onBack: _openProductList,
        );
      case MainPage.inventory:
        return InventoryScreen(
          onBack: () {
            setState(() {
              _currentPage = MainPage.dashboard;
            });
          },
          onViewHistory: () {
            setState(() {
              _currentPage = MainPage.inventoryHistory;
            });
          },
        );
      case MainPage.inventoryHistory:
        return InventoryHistoryScreen(
          onBack: () {
            setState(() {
              _currentPage = MainPage.inventory;
            });
          },
        );
      case MainPage.report:
        return Center(child: Text('Báo cáo (chưa cài đặt)'));
      case MainPage.settings:
        return SettingsScreen(
          onBack: () {
            setState(() {
              _currentPage = MainPage.dashboard;
            });
          },
        );
      case MainPage.lowStockProducts:
        return LowStockProductsScreen(
          onBack: () {
            setState(() {
              _currentPage = MainPage.dashboard;
            });
          },
          onEditProduct: (product) {
            setState(() {
              _previousPage = _currentPage;
              _currentPage = MainPage.addProduct;
              _selectedProduct = product;
            });
          },
        );
      case MainPage.addProductCategory:
        return AddProductCategoryScreen(
          onBack: () {
            setState(() {
              _currentPage = MainPage.productCategory;
            });
          },
        );
      case MainPage.styleGuide:
        return const StyleGuideScreen();
      case MainPage.invoiceImportList:
        return const InvoiceImportListScreen();
      case MainPage.invoiceImport:
        return const InvoiceImportScreen();
      case MainPage.inventoryDetail:
        if (_selectedInventorySessionId == null) return const SizedBox();
        return InventoryDetailScreen(sessionId: _selectedInventorySessionId!);
      case MainPage.inventoryCreateSession:
        return InventoryCreateSessionScreen();
      case MainPage.distributor:
        return DistributorScreen();
      default:
        return const DashboardScreen();
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
      // Logic điều hướng cho BottomNavigationBar
      switch (index) {
        case 0:
          onSidebarTap(MainPage.dashboard);
          break;
        case 1:
          onSidebarTap(MainPage.inventory);
          break;
        case 2:
          // Khi nhấn Sản phẩm trên bottom nav, đi tới ProductList
          onSidebarTap(MainPage.productList);
          break;
        case 3:
          // Khi nhấn Báo cáo trên bottom nav, đi tới Report
          onSidebarTap(MainPage.report);
          break;
      }
    });
  }
}

// Header widget
class _Header extends StatelessWidget {
  final VoidCallback onMenuPressed;
  const _Header({required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width < 1024)
            IconButton(
              icon: SvgPicture.asset('assets/icons/menu.svg', width: 16, height: 16),
              onPressed: onMenuPressed,
            ),
          const SizedBox(width: 8),
          const Text(
            'VET-POS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }
}

// Sidebar widget
class _Sidebar extends StatefulWidget {
  final bool isOpen;
  final MainPage currentPage;
  final Function(MainPage) onItemTap;
  const _Sidebar({this.isOpen = true, required this.currentPage, required this.onItemTap});

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  // Trạng thái mở/đóng cho từng mục cha
  Map<String, bool> _openMenus = {
    'product': false,
    'order': false,
    'customer': false,
    'promotion': false,
  };

  Widget _sidebarParentItem({
    required Widget icon,
    required String label,
    required bool open,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return _SidebarParentItemWidget(
      icon: icon,
      label: label,
      open: open,
      onTap: onTap,
      selected: selected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isOpen ? 290 : 70,
      decoration: BoxDecoration(
      color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Dashboard

             // Logo VET-POS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/tag_icon.svg', // thay bằng icon logo của bạn
                    width: 20,
                    height: 20,
                    color: primaryBlue, // hoặc để nguyên nếu SVG có màu sẵn
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VET-POS',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),

          _SidebarItem(
            icon: SvgPicture.asset('assets/icons/databoard.svg', width: 16, height: 16),    
            label: 'Dashboard',
            selected: widget.currentPage == MainPage.dashboard,
            isOpen: widget.isOpen,
            onTap: () => widget.onItemTap(MainPage.dashboard),
          ),
          // Sản phẩm
          _sidebarParentItem(
            icon: SvgPicture.asset('assets/icons/products.svg', width: 16, height: 16),
            label: 'Sản phẩm',
            open: _openMenus['product']!,
            selected: false,
            onTap: () => setState(() => _openMenus['product'] = !_openMenus['product']!),
          ),
          if (_openMenus['product']!)
            _submenuIndent(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SidebarItem(
                    icon: SvgPicture.asset('assets/icons/products.svg', width: 16, height: 16),
                    label: 'Tất cả sản phẩm',
                    selected: widget.currentPage == MainPage.productList,
                    isOpen: widget.isOpen,
                    onTap: () => widget.onItemTap(MainPage.productList),
                  ),
                  _SidebarItem(
                    icon: SvgPicture.asset('assets/icons/list_products.svg', width: 16, height: 16),
                    label: 'Danh mục sản phẩm',
                    selected: widget.currentPage == MainPage.productCategory,
                    isOpen: widget.isOpen,
                    onTap: () => widget.onItemTap(MainPage.productCategory),
                  ),
                ],
              ),
              height: 80,
          ),
          // Nhà cung cấp
          _SidebarItem(
            icon: Icon(Icons.local_shipping_outlined, size: 16),
            label: 'Nhà cung cấp',
            selected: widget.currentPage == MainPage.distributor,
            isOpen: widget.isOpen,
            onTap: () => widget.onItemTap(MainPage.distributor),
          ),
          // Cài đặt

          // Đơn nhập hàng
          // _sidebarParentItem(
          //   icon: Icons.dashboard,
          //   label: 'Đơn nhập hàng',
          //   open: _openMenus['order']!,
          //   selected: false,
          //   onTap: () => setState(() => _openMenus['order'] = !_openMenus['order']!),
          // ),
          // if (_openMenus['order']!)
            // _submenuIndent(
            //   Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       _SidebarItem(
            //         icon: Icons.shopping_cart,
            //         label: 'Danh sách đơn nhập',
            //         selected: false,
            //         isOpen: widget.isOpen,
            //         onTap: () {},
            //       ),
            //     ],
            //   ),
            //   height: 40,
            // ),
          // Khách hàng
          // _sidebarParentItem(
          //   icon: Icons.dashboard,
          //   label: 'Khách hàng',
          //   open: _openMenus['customer']!,
          //   selected: false,
          //   onTap: () => setState(() => _openMenus['customer'] = !_openMenus['customer']!),
          // ),
          // if (_openMenus['customer']!)
          //   _submenuIndent(
          //     Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         _SidebarItem(
          //           icon: Icons.list,
          //           label: 'Danh sách khách hàng',
          //           selected: false,
          //           isOpen: widget.isOpen,
          //           onTap: () {},
          //         ),
          //         _SidebarItem(
          //           icon: Icons.person,
          //           label: 'Nhóm khách hàng',
          //           selected: false,
          //           isOpen: widget.isOpen,
          //           onTap: () {},
          //         ),
          //       ],
          //     ),
          //     height: 80,
          //   ),
          // _SidebarItem(
          //   icon: Icons.dashboard,
          //   label: 'Nhóm khách hàng',
          //   selected: false,
          //   isOpen: widget.isOpen,
          //   onTap: () {},
          // ),
          // Khuyến mãi
          // _sidebarParentItem(
          //   icon: Icons.dashboard,
          //   label: 'Khuyến mãi',
          //   open: _openMenus['promotion']!,
          //   selected: false,
          //   onTap: () => setState(() => _openMenus['promotion'] = !_openMenus['promotion']!),
          // ),
          // if (_openMenus['promotion']!)
          //   _submenuIndent(
          //     Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         _SidebarItem(
          //           icon: Icons.emoji_events_outlined,
          //           label: 'Chương trình khuyến mãi',
          //           selected: false,
          //           isOpen: widget.isOpen,
          //           onTap: () {},
          //         ),
          //       ],
          //     ),
          //     height: 40,
          //   ),
          // Các mục sidebar khác
          _SidebarItem(
            icon: SvgPicture.asset('assets/icons/inventory.svg', width: 16, height: 16),
            label: 'Kiểm kê kho',
            selected: widget.currentPage == MainPage.inventory,
            isOpen: widget.isOpen,
            onTap: () => widget.onItemTap(MainPage.inventory),
          ),
          // _SidebarItem(
          //   icon: SvgPicture.asset('assets/icons/report.svg', width: 16, height: 16),
          //   label: 'Báo cáo',
          //   selected: widget.currentPage == MainPage.report,
          //   isOpen: widget.isOpen,
          //   onTap: () => widget.onItemTap(MainPage.report),
          // ),
          // _SidebarItem(
          //   icon: SvgPicture.asset('assets/icons/setting.svg', width: 16, height: 16),
          //   label: 'Cài đặt chung',
          //   selected: widget.currentPage == MainPage.settings,
          //   isOpen: widget.isOpen,
          //   onTap: () => widget.onItemTap(MainPage.settings),
          // ),

          _SidebarItem(
            icon: SvgPicture.asset('assets/icons/order.svg', width: 16, height: 16),
            label: 'Import Hóa đơn',
            selected: widget.currentPage == MainPage.invoiceImportList,
            isOpen: widget.isOpen,
            onTap: () => widget.onItemTap(MainPage.invoiceImportList),
          ),
          //           _SidebarItem(
          //   icon: Icon(Icons.palette, size: 16),
          //   label: 'Style Guide',
          //   selected: widget.currentPage == MainPage.styleGuide,
          //   isOpen: widget.isOpen,
          //   onTap: () => widget.onItemTap(MainPage.styleGuide),
          // ),
                    _SidebarItem(
            icon: Icon(Icons.settings_outlined, size: 16),
            label: 'Cài đặt',
            selected: widget.currentPage == MainPage.settings,
            isOpen: widget.isOpen,
            onTap: () => widget.onItemTap(MainPage.settings),
          ),
        ],
      ),
    );
  }

  Widget _submenuIndent(Widget child, {double height = 0}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 16,
        margin: const EdgeInsets.only(left: 8, right: 0),
        child: CustomPaint(
          size: Size(1, height),
          painter: _SidebarLinePainter(),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: child,
        ),
      ),
    ],
  );
}

class _SidebarLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SidebarItem extends StatefulWidget {
  final Widget icon;
  final String label;
  final bool selected;
  final bool isOpen;
  final VoidCallback? onTap;
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.isOpen = true,
    this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool showHighlight = widget.selected;
    Color textColor = textThird;
    if (showHighlight) {
      textColor = primaryBlue;
    } else if (_isHovering) {
      textColor = textActive;
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: showHighlight
            ? primaryBlue.withOpacity(0.08)
            : _isHovering
                ? sidebarHoverBackground
                : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: ListTile(
          leading: widget.icon,
          title: widget.isOpen
              ? Padding(
                  padding: const EdgeInsets.only(left: space10),
                  child: Text(
                    widget.label,
                    style: small.copyWith(
                      fontWeight: showHighlight ? FontWeight.bold : FontWeight.normal,
                      color: showHighlight
                          ? primaryBlue
                          : _isHovering
                              ? textActive
                              : textThird,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                )
              : null,
          minLeadingWidth: 0,
          horizontalTitleGap: 0,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
          onTap: widget.onTap,
          tileColor: Colors.transparent,
        ),
      ),
    );
  }
}

class _SidebarParentItemWidget extends StatefulWidget {
  final Widget icon;
  final String label;
  final bool open;
  final VoidCallback onTap;
  final bool selected;
  const _SidebarParentItemWidget({
    required this.icon,
    required this.label,
    required this.open,
    required this.onTap,
    this.selected = false,
  });

  @override
  State<_SidebarParentItemWidget> createState() => _SidebarParentItemWidgetState();
}

class _SidebarParentItemWidgetState extends State<_SidebarParentItemWidget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    Color textColor = textThird;
    if (widget.open || widget.selected) {
      textColor = primaryBlue;
    } else if (_isHovering) {
      textColor = textActive;
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (widget.open || widget.selected)
            ? primaryBlue.withOpacity(0.08)
            : _isHovering
                ? sidebarHoverBackground
                : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: ListTile(
          leading: widget.icon,
          title: Padding(
            padding: const EdgeInsets.only(left: space10),
            child: Text(
              widget.label,
              style: small.copyWith(
                fontWeight: (widget.open || widget.selected) ? FontWeight.bold : FontWeight.normal,
                color: (widget.open || widget.selected)
                    ? primaryBlue
                    : _isHovering
                        ? textActive
                        : textThird,
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          trailing: Icon(widget.open ? Icons.expand_less : Icons.expand_more, color: textSecondary, size: 20),
          minLeadingWidth: 0,
          horizontalTitleGap: 0,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
          onTap: widget.onTap,
          tileColor: Colors.transparent,
        ),
      ),
    );
  }
}

// Thêm các widget mới cho nav bar mobile
class _NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: selected
                ? BoxDecoration(
                    color: primaryBlue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  )
                : null,
            padding: const EdgeInsets.all(8),
            child: icon,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? primaryBlue : textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCenterButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  const _NavCenterButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.18),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: icon,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryBlue,
          ),
        ),
      ],
    );
  }
} 