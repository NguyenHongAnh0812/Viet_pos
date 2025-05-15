import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _sidebarOpen = true;
  int _selectedIndex = 0;

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
      // TODO: Điều hướng tới các trang tương ứng
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
                      widget.child,
                      // Hiệu ứng fade cho lớp mờ nền
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
                      // Hiệu ứng trượt cho sidebar
                      AnimatedSlide(
                        offset: _sidebarOpen ? Offset(0, 0) : Offset(-1, 0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                        child: SizedBox(
                          width: 250,
                          child: _Sidebar(isOpen: true),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _sidebarOpen ? 250 : 70,
                        child: _Sidebar(isOpen: _sidebarOpen),
                      ),
                      Expanded(child: widget.child),
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
                  icon: Icon(Icons.inventory_2),
                  label: 'Sản phẩm',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Báo cáo',
                ),
              ],
            )
          : null,
    );
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
  const _Sidebar({this.isOpen = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isOpen ? 250 : 70,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 0),
          _SidebarItem(icon: Icons.home, label: 'Trang chủ', selected: true, isOpen: isOpen),
          _SidebarItem(icon: Icons.inventory_2, label: 'Danh sách sản phẩm', isOpen: isOpen),
          _SidebarItem(icon: Icons.category, label: 'Danh mục sản phẩm', isOpen: isOpen),
          _SidebarItem(icon: Icons.check_box, label: 'Kiểm kê', isOpen: isOpen),
          _SidebarItem(icon: Icons.bar_chart, label: 'Báo cáo', isOpen: isOpen),
          _SidebarItem(icon: Icons.settings, label: 'Cài đặt', isOpen: isOpen),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isOpen;
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.isOpen = true,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool showHighlight = widget.selected || _isHovering;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.ease,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: showHighlight ? Colors.blue.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: ListTile(
          leading: Icon(widget.icon, color: widget.selected ? Colors.blue : Colors.black54),
          title: widget.isOpen
              ? Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    widget.label,
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
          onTap: () {
            // TODO: Xử lý chuyển trang
          },
        ),
      ),
    );
  }
} 