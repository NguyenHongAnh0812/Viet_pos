import 'package:flutter/material.dart';
import '../screens/product_list_screen.dart';
import '../screens/product_category_screen.dart';
import '../screens/products/add_product_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../models/product.dart';
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
import '../screens/company_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/add_company_screen.dart';
import '../screens/company_detail_screen.dart';
import '../models/company.dart';
import '../screens/product_category_detail_screen.dart';
import '../models/product_category.dart';
import '../screens/customers/customer_list_screen.dart';
import '../screens/customers/add_customer_screen.dart';
import '../screens/customers/customer_detail_screen.dart';
import '../models/customer.dart';
import '../screens/orders/order_create_screen.dart' hide Product;
import 'package:google_fonts/google_fonts.dart';
import '../screens/dashboard/dashboard_modern_screen.dart';

// Định nghĩa enum cho các trang
enum MainPage { 
  dashboard, 
  productList, 
  productCategory, 
  addProduct, 
  inventory, 
  report, 
  settings, 
  productDetail, 
  lowStockProducts, 
  addProductCategory, 
  inventoryHistory, 
  styleGuide, 
  invoiceImportList, 
  invoiceImport, 
  inventoryDetail, 
  inventoryCreateSession, 
  companies, 
  addCompany, 
  companyDetail,
  productCategoryDetail,
  customers,
  addCustomer,
  customerDetail,
  orderCreate
}

class MainLayout extends StatefulWidget {
  final Widget? child;
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
  Company? _selectedCompany;
  ProductCategory? _selectedCategory;
  Customer? _selectedCustomer;
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

  // Trạng thái mở/đóng cho từng mục cha
  Map<String, bool> _openMenus = {
    'product': false,
    'order': false,
    'customer': false,
    'promotion': false,
  };

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

  void _applyFilter(
    String category,
    RangeValues price,
    RangeValues stock,
    String statusValue,
    Set<String> tagsValue,
  ) {
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

  void updateFilterRanges(List<Product> products) {
    if (products.isNotEmpty) {
      int newMinStock = products.map((p) => p.stockSystem).reduce((a, b) => a < b ? a : b);
      int newMaxStock = products.map((p) => p.stockSystem).reduce((a, b) => a > b ? a : b);
      double newMinPrice = products.map((p) => p.salePrice).reduce((a, b) => a < b ? a : b);
      double newMaxPrice = products.map((p) => p.salePrice).reduce((a, b) => a > b ? a : b);

      double newStartPrice = priceRange.start.clamp(newMinPrice, newMaxPrice);
      double newEndPrice = priceRange.end.clamp(newMinPrice, newMaxPrice);
      double newStartStock = stockRange.start.clamp(newMinStock.toDouble(), newMaxStock.toDouble());
      double newEndStock = stockRange.end.clamp(newMinStock.toDouble(), newMaxStock.toDouble());

      setState(() {
        stockRange = RangeValues(newStartStock, newEndStock);
        priceRange = RangeValues(newStartPrice, newEndPrice);
      });
    } else {
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
      if (page != MainPage.companyDetail) {
        _selectedCompany = null;
      }
      if (page != MainPage.productCategoryDetail) {
        _selectedCategory = null;
      }
      if (page != MainPage.customerDetail) {
        _selectedCustomer = null;
      }
      
      // Auto-open product submenu when navigating to product-related pages
      if (page == MainPage.productList || 
          page == MainPage.addProduct ||
          page == MainPage.addProductCategory) {
        _openMenus['product'] = true;
      }
      
      // Auto-open customer submenu when navigating to customer-related pages
      if (page == MainPage.customers || 
          page == MainPage.addCustomer ||
          page == MainPage.customerDetail) {
        _openMenus['customer'] = true;
      }

      // Auto-open order submenu when navigating to order-related pages
      if (page == MainPage.orderCreate) {
        _openMenus['order'] = true;
      }
    });
  }

  void _goBack() {
    setState(() {
      if (_previousPage != null) {
        _currentPage = _previousPage!;
        _previousPage = null;
      } else {
        _currentPage = MainPage.productList;
      }
    });
  }

  void _openProductDetail(Product product) {
    setState(() {
      _previousPage = _currentPage;
      _currentPage = MainPage.addProduct;
      _selectedProduct = product;
      _currentPage = MainPage.productDetail;
    });
  }

  void _openEditProduct(Product product) {
    setState(() {
      _previousPage = _currentPage;
      _currentPage = MainPage.addProduct;
      _selectedProduct = product;
    });
  }

  void _openProductList() {
    setState(() {
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

  void _openCompanyDetail(Company company) {
    setState(() {
      _previousPage = _currentPage;
      _currentPage = MainPage.companyDetail;
      _selectedCompany = company;
    });
  }

  void _openCategoryDetail(ProductCategory category) {
    setState(() {
      _previousPage = _currentPage;
      _currentPage = MainPage.productCategoryDetail;
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Header(onMenuPressed: _toggleSidebar),
          Expanded(child: _buildMainContent()),
        ],
      ),
      bottomNavigationBar: Container(
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
                    'assets/icons/tag_icon.svg', 
                    width: 20,
                    height: 20,
                    color: Colors.green,
                  ),
                  label: 'Tổng quan',
                  selected: _currentPage == MainPage.dashboard,
                  onTap: () => _onNavTap(0),
                ),
                _NavItem(
                  icon: Icon(Icons.inventory_2, color: _currentPage == MainPage.productList ? Colors.green : Colors.grey, size: 28),
                  label: 'Hàng hoá',
                  selected: _currentPage == MainPage.productList,
                  onTap: () => _onNavTap(1),
                ),
                _NavItem(
                  icon: Icon(Icons.shopping_cart, color: _currentPage == MainPage.orderCreate ? Colors.green : Colors.grey, size: 28),
                  label: 'Bán hàng',
                  selected: _currentPage == MainPage.orderCreate,
                  onTap: () => _onNavTap(2),
                ),
                _NavItem(
                  icon: Icon(Icons.people, color: _currentPage == MainPage.companies ? Colors.green : Colors.grey, size: 28),
                  label: 'Nhà cung cấp',
                  selected: _currentPage == MainPage.companies,
                  onTap: () => _onNavTap(3),
                ),
                _NavItem(
                  icon: Icon(Icons.more_horiz, color: _currentPage == MainPage.settings ? Colors.green : Colors.grey, size: 28),
                  label: 'Thêm',
                  selected: _currentPage == MainPage.settings,
                  onTap: () => _onNavTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_currentPage) {
      case MainPage.dashboard:
        return const DashboardModernScreen();
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
           onCategorySelected: _openCategoryDetail,
        );
      case MainPage.addProduct:
        return AddProductScreen(
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
      case MainPage.companies:
        return CompanyScreen(onCompanySelected: _openCompanyDetail);
      case MainPage.addCompany:
        return AddCompanyScreen(onBack: () => onSidebarTap(MainPage.companies));
      case MainPage.companyDetail:
        return CompanyDetailScreen(
          company: _selectedCompany!, 
          onBack: () => onSidebarTap(MainPage.companies)
        );
      case MainPage.productCategoryDetail:
        if (_selectedCategory == null) return const SizedBox();
        return ProductCategoryDetailScreen(
          category: _selectedCategory!,
          onBack: () => onSidebarTap(MainPage.productCategory),
        );
      case MainPage.customers:
        return CustomerListScreen(
          onAddCustomer: () => onSidebarTap(MainPage.addCustomer),
          onCustomerTap: (customer) {
            setState(() {
              _selectedCustomer = customer;
              _previousPage = _currentPage;
              _currentPage = MainPage.customerDetail;
            });
          },
        );
      case MainPage.addCustomer:
        return AddCustomerScreen(
          onSuccess: () => onSidebarTap(MainPage.customers),
        );
      case MainPage.customerDetail:
        return CustomerDetailScreen(
          customerId: _selectedCustomer?.id ?? '',
          onSuccess: () => onSidebarTap(MainPage.customers),
        );
      case MainPage.orderCreate:
        return OrderCreateScreen();
      default:
        return const DashboardModernScreen();
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          onSidebarTap(MainPage.dashboard);
          break;
        case 1:
          onSidebarTap(MainPage.productList);
          break;
        case 2:
          onSidebarTap(MainPage.orderCreate);
          break;
        case 3:
          onSidebarTap(MainPage.companies);
          break;
        case 4:
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.95,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: 1.35,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            _QuickAccessGridButton(
                              icon: Icons.inventory_2,
                              label: 'Danh sách sản phẩm',
                              onTap: () {
                                Navigator.pop(context);
                                onSidebarTap(MainPage.productList);
                              },
                            ),
                            _QuickAccessGridButton(
                              icon: Icons.add_box,
                              label: 'Thêm sản phẩm',
                              onTap: () {
                                Navigator.pop(context);
                                onSidebarTap(MainPage.addProduct);
                              },
                            ),
                            _QuickAccessGridButton(
                              icon: Icons.inventory,
                              label: 'Kiểm kê kho',
                              onTap: () {
                                Navigator.pop(context);
                                onSidebarTap(MainPage.inventory);
                              },
                            ),
                            _QuickAccessGridButton(
                              icon: Icons.business,
                              label: 'Nhà cung cấp',
                              onTap: () {
                                Navigator.pop(context);
                                onSidebarTap(MainPage.companies);
                              },
                            ),
                            _QuickAccessGridButton(
                              icon: Icons.people,
                              label: 'Người dùng',
                              onTap: () {
                                Navigator.pop(context);
                                onSidebarTap(MainPage.customers);
                              },
                            ),
                            _QuickAccessGridButton(
                              icon: Icons.settings,
                              label: 'Cài đặt',
                              onTap: () {
                                Navigator.pop(context);
                                onSidebarTap(MainPage.settings);
                              },
                            ),
                            _QuickAccessGridButton(
                              icon: Icons.file_upload,
                              label: 'Import hóa đơn',
                              onTap: () {
                                Navigator.pop(context);
                                onSidebarTap(MainPage.invoiceImportList);
                              },
                            ),
                            _QuickAccessGridButton(
                              icon: Icons.palette,
                              label: 'Style Guide',
                              onTap: () {
                                Navigator.pop(context);
                                onSidebarTap(MainPage.styleGuide);
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
          );
          break;
      }
    });
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onMenuPressed;
  const _Header({required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          // Ẩn hoàn toàn header
          // const SizedBox(width: 8),
          // const Text(
          //   'VET-POS',
          //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          // ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatefulWidget {
  final bool isOpen;
  final MainPage currentPage;
  final Function(MainPage) onItemTap;
  final Map<String, bool> openMenus;
  final Function(String, bool) onMenuToggle;
  const _Sidebar({
    this.isOpen = true, 
    required this.currentPage, 
    required this.onItemTap,
    required this.openMenus,
    required this.onMenuToggle,
  });

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/tag_icon.svg',
                  width: 20,
                  height: 20,
                  color: primaryBlue,
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

          _sidebarParentItem(
            icon: SvgPicture.asset('assets/icons/products.svg', width: 16, height: 16),
            label: 'Sản phẩm',
            open: widget.openMenus['product']!,
            selected: false,
            onTap: () => widget.onMenuToggle('product', !widget.openMenus['product']!),
          ),
          if (widget.openMenus['product']!)
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
            ),

          _SidebarItem(
            icon: const Icon(Icons.business_outlined, size: 16),
            label: 'Nhà cung cấp',
            selected: widget.currentPage == MainPage.companies,
            isOpen: widget.isOpen,
            onTap: () => widget.onItemTap(MainPage.companies),
          ),

          _sidebarParentItem(
            icon: const Icon(Icons.shopping_cart_outlined, size: 16),
            label: 'Đơn hàng',
            open: widget.openMenus['order']!,
            selected: false,
            onTap: () => widget.onMenuToggle('order', !widget.openMenus['order']!),
          ),
          if (widget.openMenus['order']!)
            _submenuIndent(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SidebarItem(
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: 'Tạo đơn hàng',
                    selected: widget.currentPage == MainPage.orderCreate,
                    isOpen: widget.isOpen,
                    onTap: () => widget.onItemTap(MainPage.orderCreate),
                  ),
                ],
              ),
            ),

          _sidebarParentItem(
            icon: const Icon(Icons.people_outline, size: 16),
            label: 'Khách hàng',
            open: widget.openMenus['customer']!,
            selected: false,
            onTap: () => widget.onMenuToggle('customer', !widget.openMenus['customer']!),
          ),
          if (widget.openMenus['customer']!)
            _submenuIndent(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SidebarItem(
                    icon: const Icon(Icons.list, size: 16),
                    label: 'Danh sách khách hàng',
                    selected: widget.currentPage == MainPage.customers,
                    isOpen: widget.isOpen,
                    onTap: () => widget.onItemTap(MainPage.customers),
                  ),
                ],
              ),
            ),

          _SidebarItem(
            icon: SvgPicture.asset('assets/icons/inventory.svg', width: 16, height: 16),
            label: 'Kiểm kê kho',
            selected: widget.currentPage == MainPage.inventory,
            isOpen: widget.isOpen,
            onTap: () => widget.onItemTap(MainPage.inventory),
          ),

          _SidebarItem(
            icon: SvgPicture.asset('assets/icons/order.svg', width: 16, height: 16),
            label: 'Import Hóa đơn',
            selected: widget.currentPage == MainPage.invoiceImportList,
            isOpen: widget.isOpen,
            onTap: () => widget.onItemTap(MainPage.invoiceImportList),
          ),

          _SidebarItem(
            icon: Icon(Icons.palette, size: 16),
            label: 'Style Guide',
            selected: widget.currentPage == MainPage.styleGuide,
            isOpen: widget.isOpen,
            onTap: () => widget.onItemTap(MainPage.styleGuide),
          ),

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
    final bool showHover = _isHovering && !widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: showHighlight ? primaryBlue : (showHover ? primaryBlue.withOpacity(0.1) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              widget.icon,
              if (widget.isOpen) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: showHighlight ? Colors.white : (showHover ? primaryBlue : Colors.black87),
                      fontWeight: showHighlight ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 12),
            ],
          ),
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
    final bool showHighlight = widget.selected;
    final bool showHover = _isHovering && !widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: showHighlight ? primaryBlue : (showHover ? primaryBlue.withOpacity(0.1) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              widget.icon,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: showHighlight ? Colors.white : (showHover ? primaryBlue : Colors.black87),
                    fontWeight: showHighlight ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: widget.open ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: showHighlight ? Colors.white : (showHover ? primaryBlue : Colors.black54),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected ? primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: icon,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: selected ? primaryBlue : Colors.black54,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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

  const _NavCenterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: icon,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class FilterSidebarContent extends StatelessWidget {
  final VoidCallback onClose;
  final List<String> categories;
  final List<String> tags;
  final String selectedCategory;
  final RangeValues priceRange;
  final RangeValues stockRange;
  final String status;
  final Set<String> selectedTags;
  final Function(String, RangeValues, RangeValues, String, Set<String>) onApply;
  final VoidCallback onReset;

  const FilterSidebarContent({
    required this.onClose,
    required this.categories,
    required this.tags,
    required this.selectedCategory,
    required this.priceRange,
    required this.stockRange,
    required this.status,
    required this.selectedTags,
    required this.onApply,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bộ lọc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Danh mục',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Category filter implementation would go here
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    onApply(selectedCategory, priceRange, stockRange, status, selectedTags);
                  },
                  child: Text('Áp dụng'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  child: Text('Đặt lại'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget nút truy cập nhanh
class _QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAccessButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE0E0E0))),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _QuickAccessGridButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessGridButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: primaryBlue,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 