import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onViewProductList;
  final VoidCallback? onViewLowStockProducts;
  const DashboardScreen({super.key, this.onViewProductList, this.onViewLowStockProducts});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _productService = ProductService();

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xảy ra lỗi khi đăng xuất')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 0,
              maxWidth: constraints.maxWidth,
            ),
            child: StreamBuilder<List<Product>>(
              stream: _productService.getProducts(),
              builder: (context, snapshot) {
                final products = snapshot.data ?? [];
                final lowStockCount = products.where((p) => (p.stock ?? 0) < 60).length;
                final isMobile = MediaQuery.of(context).size.width < 600;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header content
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bảng Điều Khiển',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          tooltip: 'Đăng xuất',
                          onPressed: () => _signOut(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Dashboard cards
                    isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _DashboardCard(
                                title: 'Tổng Sản Phẩm',
                                value: '${products.length}',
                                icon: Icons.inventory_2,
                                onTap: widget.onViewProductList ?? () {},
                              ),
                              const SizedBox(height: 3),
                              _DashboardCard(
                                title: 'Lịch Sử Kiểm Kê',
                                value: '2',
                                icon: Icons.history,
                                onTap: () {},
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _DashboardCard(
                                  title: 'Tổng Sản Phẩm',
                                  value: '${products.length}',
                                  icon: Icons.inventory_2,
                                  onTap: widget.onViewProductList ?? () {},
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _DashboardCard(
                                  title: 'Lịch Sử Kiểm Kê',
                                  value: '2',
                                  icon: Icons.history,
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                    // Cảnh báo sản phẩm sắp hết hàng
                    const SizedBox(height: 0),
                    if (lowStockCount > 0)
                      GestureDetector(
                        onTap: widget.onViewLowStockProducts,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(child: Text('$lowStockCount sản phẩm sắp hết hàng', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600))),
                              const Text('Cần được xử lý', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Hoạt Động Gần Đây',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _RecentActivity(
                      icon: Icons.event_available,
                      title: 'Kiểm kê hoàn thành',
                      subtitle: 'Đã kiểm tra 25 sản phẩm',
                      time: '15/04/2024, 10:23',
                    ),
                    _RecentActivity(
                      icon: Icons.add,
                      title: 'Thêm mới sản phẩm',
                      subtitle: 'Amoxicillin 250mg',
                      time: '14/04/2024, 16:17',
                    ),
                    _RecentActivity(
                      icon: Icons.warning,
                      title: 'Cảnh báo hàng sắp hết',
                      subtitle: '3 sản phẩm sắp hết hàng',
                      time: '13/04/2024, 09:41',
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _DashboardCard({required this.title, required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bên trái: tiêu đề và số lượng
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
                ],
              ),
            ),
            // Bên phải: icon và xem chi tiết
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(icon, size: 28, color: Colors.grey[400]),
                const SizedBox(height: 32),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Xem chi tiết', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  const _RecentActivity({required this.icon, required this.title, required this.subtitle, required this.time});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(time, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 