import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../widgets/common/design_system.dart';

class CustomerListScreen extends StatefulWidget {
  final VoidCallback? onAddCustomer;
  final Function(Customer)? onCustomerTap;
  const CustomerListScreen({super.key, this.onAddCustomer, this.onCustomerTap});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _customerService = CustomerService();
  String? _statusFilter;
  String? _searchText;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: appBackground,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        elevation: 8,
        onPressed: widget.onAddCustomer,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text('Danh sách khách hàng', style: h2Mobile),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: textPrimary),
                    onPressed: () {
                      // TODO: Hiển thị popup tìm kiếm
                    },
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: borderColor,
            ),
            // Body
            Expanded(
              child: Container(
                color: appBackground,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                width: double.infinity,
                child: StreamBuilder<List<Customer>>(
                  stream: _customerService.getCustomers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Lỗi: {snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final customers = snapshot.data!;
                    if (customers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Chưa có khách hàng nào.', style: bodyMobile),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _createDemoData,
                              icon: const Icon(Icons.data_usage),
                              label: const Text('Tạo dữ liệu demo'),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final customer = customers[i];
                        return GestureDetector(
                          onTap: () => widget.onCustomerTap?.call(customer),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(customer.name, style: h3Mobile),
                                      const SizedBox(height: 4),
                                      Text(customer.phone, style: bodyMobile),
                                      if (customer.email != null && customer.email!.isNotEmpty)
                                        Text(customer.email!, style: smallMobile),
                                    ],
                                  ),
                                ),
                                DesignSystemBadge(
                                  text: 'Hoạt động',
                                  variant: BadgeVariant.secondary,
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: textSecondary, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo dữ liệu demo'),
        content: const Text('Bạn có muốn tạo 8 khách hàng mẫu để test không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Đang tạo dữ liệu demo...'),
          ],
        ),
      ),
    );

    try {
      await _customerService.createDemoData();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo thành công 8 khách hàng demo!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 