import 'package:flutter/material.dart';
import '../services/app_config_service.dart';
import '../widgets/common/design_system.dart';
import '../services/app_payment_setting_service.dart';
import '../models/app_payment_setting.dart';

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
            designSystemFormCard(
              title: 'Cài đặt tài khoản ngân hàng (VietQR)',
              child: BankSettingForm(),
            ),
          ],
        ),
      ),
    );
  }
}

class BankSettingForm extends StatefulWidget {
  @override
  State<BankSettingForm> createState() => _BankSettingFormState();
}

class _BankSettingFormState extends State<BankSettingForm> {
  final _service = AppPaymentSettingService();
  final _formKey = GlobalKey<FormState>();
  final _bankCodeController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final setting = await _service.getSetting();
    if (setting != null) {
      _bankCodeController.text = setting.bankCode;
      _bankAccountController.text = setting.bankAccount;
      _bankNameController.text = setting.bankName;
      _accountNameController.text = setting.accountName;
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _bankCodeController,
            decoration: const InputDecoration(labelText: 'Mã ngân hàng (VD: VCB, TCB, BIDV...)'),
            validator: (v) => v == null || v.isEmpty ? 'Không được để trống' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bankAccountController,
            decoration: const InputDecoration(labelText: 'Số tài khoản'),
            validator: (v) => v == null || v.isEmpty ? 'Không được để trống' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bankNameController,
            decoration: const InputDecoration(labelText: 'Tên ngân hàng'),
            validator: (v) => v == null || v.isEmpty ? 'Không được để trống' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accountNameController,
            decoration: const InputDecoration(labelText: 'Tên chủ tài khoản'),
            validator: (v) => v == null || v.isEmpty ? 'Không được để trống' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              setState(() => _loading = true);
              await _service.updateSetting(AppPaymentSetting(
                bankCode: _bankCodeController.text.trim(),
                bankAccount: _bankAccountController.text.trim(),
                bankName: _bankNameController.text.trim(),
                accountName: _accountNameController.text.trim(),
              ));
              setState(() => _loading = false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu cài đặt ngân hàng!')));
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class VietQRSettingsScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const VietQRSettingsScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading xanh, chữ trắng
            Container(
              color: mainGreen,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack ?? () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Cài đặt VietQR',
                      style: h2Mobile.copyWith(color: Colors.white),
                      textAlign: TextAlign.left,
                    ),
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
                child: ListView(
                  children: [
                    // Card thông tin tài khoản ngân hàng
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance, color: mainGreen, size: 20),
                              const SizedBox(width: 8),
                              Text('Thông tin tài khoản ngân hàng', style: h3Mobile),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cấu hình thông tin tài khoản ngân hàng để tạo QR code thanh toán VietQR',
                            style: bodyMobile.copyWith(color: textSecondary),
                          ),
                          const SizedBox(height: 16),
                          BankSettingForm(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Card hướng dẫn sử dụng
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.help_outline, color: mainGreen, size: 20),
                              const SizedBox(width: 8),
                              Text('Hướng dẫn sử dụng', style: h3Mobile),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cách sử dụng VietQR trong ứng dụng:',
                            style: bodyMobile.copyWith(color: textSecondary),
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionItem('1', 'Cấu hình thông tin tài khoản ngân hàng ở trên'),
                          _buildInstructionItem('2', 'Khi tạo đơn hàng, chọn phương thức "Chuyển khoản"'),
                          _buildInstructionItem('3', 'QR code sẽ được tạo tự động với thông tin đã cấu hình'),
                          _buildInstructionItem('4', 'Khách hàng quét QR để thanh toán qua ứng dụng ngân hàng'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: mainGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: bodyMobile),
          ),
        ],
      ),
    );
  }
} 