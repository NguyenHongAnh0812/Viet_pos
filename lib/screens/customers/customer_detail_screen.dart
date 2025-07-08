import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../../widgets/common/design_system.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  final VoidCallback? onSuccess;
  const CustomerDetailScreen({super.key, required this.customerId, this.onSuccess});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _noteController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _orgAddressController = TextEditingController();
  final _invoiceEmailController = TextEditingController();
  String? _gender;
  String? _companyId;
  bool _isSupplier = false;
  double? _discount;
  double? _priceAdjust;
  bool _saving = false;
  bool _loading = true;
  String? _customerType; // 'individual' hoặc 'organization'

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final customer = await CustomerService().getCustomerById(widget.customerId);
    if (customer != null) {
      _gender = customer.gender;
      _companyId = customer.companyId;
      _discount = customer.discount;
      _customerType = customer.customerType ?? 'individual';
      
      print('DEBUG: Customer type = $_customerType');
      print('DEBUG: Customer name = ${customer.name}');
      print('DEBUG: Customer address = ${customer.address}');
      
      // Load dữ liệu theo loại khách hàng
      if (customer.customerType == 'organization') {
        // Tổ chức - load vào các field tổ chức
        _orgNameController.text = customer.name ?? '';
        _orgAddressController.text = customer.address ?? '';
        _invoiceEmailController.text = customer.email ?? '';
        _taxCodeController.text = customer.taxCode ?? '';
        // Để trống các field cá nhân
        _nameController.clear();
        _phoneController.text = customer.phone ?? '';
        _emailController.clear();
        _addressController.clear();
        print('DEBUG: Loaded organization data');
      } else {
        // Cá nhân - load vào các field cá nhân
        _nameController.text = customer.name ?? '';
        _phoneController.text = customer.phone ?? '';
        _emailController.text = customer.email ?? '';
        _addressController.text = customer.address ?? '';
        _taxCodeController.text = customer.taxCode ?? '';
        // Để trống các field tổ chức
        _orgNameController.clear();
        _orgAddressController.clear();
        _invoiceEmailController.clear();
        print('DEBUG: Loaded individual data');
      }
      
      // Các field chung
      _birthdayController.text = customer.birthday ?? '';
      _noteController.text = customer.note ?? '';
      
      // TODO: fill _isSupplier, _priceAdjust nếu có
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taxCodeController.dispose();
    _birthdayController.dispose();
    _noteController.dispose();
    _orgNameController.dispose();
    _orgAddressController.dispose();
    _invoiceEmailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _customerType == 'organization' ? _orgNameController.text.trim() : _nameController.text.trim(),
        'gender': _gender,
        'phone': _phoneController.text.trim(),
        'email': _customerType == 'organization' ? _invoiceEmailController.text.trim() : _emailController.text.trim(),
        'address': _customerType == 'organization' ? _orgAddressController.text.trim() : _addressController.text.trim(),
        'discount': _discount,
        'tax_code': _customerType == 'organization' ? _taxCodeController.text.trim() : (_taxCodeController.text.trim().isNotEmpty ? _taxCodeController.text.trim() : null),
        'company_id': _companyId,
        'birthday': _birthdayController.text.trim().isNotEmpty ? _birthdayController.text.trim() : null,
        'note': _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        'customer_type': _customerType,
      };
      await CustomerService().updateCustomer(widget.customerId, data);
      if (mounted) {
        OverlayEntry? entry;
        entry = OverlayEntry(
          builder: (_) => DesignSystemSnackbar(
            message: 'Đã cập nhật khách hàng thành công',
            icon: Icons.check_circle,
            onDismissed: () => entry?.remove(),
          ),
        );
        Overlay.of(context).insert(entry);
        await Future.delayed(const Duration(milliseconds: 600));
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        OverlayEntry? entry;
        entry = OverlayEntry(
          builder: (_) => DesignSystemSnackbar(
            message: 'Lỗi: $e',
            icon: Icons.error,
            onDismissed: () => entry?.remove(),
          ),
        );
        Overlay.of(context).insert(entry);
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    print('DEBUG UI: _customerType = $_customerType');
    print('DEBUG UI: _orgNameController.text = ${_orgNameController.text}');
    print('DEBUG UI: _nameController.text = ${_nameController.text}');
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chỉnh sửa khách hàng', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                                  onTap: () => setState(() => _gender = 'Anh'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _gender == 'Anh' ? const Color(0xFF16A34A) : Colors.white,
                                      border: Border.all(color: _gender == 'Anh' ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Anh', textAlign: TextAlign.center, style: TextStyle(color: _gender == 'Anh' ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _gender = 'Chị'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _gender == 'Chị' ? const Color(0xFF16A34A) : Colors.white,
                                      border: Border.all(color: _gender == 'Chị' ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Chị', textAlign: TextAlign.center, style: TextStyle(color: _gender == 'Chị' ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: _customerType == 'organization' ? 'Tên người đại diện' : 'Họ và tên *'
                            ),
                            validator: (value) {
                              if (_customerType != 'organization' && (value == null || value.trim().isEmpty)) {
                                return 'Vui lòng nhập họ và tên';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(labelText: 'Số điện thoại *'),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập số điện thoại';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _birthdayController,
                            decoration: InputDecoration(
                              labelText: 'Ngày sinh',
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
                                    _birthdayController.text = '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                                  }
                                },
                              ),
                            ),
                            keyboardType: TextInputType.datetime,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(labelText: 'Địa chỉ'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _noteController,
                            decoration: const InputDecoration(labelText: 'Ghi chú'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: _customerType == 'organization',
                                onChanged: (val) => setState(() => _customerType = val == true ? 'organization' : 'individual'),
                              ),
                              const Text('Tổ chức'),
                            ],
                          ),
                          if (_customerType == 'organization') ...[
                            const SizedBox(height: 12),
                            const Text('Thông tin tổ chức', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _orgNameController,
                              decoration: const InputDecoration(labelText: 'Tên tổ chức *'),
                              validator: (value) {
                                if (_customerType == 'organization' && (value == null || value.trim().isEmpty)) {
                                  return 'Vui lòng nhập tên tổ chức';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _taxCodeController,
                              decoration: const InputDecoration(labelText: 'Mã số thuế *'),
                              validator: (value) {
                                if (_customerType == 'organization' && (value == null || value.trim().isEmpty)) {
                                  return 'Vui lòng nhập mã số thuế';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _orgAddressController,
                              decoration: const InputDecoration(labelText: 'Địa chỉ tổ chức'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _invoiceEmailController,
                              decoration: const InputDecoration(labelText: 'Email nhận hóa đơn'),
                              validator: _validateEmail,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
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
                              : const Text('Cập nhật khách hàng', style: TextStyle(color: Colors.white)),
                          ),
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
    );
  }
} 