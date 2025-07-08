import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../widgets/common/design_system.dart';

class AddCustomerScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Function(Customer)? onCustomerAdded; // Callback để trả về customer mới
  const AddCustomerScreen({super.key, this.onSuccess, this.onCustomerAdded});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxCodeController = TextEditingController();
  String? _gender;
  String? _companyId;
  bool _isSupplier = false;
  double? _discount;
  double? _priceAdjust;
  bool _saving = false;
  String gender = 'Anh';
  String customerType = 'individual'; // 'individual' hoặc 'organization'
  final birthdayController = TextEditingController();
  final noteController = TextEditingController();
  final orgNameController = TextEditingController();
  final taxController = TextEditingController();
  final orgAddressController = TextEditingController();
  final invoiceEmailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taxCodeController.dispose();
    birthdayController.dispose();
    noteController.dispose();
    orgNameController.dispose();
    taxController.dispose();
    orgAddressController.dispose();
    invoiceEmailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    print('[AddCustomerScreen] Bắt đầu submit form');
    if (!_formKey.currentState!.validate()) {
      print('[AddCustomerScreen] Form không hợp lệ, không lưu');
      return;
    }

    setState(() => _saving = true);
    try {
      String? finalCompanyId = _companyId;
      if (customerType == 'organization' && orgNameController.text.trim().isNotEmpty) {
        finalCompanyId = orgNameController.text.trim();
      }

      final customer = Customer(
        id: '',
        name: _nameController.text.trim(),
        gender: gender,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        discount: _discount,
        taxCode: customerType == 'organization' ? taxController.text.trim() : _taxCodeController.text.trim(),
        tags: [],
        companyId: finalCompanyId ?? '',
        orgName: customerType == 'organization' ? orgNameController.text.trim() : '',
        orgAddress: customerType == 'organization' ? orgAddressController.text.trim() : '',
        invoiceEmail: customerType == 'organization' ? invoiceEmailController.text.trim() : '',
        birthday: birthdayController.text.trim().isNotEmpty ? birthdayController.text.trim() : null,
        note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
        customerType: customerType,
      );
      print('[AddCustomerScreen] Dữ liệu customer chuẩn bị lưu: ${customer.toMap()}');
      
      // Lưu customer và lấy ID
      final customerService = CustomerService();
      final docRef = await customerService.addCustomerAndGetId(customer);
      
      // Tạo customer với ID mới
      final savedCustomer = Customer(
        id: docRef.id,
        name: customer.name,
        gender: customer.gender,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
        discount: customer.discount,
        taxCode: customer.taxCode,
        tags: customer.tags,
        companyId: customer.companyId,
        orgName: customer.orgName,
        orgAddress: customer.orgAddress,
        invoiceEmail: customer.invoiceEmail,
        birthday: customer.birthday,
        note: customer.note,
        customerType: customer.customerType,
      );
      
      print('[AddCustomerScreen] Lưu khách hàng thành công với ID: ${docRef.id}');
      
      if (mounted) {
        // Hiển thị thông báo thành công
        OverlayEntry? entry;
        entry = OverlayEntry(
          builder: (_) => DesignSystemSnackbar(
            message: 'Đã thêm khách hàng thành công',
            icon: Icons.check_circle,
            onDismissed: () => entry?.remove(),
          ),
        );
        Overlay.of(context).insert(entry);
        await Future.delayed(const Duration(milliseconds: 600));
        
        // Gọi callback để trả về customer mới
        widget.onCustomerAdded?.call(savedCustomer);
        widget.onSuccess?.call();
        
        // Trở về màn hình trước đó
        Navigator.of(context).pop(savedCustomer);
      }
    } catch (e, stack) {
      print('[AddCustomerScreen] Lỗi khi lưu khách hàng: $e');
      print(stack);
      if (mounted) {
        _showError('Lỗi: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) return 'Email không hợp lệ';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
    if (value.trim().length < 10) return 'Số điện thoại phải có ít nhất 10 số';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập họ và tên';
    if (value.trim().length < 2) return 'Họ và tên phải có ít nhất 2 ký tự';
    return null;
  }

  String? _validateOrgName(String? value) {
    if (customerType == 'organization' && (value == null || value.trim().isEmpty)) {
      return 'Vui lòng nhập tên tổ chức';
    }
    return null;
  }

  String? _validateTaxCode(String? value) {
    if (customerType == 'organization' && (value == null || value.trim().isEmpty)) {
      return 'Vui lòng nhập mã số thuế';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Thêm khách hàng mới', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Hủy', style: TextStyle(color: Colors.black)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _saving 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Thêm khách hàng', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Thông tin cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => gender = 'Anh'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: gender == 'Anh' ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('Anh', textAlign: TextAlign.center, style: TextStyle(color: gender == 'Anh' ? const Color(0xFF16A34A) : Colors.black, fontWeight: FontWeight.w600, fontSize: 14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => gender = 'Chị'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: gender == 'Chị' ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('Chị', textAlign: TextAlign.center, style: TextStyle(color: gender == 'Chị' ? const Color(0xFF16A34A) : Colors.black, fontWeight: FontWeight.w600, fontSize: 14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Họ và tên *',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF16A34A)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            validator: _validateName,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Số điện thoại *',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF16A34A)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF16A34A)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: birthdayController,
                            decoration: InputDecoration(
                              labelText: 'Ngày sinh',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF16A34A)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today, size: 20),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    birthdayController.text = '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                                  }
                                },
                              ),
                            ),
                            keyboardType: TextInputType.datetime,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Địa chỉ',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF16A34A)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: noteController,
                            decoration: InputDecoration(
                              labelText: 'Ghi chú',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF16A34A)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: customerType == 'organization',
                                onChanged: (val) => setState(() => customerType = val == true ? 'organization' : 'individual'),
                              ),
                              const Text('Tổ chức'),
                            ],
                          ),
                          if (customerType == 'organization') ...[
                            const SizedBox(height: 12),
                            const Text('Thông tin tổ chức', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: orgNameController,
                              decoration: InputDecoration(
                                labelText: 'Tên tổ chức *',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF16A34A)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: _validateOrgName,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: taxController,
                              decoration: InputDecoration(
                                labelText: 'Mã số thuế *',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF16A34A)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: _validateTaxCode,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: orgAddressController,
                              decoration: InputDecoration(
                                labelText: 'Địa chỉ tổ chức',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF16A34A)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: invoiceEmailController,
                              decoration: InputDecoration(
                                labelText: 'Email nhận hóa đơn',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF16A34A)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: _validateEmail,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => DesignSystemSnackbar(
        message: message,
        icon: Icons.error,
        onDismissed: () => entry?.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
  }
} 