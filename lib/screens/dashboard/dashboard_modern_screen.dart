import 'package:flutter/material.dart';
import '../../widgets/common/design_system_update.dart';

class DashboardModernScreen extends StatelessWidget {
  const DashboardModernScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.secondaryColor,
      body: Column(
        children: [
          // Header logo block
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppDesignSystem.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.favorite, color: AppDesignSystem.primaryColor, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VetPharm', style: AppDesignSystem.headingLg.copyWith(color: AppDesignSystem.primaryColor)),
                      Text('Nhà thuốc thú y', style: AppDesignSystem.textSm.copyWith(color: AppDesignSystem.primaryColor.withOpacity(0.7))),
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
                constraints: const BoxConstraints(maxWidth: 484),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome
                        Text('Chào mừng bạn trở lại!', style: AppDesignSystem.headingLg),
                        const SizedBox(height: 4),
                        Text('Quản lý nhà thuốc thú y một cách hiệu quả', style: AppDesignSystem.textBase.copyWith(color: AppDesignSystem.mutedForegroundColor)),
                        const SizedBox(height: 32),
                        // Quick Stats
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Thống kê nhanh hôm nay', style: AppDesignSystem.textBase.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _StatItem(value: '12', label: 'Đơn hàng', color: AppDesignSystem.successColor),
                                  _StatItem(value: '2.4M', label: 'Doanh thu', color: AppDesignSystem.infoColor, isBold: true),
                                  _StatItem(value: '156', label: 'Sản phẩm', color: AppDesignSystem.warningColor),
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
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Thao tác nhanh', style: AppDesignSystem.textLg.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  // Tìm sản phẩm
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppDesignSystem.foregroundColor,
                                          side: const BorderSide(color: AppDesignSystem.borderColor),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          backgroundColor: Colors.white,
                                          textStyle: AppDesignSystem.textBase,
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
                                          foregroundColor: AppDesignSystem.foregroundColor,
                                          side: const BorderSide(color: AppDesignSystem.borderColor),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          backgroundColor: Colors.white,
                                          textStyle: AppDesignSystem.textBase,
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
          style: AppDesignSystem.headingLg.copyWith(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppDesignSystem.textSm.copyWith(color: AppDesignSystem.mutedForegroundColor),
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
            children: const [
              _NavItem(icon: Icons.dashboard, label: 'Tổng quan', selected: true),
              _NavItem(icon: Icons.inventory_2, label: 'Hàng hoá'),
              _NavItem(icon: Icons.shopping_cart, label: 'Bán hàng'),
              _NavItem(icon: Icons.people, label: 'Nhà cung cấp'),
              _NavItem(icon: Icons.more_horiz, label: 'Thêm'),
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
  const _NavItem({required this.icon, required this.label, this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: selected ? AppDesignSystem.primaryColor : AppDesignSystem.mutedForegroundColor),
        const SizedBox(height: 2),
        Text(label, style: AppDesignSystem.textXs.copyWith(color: selected ? AppDesignSystem.primaryColor : AppDesignSystem.mutedForegroundColor)),
      ],
    );
  }
} 