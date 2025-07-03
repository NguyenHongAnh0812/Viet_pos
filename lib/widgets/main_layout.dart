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
import '../screens/settings_screen.dart';

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
  orderCreate,
  moreDashboard
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
          _currentPage = MainPage.moreDashboard;
          break;
      }
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
                    Text(storeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF222B45))),
                    const SizedBox(height: 2),
                    Text(role, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
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
                children: const [
                  Text('Thông tin cửa hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF222B45))),
                  Spacer(),
                  Icon(Icons.chevron_right, color: Color(0xFFB0B4BA), size: 22),
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF222B45)),
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red : const Color(0xFF222B45),
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
  const MoreDashboardScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StoreInfoBlock(
                  storeName: 'Cửa hàng ABC',
                  role: 'Nhân viên kho',
                  onEdit: () {/* TODO: Sửa thông tin cửa hàng */},
                  onInfo: () {/* TODO: Xem thông tin cửa hàng */},
                ),
                const SizedBox(height: 10),
                _MoreDashboardSheetContent(onNavigate: onNavigate),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreDashboardSheetContent extends StatelessWidget {
  final void Function(MainPage) onNavigate;
  const _MoreDashboardSheetContent({required this.onNavigate});

  Widget _buildGroup(String title, List<_MoreDashboardItem> items) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF222B45))),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
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
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF222B45))),
          ),
          ...items,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroup('Giao dịch', [
          _MoreDashboardItem(icon: Icons.shopping_cart, label: 'Tạo đơn', onTap: () { onNavigate(MainPage.orderCreate); }),
          _MoreDashboardItem(icon: Icons.receipt_long, label: 'Hóa đơn', onTap: () {/* TODO: navigate to invoice list */}),
          _MoreDashboardItem(icon: Icons.store, label: 'Cửa hàng', onTap: () {/* TODO: navigate to store info */}),
        ]),
        const SizedBox(height: 10),
        _buildGroup('Hàng hoá', [
          _MoreDashboardItem(icon: Icons.inventory_2, label: 'Hàng hoá', onTap: () { onNavigate(MainPage.productList); }),
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
            _SettingsListItem(icon: Icons.group, label: 'Quản lý người dùng', onTap: () {/* TODO */}),
          ],
        ),
        _buildSettingsBlock(
          title: 'HỖ TRỢ',
          items: [
            _SettingsListItem(icon: Icons.help_outline, label: 'Hướng dẫn sử dụng', onTap: () {/* TODO */}),
            _SettingsListItem(icon: Icons.chat, label: 'Chat với KiotViet', onTap: () {/* TODO */}),
            _SettingsListItem(icon: Icons.phone, label: 'Gọi tổng đài 19006522', onTap: () {/* TODO */}),
            _SettingsListItem(icon: Icons.support_agent, label: 'Chuyên viên hỗ trợ qua Zalo', onTap: () {/* TODO */}),
            _SettingsListItem(icon: Icons.smart_toy, label: 'Gọi trợ lý ảo AI free', onTap: () {/* TODO */}),
          ],
        ),
        _buildSettingsBlock(
          title: 'KHÁC',
          items: [
            _SettingsListItem(icon: Icons.language, label: 'Ngôn ngữ', onTap: () {/* TODO */}),
            _SettingsListItem(icon: Icons.description, label: 'Điều khoản sử dụng', onTap: () {/* TODO */}),
            _SettingsListItem(icon: Icons.logout, label: 'Đăng xuất', onTap: () {/* TODO: logout */}, isDestructive: true),
          ],
        ),
      ],
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? const Color(0xFF16A34A) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
} 