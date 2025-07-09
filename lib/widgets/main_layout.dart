import 'package:flutter/material.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/categories/product_category_screen.dart';
import '../screens/products/add_product_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/products/low_stock_products_screen.dart';
import '../screens/categories/add_product_category_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/inventory/inventory_history_screen.dart';
import '../screens/inventory/inventory_detail_screen.dart';
import '../screens/inventory/inventory_confirm_screen.dart';
import '../screens/inventory/inventory_create_session_screen.dart';
import '../screens/companies/company_screen.dart';
import '../screens/companies/add_company_screen.dart';
import '../screens/companies/company_detail_screen.dart';
import '../screens/categories/product_category_detail_screen.dart';
import 'common/design_system.dart';
import '../screens/style_guide_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/product_service.dart';
import '../screens/invoice_import_list_screen.dart';
import '../screens/invoice_import_screen.dart';
import '../screens/customers/customer_list_screen.dart';
import '../screens/customers/add_customer_screen.dart';
import '../screens/customers/customer_detail_screen.dart';
import '../models/customer.dart';
import '../screens/orders/order_create_screen.dart' hide Product;
import 'package:google_fonts/google_fonts.dart';
import '../screens/dashboard/dashboard_modern_screen.dart';
import '../models/product.dart';
import '../models/company.dart';
import '../models/product_category.dart';
import '../screens/settings_screen.dart' show SettingsScreen, BankSettingForm, VietQRSettingsScreen;
import '../screens/example_standard_screen.dart';
import '../screens/users/user_list_screen.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../screens/users/permissions_overview_screen.dart';
import '../screens/auth/login_screen.dart';

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
  inventoryConfirm,
  inventoryCreateSession, 
  companies, 
  addCompany, 
  companyDetail,
  productCategoryDetail,
  customers,
  addCustomer,
  customerDetail,
  orderCreate,
  moreDashboard,
  demoLayout,
  users,
  permissionsOverview,
}

class MainLayout extends StatefulWidget {
  final Widget? child;
  const MainLayout({super.key, this.child});

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  bool _sidebarOpen = false;
  int _selectedIndex = 0;
  MainPage _currentPage = MainPage.dashboard;
  MainPage? _previousPage;
  Product? _selectedProduct;
  Company? _selectedCompany;
  ProductCategory? _selectedCategory;
  Customer? _selectedCustomer;
  bool isFilterSidebarOpen = false;
  
  // Animation controller cho bottom navigation
  late AnimationController _navAnimationController;
  late Animation<double> _navAnimation;

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
  User? _currentUser;
  final UserService _userService = UserService();

  // Trạng thái mở/đóng cho từng mục cha
  final Map<String, bool> _openMenus = {
    'product': false,
    'order': false,
    'customer': false,
    'promotion': false,
  };

  @override
  void initState() {
    super.initState();
    
    // Khởi tạo animation controller
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _navAnimation = CurvedAnimation(
      parent: _navAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Load current user
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _navAnimationController.dispose();
    super.dispose();
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

  Future<void> _loadCurrentUser() async {
    final user = await _userService.getCurrentUser();
    setState(() {
      _currentUser = user;
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

  void openInventoryConfirm(String sessionId) {
    setState(() {
      _selectedInventorySessionId = sessionId;
      _previousPage = _currentPage;
      _currentPage = MainPage.inventoryConfirm;
    });
  }

  void openInventoryHistory(String sessionId) {
    setState(() {
      _selectedInventorySessionId = sessionId;
      _previousPage = _currentPage;
      _currentPage = MainPage.inventoryHistory;
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

  void _showMoreSheet(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final crossAxisCount = isMobile ? 3 : 5;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final items = [
          {'icon': Icons.settings, 'label': 'Cài đặt'},
          {'icon': Icons.bar_chart, 'label': 'Báo cáo'},
          {'icon': Icons.receipt, 'label': 'Hóa đơn'},
          {'icon': Icons.account_circle, 'label': 'Tài khoản'},
          {'icon': Icons.help, 'label': 'Trợ giúp'},
          {'icon': Icons.inventory, 'label': 'Kiểm kê'},
          {'icon': Icons.category, 'label': 'Danh mục'},
          {'icon': Icons.people, 'label': 'Khách hàng'},
          {'icon': Icons.analytics, 'label': 'Thống kê'},
          {'icon': Icons.backup, 'label': 'Sao lưu'},
        ];
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Thêm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: items.map((item) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: Icon(item['icon'] as IconData, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['label'] as String, 
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    switch (_currentPage) {
      case MainPage.dashboard:
        return const DashboardModernScreen(
          key: PageStorageKey('dashboard'),
        );
      case MainPage.productList:
        return ProductListScreen(
          key: PageStorageKey('product-list'),
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
          key: const PageStorageKey('product-category'),
          onNavigate: onSidebarTap,
          onCategorySelected: _openCategoryDetail,
        );
      case MainPage.addProduct:
        return AddProductScreen(
          key: const PageStorageKey('add-product'),
          onBack: _openProductList,
        );
      case MainPage.productDetail:
        return ProductDetailScreen(
          key: const PageStorageKey('product-detail'),
          product: _selectedProduct!,
          onBack: _openProductList,
        );
      case MainPage.inventory:
        return InventoryScreen(
          key: const PageStorageKey('inventory'),
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
          key: const PageStorageKey('inventory-history'),
          sessionId: _selectedInventorySessionId!,
        );
      case MainPage.report:
        return const Center(child: Text('Báo cáo (chưa cài đặt)'));
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
      case MainPage.inventoryConfirm:
        if (_selectedInventorySessionId == null) return const SizedBox();
        return InventoryConfirmScreen(sessionId: _selectedInventorySessionId!);
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
      case MainPage.moreDashboard:
        return MoreDashboardScreen(onNavigate: onSidebarTap);
      case MainPage.demoLayout:
        return const ExampleStandardScreen();
      case MainPage.users:
        return const UserListScreen();
      case MainPage.permissionsOverview:
        return const PermissionsOverviewScreen();
      default:
        return const DashboardModernScreen();
    }
  }

  void _onNavTap(int index) {
    final User? currentUser = _currentUser;
    final bool isEmployee = currentUser?.role == UserRole.employee;
    if (isEmployee) {
      if (index == 0) {
        setState(() { _currentPage = MainPage.dashboard; });
      } else {
        setState(() { _currentPage = MainPage.orderCreate; });
      }
      return;
    }
    // Logic cho admin và role khác
    MainPage targetPage;
    switch (index) {
      case 0:
        targetPage = MainPage.dashboard;
        break;
      case 1:
        targetPage = MainPage.productList;
        break;
      case 2:
        targetPage = MainPage.orderCreate;
        break;
      case 3:
        targetPage = MainPage.companies;
        break;
      case 4:
        targetPage = MainPage.moreDashboard;
        break;
      default:
        targetPage = MainPage.dashboard;
    }
    setState(() {
      _currentPage = targetPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final bool isAdmin = currentUser.role == UserRole.admin;
    final bool isEmployee = currentUser.role == UserRole.employee;

    // Nếu employee cố truy cập màn khác ngoài dashboard và orderCreate thì tự động chuyển về dashboard
    if (isEmployee && _currentPage != MainPage.dashboard && _currentPage != MainPage.orderCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentPage = MainPage.dashboard;
        });
      });
    }

    final bool canViewUsers = currentUser.hasPermission(Permission.viewUsers);

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
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (isEmployee) ...[
                  _NavItem(
                    icon: SvgPicture.asset(
                      'assets/icons/new_icon/overview.svg',
                      width: 20,
                      height: 20,
                      color: _currentPage == MainPage.dashboard ? Colors.green : Colors.grey,
                    ),
                    label: 'Tổng quan',
                    selected: _currentPage == MainPage.dashboard,
                    onTap: () => _onNavTap(0),
                  ),
                  _NavItem(
                    icon: SvgPicture.asset(
                      'assets/icons/new_icon/sell.svg',
                      width: 20,
                      height: 20,
                      color: _currentPage == MainPage.orderCreate ? Colors.green : Colors.grey,
                    ),
                    label: 'Bán hàng',
                    selected: _currentPage == MainPage.orderCreate,
                    onTap: () => _onNavTap(1),
                  ),
                ]
                else ...[
                  _NavItem(
                    icon: SvgPicture.asset(
                      'assets/icons/new_icon/overview.svg',
                      width: 20,
                      height: 20,
                      color: _currentPage == MainPage.dashboard ? Colors.green : Colors.grey,
                    ),
                    label: 'Tổng quan',
                    selected: _currentPage == MainPage.dashboard,
                    onTap: () => _onNavTap(0),
                  ),
                  _NavItem(
                    icon: SvgPicture.asset(
                      'assets/icons/new_icon/product.svg',
                      width: 20,
                      height: 20,
                      color: _currentPage == MainPage.productList ? Colors.green : Colors.grey,
                    ),
                    label: 'Sản phẩm',
                    selected: _currentPage == MainPage.productList,
                    onTap: () => _onNavTap(1),
                  ),
                  _NavItem(
                    icon: SvgPicture.asset(
                      'assets/icons/new_icon/sell.svg',
                      width: 20,
                      height: 20,
                      color: _currentPage == MainPage.orderCreate ? Colors.green : Colors.grey,
                    ),
                    label: 'Bán hàng',
                    selected: _currentPage == MainPage.orderCreate,
                    onTap: () => _onNavTap(2),
                  ),
                  _NavItem(
                    icon: SvgPicture.asset(
                      'assets/icons/new_icon/companies.svg',
                      width: 20,
                      height: 20,
                      color: _currentPage == MainPage.companies ? Colors.green : Colors.grey,
                    ),
                    label: 'Nhà cung cấp',
                    selected: _currentPage == MainPage.companies,
                    onTap: () => _onNavTap(3),
                  ),
                  _NavItem(
                    icon: SvgPicture.asset(
                      'assets/icons/new_icon/other.svg',
                      width: 20,
                      height: 20,
                      color: _currentPage == MainPage.moreDashboard ? Colors.green : Colors.grey,
                    ),
                    label: 'Thêm',
                    selected: _currentPage == MainPage.moreDashboard,
                    onTap: () => _onNavTap(4),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreInfoBlock extends StatelessWidget {
  final String storeName;
  final String role;
  final VoidCallback onEdit;
  final VoidCallback onInfo;
  const _StoreInfoBlock({required this.storeName, required this.role, required this.onEdit, required this.onInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0, top: 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(storeName, style: responsiveTextStyle(context, h4, h3Mobile)),
                    const SizedBox(height: 2),
                    Text(role, style: responsiveTextStyle(context, labelMedium.copyWith(color: textSecondary), labelSmall.copyWith(color: textSecondary))),
                ],
              ),
            ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Color(0xFF6B7280)),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onInfo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text('Thông tin cửa hàng', style: responsiveTextStyle(context, labelLarge.copyWith(fontWeight: FontWeight.w600), labelMedium.copyWith(fontWeight: FontWeight.w600))),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Color(0xFFB0B4BA), size: 22),
                ],
              ),
        ),
      ),
    ],
      ),
    );
  }
}

class _MoreDashboardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MoreDashboardItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
          decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
          ),
            child: Icon(icon, color: const Color(0xFF16A34A), size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: responsiveTextStyle(
              context,
              labelMedium.copyWith(color: textPrimary),
              labelSmall.copyWith(color: textPrimary),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SettingsListItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _SettingsListItem({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
            Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF16A34A), size: 22),
            const SizedBox(width: 16),
              Expanded(
                child: Text(
                label,
                  style: responsiveTextStyle(
                    context,
                    labelLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : textPrimary,
                    ),
                    labelMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : textPrimary,
                    ),
                  ),
                ),
              ),
            Icon(Icons.chevron_right, color: isDestructive ? Colors.red : Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }
}

class MoreDashboardScreen extends StatelessWidget {
  final void Function(MainPage) onNavigate;
  const MoreDashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
    final User? currentUser = mainLayoutState?._currentUser;
    
    final bool canViewUsers = currentUser?.hasPermission(Permission.viewUsers) ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: MediaQuery.of(context).size.width < 600
            ? _buildMobileLayout(context)
            : _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _MoreDashboardSheetContent(onNavigate: onNavigate),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
    final User? currentUser = mainLayoutState?._currentUser;
    
    final bool canViewUsers = currentUser?.hasPermission(Permission.viewUsers) ?? false;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          child: Builder(
            builder: (context) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Store info and main features
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.store,
                                      color: Colors.green,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cửa hàng ABC',
                                          style: h2.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Nhân viên kho',
                                          style: body.copyWith(color: textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.grey),
                                    onPressed: () {/* TODO */},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F6FA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Thông tin cửa hàng',
                                      style: body.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Main features grid
                        _buildDesktopGroup('Giao dịch', [
                          _MoreDashboardItem(icon: Icons.shopping_cart, label: 'Tạo đơn', onTap: () { onNavigate(MainPage.orderCreate); }),
                          _MoreDashboardItem(icon: Icons.receipt_long, label: 'Hóa đơn', onTap: () {/* TODO */}),
                          _MoreDashboardItem(icon: Icons.store, label: 'Cửa hàng', onTap: () {/* TODO */}),
                        ]),
                        const SizedBox(height: 16),
                        _buildDesktopGroup('Sản phẩm', [
                          _MoreDashboardItem(icon: Icons.inventory_2, label: 'Sản phẩm', onTap: () { onNavigate(MainPage.productList); }),
                          _MoreDashboardItem(icon: Icons.category, label: 'Danh mục', onTap: () { onNavigate(MainPage.productCategory); }),
                          _MoreDashboardItem(icon: Icons.inventory, label: 'Tồn kho', onTap: () { onNavigate(MainPage.inventory); }),
                        ]),
                        const SizedBox(height: 16),
                        _buildDesktopGroup('Đối tác', [
                          _MoreDashboardItem(icon: Icons.people, label: 'Khách hàng', onTap: () { onNavigate(MainPage.customers); }),
                          _MoreDashboardItem(icon: Icons.business, label: 'Nhà cung cấp', onTap: () { onNavigate(MainPage.companies); }),
                        ]),
                        const SizedBox(height: 16),
                        _buildDesktopGroup('Báo cáo', [
                          _MoreDashboardItem(icon: Icons.bar_chart, label: 'Doanh thu', onTap: () {/* TODO */}),
                          _MoreDashboardItem(icon: Icons.inventory, label: 'Hàng tồn', onTap: () {/* TODO */}),
                        ]),
                        const SizedBox(height: 16),
                        _buildDesktopGroup('Tài chính', [
                          _MoreDashboardItem(icon: Icons.payments, label: 'Thanh toán', onTap: () {/* TODO */}),
                          _MoreDashboardItem(icon: Icons.history, label: 'Lịch sử', onTap: () {/* TODO */}),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Right column - Settings and support
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDesktopSettingsBlock('CÀI ĐẶT CHUNG', [
                          _SettingsListItem(icon: Icons.store, label: 'Thiết lập cửa hàng', onTap: () {/* TODO */}),
                          _SettingsListItem(icon: Icons.devices, label: 'Ứng dụng & thiết bị', onTap: () {/* TODO */}),
                          _SettingsListItem(icon: Icons.group, label: 'Quản lý người dùng', onTap: () { onNavigate(MainPage.users); }),
                          _SettingsListItem(icon: Icons.account_balance, label: 'Cài đặt VietQR', onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => VietQRSettingsScreen()));
                          }),
                        ], context),
                        const SizedBox(height: 16),
                        _buildDesktopSettingsBlock('HỖ TRỢ', [
                          _SettingsListItem(icon: Icons.help_outline, label: 'Hướng dẫn sử dụng', onTap: () {/* TODO */}),
                        ], context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopGroup(String title, List<_MoreDashboardItem> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: h4.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: items,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSettingsBlock(String title, List<_SettingsListItem> items, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: h4.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
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
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 2),
              Text(
                label,
                style: responsiveTextStyle(
                  context,
                  labelMedium.copyWith(color: selected ? const Color(0xFF16A34A) : Colors.grey),
                  labelSmall.copyWith(color: selected ? const Color(0xFF16A34A) : Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreDashboardSheetContent extends StatelessWidget {
  final void Function(MainPage) onNavigate;
  const _MoreDashboardSheetContent({required this.onNavigate});

  Future<void> _logout(BuildContext context) async {
    final UserService _userService = UserService();
    
    // Hiển thị dialog xác nhận theo design system
    final confirmed = await showLogoutDialog(context);

    if (confirmed == true) {
      try {
        // Đăng xuất khỏi Firebase Auth
        await _userService.signOut();
        
        // Hiển thị thông báo thành công
        if (context.mounted) {
          showSuccessSnackBar(context, 'Đã đăng xuất thành công');
        }
        
        // Chuyển về màn hình login và xóa tất cả route
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          showErrorSnackBar(context, 'Có lỗi xảy ra: ${e.toString()}');
        }
      }
    }
  }

  Widget _buildGroup(String title, List<_MoreDashboardItem> items) {
    return Builder(
      builder: (context) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final crossAxisCount = isMobile ? 3 : 5;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: responsiveTextStyle(
                  context,
                  h4.copyWith(fontWeight: FontWeight.w700),
                  h3Mobile.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 0.95,
                children: items,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsBlock({required String title, required List<_SettingsListItem> items}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Builder(
              builder: (context) => Text(
                title,
                style: responsiveTextStyle(
                  context,
                  h4.copyWith(fontWeight: FontWeight.w700),
                  h3Mobile.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
    final User? currentUser = mainLayoutState?._currentUser;
    final bool canViewUsers = currentUser?.hasPermission(Permission.viewUsers) ?? false;

    print('TEST: currentUser = ${currentUser?.role.name}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thông tin người dùng hiện tại
        if (currentUser != null)
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(currentUser.roleColor).withOpacity(0.1),
                      child: Text(
                        currentUser.name?.substring(0, 1).toUpperCase() ?? 
                        currentUser.email.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Color(currentUser.roleColor),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.name ?? 'Chưa có tên',
                            style: h4.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser.email,
                            style: body.copyWith(color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(currentUser.roleColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentUser.roleDisplayName,
                        style: caption.copyWith(
                          color: Color(currentUser.roleColor),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentUser.isActive ? mainGreen.withOpacity(0.1) : destructiveRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentUser.isActive ? 'Hoạt động' : 'Vô hiệu',
                        style: caption.copyWith(
                          color: currentUser.isActive ? mainGreen : destructiveRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Quyền: ${currentUser.permissions.length} quyền',
                  style: small.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
        _buildGroup('Giao dịch', [
          _MoreDashboardItem(icon: Icons.shopping_cart, label: 'Tạo đơn', onTap: () { onNavigate(MainPage.orderCreate); }),
          _MoreDashboardItem(icon: Icons.receipt_long, label: 'Hóa đơn', onTap: () {/* TODO: navigate to invoice list */}),
          _MoreDashboardItem(icon: Icons.store, label: 'Cửa hàng', onTap: () {/* TODO: navigate to store info */}),
        ]),
        const SizedBox(height: 10),
        _buildGroup('Sản phẩm', [
          _MoreDashboardItem(icon: Icons.inventory_2, label: 'Sản phẩm', onTap: () { onNavigate(MainPage.productList); }),
          _MoreDashboardItem(icon: Icons.category, label: 'Danh mục', onTap: () { onNavigate(MainPage.productCategory); }),
          _MoreDashboardItem(icon: Icons.upload, label: 'Xuất kho', onTap: () {/* TODO: navigate to export stock */}),
          _MoreDashboardItem(icon: Icons.download, label: 'Nhập kho', onTap: () {/* TODO: navigate to import stock */}),
          _MoreDashboardItem(icon: Icons.inventory, label: 'Tồn kho', onTap: () { onNavigate(MainPage.inventory); }),
          _MoreDashboardItem(icon: Icons.compare_arrows, label: 'Chuyển kho', onTap: () {/* TODO: navigate to transfer stock */}),
        ]),
        const SizedBox(height: 10),
        _buildGroup('Bán online', [
          _MoreDashboardItem(icon: Icons.shopping_bag, label: 'Đơn online', onTap: () {/* TODO: navigate to online orders */}),
          _MoreDashboardItem(icon: Icons.verified, label: 'Đối soát', onTap: () {/* TODO: navigate to reconciliation */}),
        ]),
        const SizedBox(height: 10),
        _buildGroup('Đối tác', [
          _MoreDashboardItem(icon: Icons.people, label: 'Khách hàng', onTap: () { onNavigate(MainPage.customers); }),
          _MoreDashboardItem(icon: Icons.business, label: 'Nhà cung cấp', onTap: () { onNavigate(MainPage.companies); }),
        ]),
        const SizedBox(height: 10),
        _buildGroup('Giao hàng', [
          _MoreDashboardItem(icon: Icons.local_shipping, label: 'Lịch sử GH', onTap: () {/* TODO: navigate to delivery history */}),
          _MoreDashboardItem(icon: Icons.pending_actions, label: 'Đơn chờ GH', onTap: () {/* TODO: navigate to pending delivery */}),
          _MoreDashboardItem(icon: Icons.cancel, label: 'Thất bại', onTap: () {/* TODO: navigate to failed delivery */}),
        ]),
        const SizedBox(height: 10),
        _buildGroup('Nhân viên', [
          _MoreDashboardItem(icon: Icons.badge, label: 'Bảng lương', onTap: () {/* TODO: navigate to payroll */}),
          _MoreDashboardItem(icon: Icons.calendar_month, label: 'Lịch làm', onTap: () {/* TODO: navigate to work calendar */}),
          _MoreDashboardItem(icon: Icons.check_circle, label: 'Chấm công', onTap: () {/* TODO: navigate to attendance */}),
          _MoreDashboardItem(icon: Icons.card_giftcard, label: 'Thưởng', onTap: () {/* TODO: navigate to bonus */}),
          _MoreDashboardItem(icon: Icons.warning, label: 'Phạt', onTap: () {/* TODO: navigate to penalty */}),
        ]),
        const SizedBox(height: 10),
        _buildGroup('Báo cáo', [
          _MoreDashboardItem(icon: Icons.bar_chart, label: 'Doanh thu', onTap: () {/* TODO: navigate to revenue report */}),
          _MoreDashboardItem(icon: Icons.inventory, label: 'Hàng tồn', onTap: () {/* TODO: navigate to stock report */}),
        ]),
        const SizedBox(height: 10),
        _buildGroup('Tài chính', [
          _MoreDashboardItem(icon: Icons.payments, label: 'Thanh toán', onTap: () {/* TODO: navigate to payment */}),
          _MoreDashboardItem(icon: Icons.history, label: 'Lịch sử', onTap: () {/* TODO: navigate to payment history */}),
        ]),
        const SizedBox(height: 10),
        // Các block cài đặt
        _buildSettingsBlock(
          title: 'CÀI ĐẶT CHUNG',
          items: [
            _SettingsListItem(icon: Icons.store, label: 'Thiết lập cửa hàng', onTap: () {/* TODO */}),
            _SettingsListItem(icon: Icons.devices, label: 'Ứng dụng & thiết bị', onTap: () {/* TODO */}),
            if (canViewUsers)
              _SettingsListItem(icon: Icons.group, label: 'Quản lý người dùng', onTap: () { onNavigate(MainPage.users); }),
            if (canViewUsers)
              _SettingsListItem(icon: Icons.security, label: 'Phân quyền chi tiết', onTap: () {
                onNavigate(MainPage.permissionsOverview);
              }),
            _SettingsListItem(icon: Icons.account_balance, label: 'Cài đặt VietQR', onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => VietQRSettingsScreen()));
            }),
          ],
        ),
        _buildSettingsBlock(
          title: 'HỖ TRỢ',
          items: [
            _SettingsListItem(icon: Icons.help_outline, label: 'Hướng dẫn sử dụng', onTap: () {/* TODO */}),
            _SettingsListItem(icon: Icons.smart_toy, label: 'Gọi trợ lý ảo AI free', onTap: () {/* TODO */}),
          ],
        ),
        _buildSettingsBlock(
          title: 'KHÁC',
          items: [
            _SettingsListItem(icon: Icons.language, label: 'Ngôn ngữ', onTap: () {/* TODO */}),
            _SettingsListItem(icon: Icons.description, label: 'Điều khoản sử dụng', onTap: () {/* TODO */}),
            _SettingsListItem(icon: Icons.file_upload, label: 'Import hóa đơn', onTap: () { onNavigate(MainPage.invoiceImportList); }),
            _SettingsListItem(icon: Icons.style, label: 'Style Guide', onTap: () { onNavigate(MainPage.styleGuide); }),
            _SettingsListItem(icon: Icons.screen_share, label: 'Demo Layout', onTap: () { onNavigate(MainPage.demoLayout); }),
            _SettingsListItem(icon: Icons.logout, label: 'Đăng xuất', onTap: () {
              _logout(context);
            }, isDestructive: true),
          ],
        ),
      ],
    );
  }
} 