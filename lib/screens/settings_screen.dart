import 'package:flutter/material.dart';
import '../services/app_config_service.dart';
import '../widgets/common/design_system.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const SettingsScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final appConfigService = AppConfigService();

    return Scaffold(
      backgroundColor: appBackground,
      body: Padding(
        padding: MediaQuery.of(context).size.width < 600 ? const EdgeInsets.symmetric(horizontal: 15) : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: ListView(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack ?? () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                const Text('Cài đặt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              ],
            ),
            const SizedBox(height: 24),
            designSystemFormCard(
              title: 'Cài đặt hiển thị',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tùy chỉnh cách hiển thị thông tin trong ứng dụng', style: small.copyWith(color: textSecondary)),
                  const SizedBox(height: 20),
                  StreamBuilder(
                    stream: appConfigService.getConfig(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Có lỗi xảy ra: ${snapshot.error}');
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final config = snapshot.data!;
                      return Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Hiển thị thông tin chi tiết sản phẩm'),
                            subtitle: Text(
                              'Khi bật, các thông tin chi tiết như mô tả, công dụng, thành phần sẽ được hiển thị trong trang chi tiết sản phẩm',
                              style: small.copyWith(color: textSecondary),
                            ),
                            value: config.showProductDetails,
                            onChanged: (value) {
                              appConfigService.updateShowProductDetails(value);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 