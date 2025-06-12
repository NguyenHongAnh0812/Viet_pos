import 'package:flutter/material.dart';
import '../../widgets/common/design_system.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final String route;
  final List<SubMenuItem>? subItems;

  const MenuItem({
    required this.title,
    required this.icon,
    required this.route,
    this.subItems,
  });
}

class SubMenuItem {
  final String title;
  final String route;

  const SubMenuItem({
    required this.title,
    required this.route,
  });
}

class SidebarMenu extends StatefulWidget {
  const SidebarMenu({super.key});

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  final List<MenuItem> menuItems = [
    const MenuItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: '/dashboard',
    ),
    const MenuItem(
      title: 'Sản phẩm',
      icon: Icons.inventory_2_outlined,
      route: '/products',
      subItems: [
        SubMenuItem(
          title: 'Danh sách sản phẩm',
          route: '/products',
        ),
        SubMenuItem(
          title: 'Thêm sản phẩm',
          route: '/addProduct',
        ),
        SubMenuItem(
          title: 'Danh mục sản phẩm',
          route: '/product-categories',
        ),
      ],
    ),
    const MenuItem(
      title: 'Kho hàng',
      icon: Icons.warehouse_outlined,
      route: '/inventory',
      subItems: [
        SubMenuItem(
          title: 'Tồn kho',
          route: '/inventory',
        ),
        SubMenuItem(
          title: 'Lịch sử nhập xuất',
          route: '/inventory-history',
        ),
        SubMenuItem(
          title: 'Sản phẩm sắp hết',
          route: '/low-stock-products',
        ),
      ],
    ),
    const MenuItem(
      title: 'Import Hóa đơn',
      icon: Icons.upload_file_outlined,
      route: '/invoice-imports',
      subItems: [
        SubMenuItem(
          title: 'Danh sách Import',
          route: '/invoice-imports',
        ),
        SubMenuItem(
          title: 'Import mới',
          route: '/invoice-import',
        ),
      ],
    ),
  ];

  String? _selectedRoute;
  String? _expandedMenuTitle;

  @override
  void initState() {
    super.initState();
    _selectedRoute = '/dashboard';
    _expandedMenuTitle = 'Dashboard';
  }

  void _handleMenuTap(MenuItem item) {
    setState(() {
      if (item.subItems != null) {
        if (_expandedMenuTitle == item.title) {
          _expandedMenuTitle = null;
        } else {
          _expandedMenuTitle = item.title;
        }
      } else {
        _selectedRoute = item.route;
        _expandedMenuTitle = null;
      }
    });
  }

  void _handleSubMenuTap(SubMenuItem item) {
    setState(() {
      _selectedRoute = item.route;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: sidebarWidth,
      color: sidebarBackground,
      child: Column(
        children: [
          Container(
            height: headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: space16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: sidebarBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 32,
                ),
                const SizedBox(width: space12),
                Text(
                  'VET-POS',
                  style: h3.copyWith(color: sidebarForeground),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: space16),
              children: menuItems.map((item) {
                final isExpanded = _expandedMenuTitle == item.title;
                final isSelected = _selectedRoute == item.route;

                return Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected ? sidebarPrimary : sidebarForeground,
                      ),
                      title: Text(
                        item.title,
                        style: body.copyWith(
                          color: isSelected ? sidebarPrimary : sidebarForeground,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: item.subItems != null
                          ? Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: sidebarForeground,
                            )
                          : null,
                      selected: isSelected,
                      selectedTileColor: sidebarAccent,
                      onTap: () => _handleMenuTap(item),
                    ),
                    if (isExpanded && item.subItems != null)
                      ...item.subItems!.map((subItem) {
                        final isSubSelected = _selectedRoute == subItem.route;
                        return ListTile(
                          leading: const SizedBox(width: space32),
                          title: Text(
                            subItem.title,
                            style: body.copyWith(
                              color: isSubSelected ? sidebarPrimary : sidebarForeground,
                              fontWeight: isSubSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          selected: isSubSelected,
                          selectedTileColor: sidebarAccent,
                          onTap: () => _handleSubMenuTap(subItem),
                        );
                      }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
} 