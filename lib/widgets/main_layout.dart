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

// Định nghĩa enum cho các trang
enum MainPage { dashboard, productList, productCategory, addProduct, inventory, report, settings, productDetail, lowStockProducts, addProductCategory, inventoryHistory }

class MainLayout extends StatefulWidget {
  final Widget? child; // Không cần truyền child nữa, sẽ render theo _currentPage
  const MainLayout({super.key, this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _sidebarOpen = true;
  int _selectedIndex = 0;
  MainPage _currentPage = MainPage.dashboard; // Bắt đầu ở DashboardScreen
  MainPage? _previousPage; // Lưu trang trước đó để xử lý nút back
  Product? _selectedProduct;

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
    });
  }

  void _onSidebarTap(MainPage page) {
    setState(() {
      _previousPage = _currentPage;
      _currentPage = page;
      // Đóng sidebar trên mobile sau khi chọn trang
      if (MediaQuery.of(context).size.width < 600) {
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      body: Column(
        children: [
          _Header(onMenuPressed: _toggleSidebar),
          Expanded(
            child: isMobile
                ? Stack(
                    children: [
                      _buildMainContent(),
                      AnimatedOpacity(
                        opacity: _sidebarOpen ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                        child: _sidebarOpen
                            ? GestureDetector(
                                onTap: _toggleSidebar,
                                child: Container(
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedSlide(
                        offset: _sidebarOpen ? Offset(0, 0) : Offset(-1, 0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                        child: SizedBox(
                          width: 250,
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
                        width: _sidebarOpen ? 250 : 70,
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
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onNavTap,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.black54,
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_box),
                  label: 'Kiểm kê',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2), // Product list or add product
                  label: 'Sản phẩm',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart), // Report or product category
                  label: 'Báo cáo',
                ),
              ],
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
class _Sidebar extends StatelessWidget {
  final bool isOpen;
  final MainPage currentPage;
  final Function(MainPage) onItemTap;
  const _Sidebar({this.isOpen = true, required this.currentPage, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isOpen ? 250 : 70,
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
      child: Column(
        children: [
          const SizedBox(height: 0),
          _SidebarItem(
            icon: Icons.home,
            label: 'Trang chủ',
            selected: currentPage == MainPage.dashboard,
            isOpen: isOpen,
            onTap: () => onItemTap(MainPage.dashboard),
          ),
          _SidebarItem(
            icon: Icons.inventory_2,
            label: 'Danh sách sản phẩm',
            selected: currentPage == MainPage.productList,
            isOpen: isOpen,
            onTap: () => onItemTap(MainPage.productList),
          ),
          _SidebarItem(
            icon: Icons.category,
            label: 'Danh mục sản phẩm',
            selected: currentPage == MainPage.productCategory,
            isOpen: isOpen,
            onTap: () => onItemTap(MainPage.productCategory),
          ),
          _SidebarItem(
            icon: Icons.check_box,
            label: 'Kiểm kê',
            selected: currentPage == MainPage.inventory,
            isOpen: isOpen,
            onTap: () => onItemTap(MainPage.inventory),
          ),
          _SidebarItem(
            icon: Icons.history,
            label: 'Lịch sử kiểm kê',
            selected: currentPage == MainPage.inventoryHistory,
            isOpen: isOpen,
            onTap: () => onItemTap(MainPage.inventoryHistory),
          ),
          _SidebarItem(
            icon: Icons.bar_chart,
            label: 'Báo cáo',
            selected: currentPage == MainPage.report,
            isOpen: isOpen,
            onTap: () => onItemTap(MainPage.report),
          ),
          _SidebarItem(
            icon: Icons.settings,
            label: 'Cài đặt',
            selected: currentPage == MainPage.settings,
            isOpen: isOpen,
            onTap: () => onItemTap(MainPage.settings),
          ),
          // Thêm mục Thêm sản phẩm mới vào Sidebar (tạm thời để test)
          // _SidebarItem(
          //   icon: Icons.add_circle_outline,
          //   label: 'Thêm sản phẩm mới',
          //   selected: currentPage == MainPage.addProduct,
          //   isOpen: isOpen,
          //   onTap: () => onItemTap(MainPage.addProduct),
          // ),
        ],
      ),
    );
  }
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
          color: showHighlight ? Colors.blue.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: ListTile(
          leading: Icon(icon, color: selected ? Colors.blue : Colors.black54),
          title: isOpen
              ? Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
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