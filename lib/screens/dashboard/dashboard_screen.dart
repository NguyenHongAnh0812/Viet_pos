import 'package:flutter/material.dart';
import '../../widgets/common/design_system.dart';

class DashboardModernScreen extends StatelessWidget {
  const DashboardModernScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: Column(
        children: [
          // Header logo block
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: mainGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.favorite, color: mainGreen, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VetPharm', style: h1.copyWith(color: mainGreen)),
                      Text('Nhà thuốc thú y', style: bodySmall.copyWith(color: mainGreen.withValues(alpha: 0.7))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Main content scrollable
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome
                        Text('Chào mừng bạn trở lại!', style: h1),
                        const SizedBox(height: 4),
                        Text('Quản lý nhà thuốc thú y một cách hiệu quả', style: body.copyWith(color: textMuted)),
                        const SizedBox(height: 32),
                        // Quick Stats
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Thống kê nhanh hôm nay', style: body.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _StatItem(value: '12', label: 'Đơn hàng', color: successGreen),
                                  _StatItem(value: '2.4M', label: 'Doanh thu', color: infoBlue, isBold: true),
                                  _StatItem(value: '156', label: 'Sản phẩm', color: warningOrange),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Quick Actions
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Thao tác nhanh', style: h3.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  // Tìm sản phẩm
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: textPrimary,
                                          side: const BorderSide(color: borderColor),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          backgroundColor: Colors.white,
                                          textStyle: body,
                                        ),
                                        onPressed: () {},
                                        icon: const Icon(Icons.search, size: 20),
                                        label: const Text('Tìm sản phẩm'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Quét mã
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: textPrimary,
                                          side: const BorderSide(color: borderColor),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          backgroundColor: Colors.white,
                                          textStyle: body,
                                        ),
                                        onPressed: () {},
                                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                                        label: const Text('Quét mã'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: Center(
      //   child: ConstrainedBox(
      //     constraints: const BoxConstraints(maxWidth: 484),
      //     child: _BottomNavBar(),
      //   ),
      // ), 
    );
  }
}

void showMoreSheet(BuildContext context) {
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
        // ... thêm các item khác nếu cần
      ];
      return Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: items.map((item) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: mainGreen.withOpacity(0.1),
                child: Icon(item['icon'] as IconData, color: mainGreen),
              ),
              const SizedBox(height: 8),
              Text(item['label'] as String, style: bodySmall),
            ],
          )).toList(),
        ),
      );
    },
  );
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isBold;
  const _StatItem({required this.value, required this.label, required this.color, this.isBold = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: h1.copyWith(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: bodySmall.copyWith(color: textMuted),
        ),
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              const _NavItem(icon: Icons.dashboard, label: 'Tổng quan 2', selected: true),
              const _NavItem(icon: Icons.inventory_2, label: 'Hàng hoá'),
              const _NavItem(icon: Icons.shopping_cart, label: 'Bán hàng'),
              const _NavItem(icon: Icons.people, label: 'Nhà cung cấp'),
              _NavItem(
                icon: Icons.more_horiz,
                label: 'Thêm',
                onTap: () => showMoreSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _NavItem({required this.icon, required this.label, this.selected = false, this.onTap});
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
              Icon(icon, color: selected ? mainGreen : textMuted),
              const SizedBox(height: 2),
              Text(label, style: bodySmall.copyWith(color: selected ? mainGreen : textMuted)),
            ],
          ),
        ),
      ),
    );
  }
} 