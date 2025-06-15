import 'package:flutter/material.dart';
import '../models/distributor.dart';
import '../services/distributor_service.dart';
import '../widgets/common/design_system.dart';

class DistributorScreen extends StatefulWidget {
  const DistributorScreen({Key? key}) : super(key: key);

  @override
  State<DistributorScreen> createState() => _DistributorScreenState();
}

class _DistributorScreenState extends State<DistributorScreen> {
  final DistributorService _service = DistributorService();

  void _showDistributorDialog({Distributor? distributor}) {
    final nameController = TextEditingController(text: distributor?.name ?? '');
    final phoneController = TextEditingController(text: distributor?.phone ?? '');
    final addressController = TextEditingController(text: distributor?.address ?? '');
    showDesignSystemDialog(
      context: context,
      title: distributor == null ? 'Thêm nhà phân phối' : 'Sửa nhà phân phối',
      content: designSystemFormCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesignSystemFormField(
              label: 'Tên nhà phân phối',
              required: true,
              input: TextField(
                controller: nameController,
                decoration: designSystemInputDecoration(hint: 'Nhập tên nhà phân phối'),
              ),
            ),
            const SizedBox(height: 16),
            DesignSystemFormField(
              label: 'Số điện thoại',
              input: TextField(
                controller: phoneController,
                decoration: designSystemInputDecoration(hint: 'Nhập số điện thoại'),
              ),
            ),
            const SizedBox(height: 16),
            DesignSystemFormField(
              label: 'Địa chỉ',
              input: TextField(
                controller: addressController,
                decoration: designSystemInputDecoration(hint: 'Nhập địa chỉ'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: ghostBorderButtonStyle,
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) return;
            if (distributor == null) {
              await _service.addDistributor(Distributor(
                id: '',
                name: name,
                phone: phoneController.text.trim(),
                address: addressController.text.trim(),
              ));
            } else {
              await _service.updateDistributor(distributor.id, {
                'name': name,
                'phone': phoneController.text.trim(),
                'address': addressController.text.trim(),
              });
            }
            if (mounted) Navigator.pop(context);
          },
          style: primaryButtonStyle,
          child: const Text('Lưu'),
        ),
      ],
      maxWidth: 420,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý nhà phân phối'),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showDistributorDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm nhà phân phối'),
                  style: primaryButtonStyle,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<Distributor>>(
                stream: _service.getDistributors(),
                builder: (context, snapshot) {
                  final distributors = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (distributors.isEmpty) {
                    return const Center(child: Text('Chưa có nhà phân phối nào.'));
                  }
                  return ListView.separated(
                    itemCount: distributors.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final d = distributors[i];
                      return ListTile(
                        title: Text(d.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (d.phone != null && d.phone!.isNotEmpty) Text('SĐT: ${d.phone}'),
                            if (d.address != null && d.address!.isNotEmpty) Text('Địa chỉ: ${d.address}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showDistributorDialog(distributor: d),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await _service.deleteDistributor(d.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 