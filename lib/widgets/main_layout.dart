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

// Định nghĩa enum cho các trang
enum MainPage { dashboard, productList, productCategory, addProduct, inventory, report, settings, productDetail, lowStockProducts, addProductCategory, inventoryHistory }

class MainLayout extends StatefulWidget {
  final Widget? child; // Không cần truyền child nữa, sẽ render theo _currentPage
  const MainLayout({super.key, this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _sidebarOpen = false;
  int _selectedIndex = 0;
  MainPage _currentPage = MainPage.dashboard;
  MainPage? _previousPage;
  Product? _selectedProduct;
  bool _isMobile = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo sidebar dựa trên kích thước màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isMobile = MediaQuery.of(context).size.width < 1024;
          _sidebarOpen = !_isMobile;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cập nhật layout khi dependencies thay đổi (ví dụ: MediaQuery)
    final newIsMobile = MediaQuery.of(context).size.width < 1024;
    if (newIsMobile != _isMobile) {
      setState(() {
        _isMobile = newIsMobile;
        _sidebarOpen = !newIsMobile;
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
    });
  }

  void _onSidebarTap(MainPage page) {
    setState(() {
      _previousPage = _currentPage;
      _currentPage = page;
      if (_isMobile) {
        _sidebarOpen = false;
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
      _currentPage = MainPage.productList;
      _selectedProduct = null;
    });
  }

  void _openLowStockProducts() {
    setState(() {
      _previousPage = _currentPage;
      _currentPage = MainPage.lowStockProducts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Header(onMenuPressed: _toggleSidebar),
          Expanded(
            child: _isMobile
                ? Stack(
                    children: [
                      _buildMainContent(),
                      if (_sidebarOpen)
                        GestureDetector(
                          onTap: _toggleSidebar,
                          child: Container(
                            color: Colors.black.withOpacity(0.3),
                          ),
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
                            onItemTap: _onSidebarTap,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _sidebarOpen ? 290 : 70,
                        child: _Sidebar(
                          isOpen: _sidebarOpen,
                          currentPage: _currentPage,
                          onItemTap: _onSidebarTap,
                        ),
                      ),
                      Expanded(child: _buildMainContent()),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _isMobile
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
                        icon: Icons.dashboard,
                        label: 'Trang chủ',
                        selected: _currentPage == MainPage.dashboard,
                        onTap: () => _onNavTap(0),
                      ),
                      _NavItem(
                        icon: Icons.inventory_2,
                        label: 'Kiểm kê',
                        selected: _currentPage == MainPage.inventory,
                        onTap: () => _onNavTap(1),
                      ),
                      _NavCenterButton(
                        icon: Icons.add,
                        label: 'Thêm mới',
                        onTap: () => _onSidebarTap(MainPage.addProduct),
                      ),
                      _NavItem(
                        icon: Icons.inventory,
                        label: 'Sản phẩm',
                        selected: _currentPage == MainPage.productList,
                        onTap: () => _onNavTap(2),
                      ),
                      _NavItem(
                        icon: Icons.bar_chart,
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
    );
  }

  Widget _buildMainContent() {
    switch (_currentPage) {
      case MainPage.dashboard:
        return DashboardScreen(
          onViewProductList: () => _onSidebarTap(MainPage.productList),
          onViewLowStockProducts: _openLowStockProducts,
        );
      case MainPage.productList:
        return ProductListScreen(
          onProductTap: _openProductDetail,
          onNavigate: _onSidebarTap,
        );
      case MainPage.productCategory:
        return ProductCategoryScreen(
           onNavigate: _onSidebarTap,
        );
      case MainPage.addProduct:
        return AddProductScreen(
          product: _selectedProduct,
          isEdit: _selectedProduct != null,
          onBack: _openProductList,
        );
      case MainPage.productDetail:
        return ProductDetailScreen(
          product: _selectedProduct!,
          onEdit: _openEditProduct,
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
        return Center(child: Text('Cài đặt (chưa cài đặt)'));
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
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
      // Logic điều hướng cho BottomNavigationBar
      switch (index) {
        case 0:
          _onSidebarTap(MainPage.dashboard);
          break;
        case 1:
          _onSidebarTap(MainPage.inventory);
          break;
        case 2:
          // Khi nhấn Sản phẩm trên bottom nav, đi tới ProductList
          _onSidebarTap(MainPage.productList);
          break;
        case 3:
          // Khi nhấn Báo cáo trên bottom nav, đi tới Report
          _onSidebarTap(MainPage.report);
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
          IconButton(
            icon: const Icon(Icons.menu),
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
    required IconData icon,
    required String label,
    required bool open,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.ease,
        decoration: BoxDecoration(
          color: (open || selected) ? primaryBlue.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: ListTile(
          leading: Icon(icon, color: (open || selected) ? primaryBlue : textSecondary),
          title: Padding(
            padding: const EdgeInsets.only(left: space10),
            child: Text(
              label,
              style: small.copyWith(
                fontWeight: (open || selected) ? FontWeight.bold : FontWeight.normal,
                color: textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          trailing: Icon(open ? Icons.expand_less : Icons.expand_more, color: textSecondary, size: 20),
          minLeadingWidth: 0,
          horizontalTitleGap: 0,
          onTap: onTap,
        ),
      ),
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
          _SidebarItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            selected: widget.currentPage == MainPage.dashboard,
            isOpen: widget.isOpen,
            onTap: () => widget.onItemTap(MainPage.dashboard),
          ),
          // Sản phẩm
          _sidebarParentItem(
            icon: Icons.dashboard,
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
                    icon: Icons.dashboard,
                    label: 'Tất cả sản phẩm',
                    selected: widget.currentPage == MainPage.productList,
                    isOpen: widget.isOpen,
                    onTap: () => widget.onItemTap(MainPage.productList),
                  ),
                  _SidebarItem(
                    icon: Icons.list,
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
          // _SidebarItem(
          //   icon: Icons.dashboard,
          //   label: 'Nhà cung cấp',
          //   selected: false,
          //   isOpen: widget.isOpen,
          //   onTap: () {},
          // ),
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
            icon: Icons.dashboard,
            label: 'Kiểm kê kho',
            selected: widget.currentPage == MainPage.inventory,
            isOpen: widget.isOpen,
            onTap: () => widget.onItemTap(MainPage.inventory),
          ),
          _SidebarItem(
            icon: Icons.dashboard,
            label: 'Báo cáo',
            selected: widget.currentPage == MainPage.report,
            isOpen: widget.isOpen,
            onTap: () => widget.onItemTap(MainPage.report),
          ),
          _SidebarItem(
            icon: Icons.settings,
            label: 'Cài đặt chung',
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

class _SidebarItem extends StatelessWidget {
  final IconData icon;
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
  Widget build(BuildContext context) {
    final bool showHighlight = selected;
    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.ease,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: showHighlight ? primaryBlue.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: ListTile(
          leading: Icon(icon, color: selected ? primaryBlue : textSecondary),
          title: isOpen
              ? Padding(
                  padding: const EdgeInsets.only(left: space10),
                  child: Text(
                    label,
                    style: small.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                )
              : null,
          minLeadingWidth: 0,
          horizontalTitleGap: 0,
          onTap: onTap,
        ),
      ),
    );
  }
}

// Thêm các widget mới cho nav bar mobile
class _NavItem extends StatelessWidget {
  final IconData icon;
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
            child: Icon(
              icon,
              color: selected ? primaryBlue : textSecondary,
              size: 20,
            ),
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
  final IconData icon;
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
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
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