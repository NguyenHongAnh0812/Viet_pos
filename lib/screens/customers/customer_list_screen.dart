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
      appBar: AppBar(
        title: const Text('Danh sách khách hàng'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: OutlinedButton.icon(
              onPressed: _createDemoData,
              icon: const Icon(Icons.data_usage, size: 16),
              label: const Text('Demo Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: widget.onAddCustomer,
              icon: const Icon(Icons.add),
              label: const Text('Thêm khách hàng'),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Customer>>(
        stream: _customerService.getCustomers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final customers = snapshot.data!;
          if (customers.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có khách hàng nào.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createDemoData,
                      icon: const Icon(Icons.data_usage),
                      label: const Text('Tạo dữ liệu demo'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: StandardTableContainer(
                child: Column(
                  children: [
                    StandardTableHeader(
                      children: [
                        TableColumn(flex: 2, child: Text('Tên', style: TableDesignSystem.tableHeaderTextStyle)),
                        TableColumn(flex: 2, child: Text('Số điện thoại', style: TableDesignSystem.tableHeaderTextStyle)),
                        TableColumn(flex: 2, child: Text('Email', style: TableDesignSystem.tableHeaderTextStyle)),
                        TableColumn(flex: 2, child: Text('Công ty', style: TableDesignSystem.tableHeaderTextStyle)),
                        TableColumnFixed(width: 100, child: Text('Trạng thái', style: TableDesignSystem.tableHeaderTextStyle)),
                      ],
                    ),
                    ...customers.map((customer) => StandardTableRow(
                      onTap: () => widget.onCustomerTap?.call(customer),
                      children: [
                        TableColumn(flex: 2, child: Text(customer.name, style: TableDesignSystem.tableRowTextStyle)),
                        TableColumn(flex: 2, child: Text(customer.phone, style: TableDesignSystem.tableRowTextStyle)),
                        TableColumn(flex: 2, child: Text(customer.email ?? '', style: TableDesignSystem.tableRowTextStyle)),
                        TableColumn(flex: 2, child: Text(customer.companyId ?? '', style: TableDesignSystem.tableRowTextStyle)),
                        TableColumnFixed(
                          width: 100,
                          child: DesignSystemBadge(
                            text: 'Hoạt động',
                            variant: BadgeVariant.secondary,
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          );
        },
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