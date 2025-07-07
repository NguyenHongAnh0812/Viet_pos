import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/common/design_system.dart';

class DashboardModernScreen extends StatelessWidget {
  const DashboardModernScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4), // #f0fdf4
              Color(0xFFEFF6FF), // #eff6ff
            ],
          ),
        ),
        child: Column(
          children: [
            // HEADER: background phủ sát mép trên, nội dung tránh notch
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false, // chỉ tránh notch phía trên
                child: Padding(
                  padding: const EdgeInsets.only(top: 0, bottom: 18),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: mainGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/icons/new_icon/favorite.svg',
                                    width: 28,
                                    height: 28,
                                    colorFilter: ColorFilter.mode(appBackground, BlendMode.srcIn),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('VetPharm', style: responsiveTextStyle(context, h1, h1Mobile).copyWith(color: textPrimary)),
                                  Text('Nhà thuốc thú y', style: responsiveTextStyle(context, bodySmall.copyWith(color: mainGreen), smallMobile.copyWith(color: mainGreen))),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_none, color: Colors.black87),
                                onPressed: () {},
                                tooltip: 'Thông báo',
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout, color: Colors.black87),
                                onPressed: () {},
                                tooltip: 'Đăng xuất',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // MAIN CONTENT BÊN DƯỚI BỌC SafeArea
            Expanded(
              child: SafeArea(
                top: false, // Không cần tránh notch nữa
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 484),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome
                          Text('Chào mừng bạn trở lại!', style: responsiveTextStyle(context, h1, h1Mobile)),
                          const SizedBox(height: 4),
                          Text('Quản lý nhà thuốc thú y một cách hiệu quả', style: responsiveTextStyle(context, body, bodyMobile).copyWith(color: textSecondary)),
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
                                Text('Thống kê nhanh hôm nay', style: responsiveTextStyle(context, body, bodyMobile).copyWith(fontWeight: FontWeight.bold)),
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
                                Text('Thao tác nhanh', style: responsiveTextStyle(context, h3, h3Mobile).copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    // Tìm sản phẩm
                                    Expanded(
                                      child: SizedBox(
                                        height: 52,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: textPrimary,
                                            side: const BorderSide(color: borderColor),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            backgroundColor: Colors.white,
                                            textStyle: responsiveTextStyle(context, body, bodyMobile),
                                            minimumSize: const Size(0, 52),
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                          onPressed: () {},
                                          icon: const Icon(Icons.search, size: 20),
                                          label: Text(
                                            'Tìm sản phẩm',
                                            style: responsiveTextStyle(context, labelLarge, labelSmall),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Quét mã
                                    Expanded(
                                      child: SizedBox(
                                        height: 52,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: textPrimary,
                                            side: const BorderSide(color: borderColor),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            backgroundColor: Colors.white,
                                            textStyle: responsiveTextStyle(context, body, bodyMobile),
                                            minimumSize: const Size(0, 52),
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                          onPressed: () {},
                                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                                          label: Text(
                                            'Quét mã',
                                            style: responsiveTextStyle(context, labelLarge, labelSmall),
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
          style: responsiveTextStyle(context, h1, h1Mobile).copyWith(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: responsiveTextStyle(context, bodySmall, smallMobile).copyWith(color: textSecondary),
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
        Icon(icon, color: selected ? mainGreen : textSecondary),
        const SizedBox(height: 2),
        Text(
          label,
          style: responsiveTextStyle(context, labelSmall, captionMobile).copyWith(color: selected ? mainGreen : textSecondary),
        ),
      ],
    );
  }
} 