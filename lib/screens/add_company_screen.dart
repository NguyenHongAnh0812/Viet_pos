import 'package:flutter/material.dart';
import '../models/company.dart';
import '../services/company_service.dart';
import '../widgets/common/design_system.dart';

class AddCompanyScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AddCompanyScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final CompanyService _companyService = CompanyService();
  bool _isSaving = false;

  // Controllers for text fields
  final _nameController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _hotlineController = TextEditingController();
  final _mainContactController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _paymentTermController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();

  String _status = 'active'; // 'active' hoặc 'inactive'
  List<String> _tags = [];
  bool _isSupplier = true;
  bool _isCustomer = false;

  @override
  void dispose() {
    _nameController.dispose();
    _taxCodeController.dispose();
    _emailController.dispose();
    _hotlineController.dispose();
    _mainContactController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _paymentTermController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: Padding(
        padding: MediaQuery.of(context).size.width < 600 ? const EdgeInsets.symmetric(horizontal: 15) : const EdgeInsets.all(24),
        child: Column(
          children: [
            // Custom header
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: appBackground,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: widget.onBack ?? () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Text('Thêm công ty mới', style: h2),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormSection(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: DesignSystemFormField(label: 'Tên công ty', required: true, input: _buildTextField(_nameController))),
            const SizedBox(width: 24),
            Expanded(child: DesignSystemFormField(
              label: 'Mã số thuế', 
              input: _buildTextField(_taxCodeController)
            )),
          ],
        ),
        const SizedBox(height: 16),
        DesignSystemFormField(label: 'Địa chỉ', input: _buildTextField(_addressController)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: DesignSystemFormField(label: 'Email', input: _buildTextField(_emailController))),
            const SizedBox(width: 24),
            Expanded(child: DesignSystemFormField(label: 'Hotline', input: _buildTextField(_hotlineController))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Expanded(child: DesignSystemFormField(label: 'Website', input: _buildTextField(_websiteController))),
            const SizedBox(width: 24),
            Expanded(child: DesignSystemFormField(label: 'Người liên hệ chính', input: _buildTextField(_mainContactController))),
          ],
        ),
         const SizedBox(height: 16),
         DesignSystemFormField(label: 'Điều khoản thanh toán', input: _buildTextField(_paymentTermController, hint: 'VD: Net 30, Công nợ 30 ngày')),
         const SizedBox(height: 16),
         Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: DesignSystemFormField(label: 'Số tài khoản ngân hàng', input: _buildTextField(_bankAccountController))),
            const SizedBox(width: 24),
            Expanded(child: DesignSystemFormField(label: 'Tên ngân hàng', input: _buildTextField(_bankNameController))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DesignSystemFormField(
                label: 'Trạng thái',
                input: ShopifyDropdown<String>(
                  items: const ['active', 'inactive'],
                  value: _status,
                  getLabel: (s) => (s == 'active' || s.isEmpty) ? 'Đang hoạt động' : 'Ngừng hoạt động',
                  onChanged: (val) {
                    if(val != null) setState(() => _status = val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Phân loại', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary)),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       Checkbox(value: _isSupplier, onChanged: (val) => setState(() => _isSupplier = val ?? false)),
                       const Text('Là nhà cung cấp'),
                       const SizedBox(width: 16),
                       Checkbox(value: _isCustomer, onChanged: (val) => setState(() => _isCustomer = val ?? false)),
                       const Text('Là khách hàng'),
                     ],
                   )
                ],
              )
            )
          ],
        ),
         const SizedBox(height: 16),
         DesignSystemFormField(
           label: 'Tags',
           input: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Wrap(
                 spacing: 8,
                 runSpacing: 8,
                 children: _tags.map((tag) => Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                   decoration: BoxDecoration(
                     color: Colors.transparent,
                     border: Border.all(color: borderColor),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       const Icon(Icons.local_offer_outlined, size: 16, color: textSecondary),
                       const SizedBox(width: 4),
                       Text(tag, style: TextStyle(color: textPrimary)),
                       const SizedBox(width: 4),
                       GestureDetector(
                         onTap: () => setState(() => _tags.remove(tag)),
                         child: const Icon(Icons.close, size: 16, color: textSecondary),
                       ),
                     ],
                   ),
                 )).toList(),
               ),
               const SizedBox(height: 8),
               Row(
                 children: [
                   Expanded(
                     child: TextField(
                       controller: _tagsController,
                       decoration: designSystemInputDecoration(hint: 'Nhập tag và nhấn Enter', fillColor: mutedBackground),
                       onSubmitted: (val) => _addTag(),
                     ),
                   ),
                   const SizedBox(width: 8),
                   ElevatedButton.icon(
                     style: ghostBorderButtonStyle,
                     onPressed: _addTag,
                     icon: const Icon(Icons.add, size: 16),
                     label: const Text('Thêm'),
                   ),
                 ],
               ),
             ],
           ),
         ),
         const SizedBox(height: 16),
         DesignSystemFormField(label: 'Ghi chú', input: _buildTextField(_notesController, maxLines: 4)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1, String? hint, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: designSystemInputDecoration(hint: hint),
      style: const TextStyle(fontSize: 14),
      validator: validator,
    );
  }

  Future<void> _saveCompany() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final isUnique = await _companyService.isTaxCodeUnique(_taxCodeController.text.trim());
        if (!isUnique) {
          if (mounted) {
            OverlayEntry? entry;
            entry = OverlayEntry(
              builder: (_) => DesignSystemSnackbar(
                message: 'Mã số thuế đã tồn tại trong hệ thống!',
                icon: Icons.error,
                onDismissed: () => entry?.remove(),
              ),
            );
            Overlay.of(context).insert(entry);
          }
          setState(() => _isSaving = false);
          return;
        }

        final newCompany = Company(
          id: '', // Firestore will generate
          name: _nameController.text.trim(),
          taxCode: _taxCodeController.text.trim(),
          address: _addressController.text.trim(),
          hotline: _hotlineController.text.trim(),
          email: _emailController.text.trim(),
          website: _websiteController.text.trim(),
          mainContact: _mainContactController.text.trim(),
          bankAccount: _bankAccountController.text.trim(),
          bankName: _bankNameController.text.trim(),
          paymentTerm: _paymentTermController.text.trim(),
          status: _status,
          tags: _tags,
          note: _notesController.text.trim(),
          isSupplier: _isSupplier,
          isCustomer: _isCustomer,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _companyService.addCompany(newCompany);

        if (mounted) {
          OverlayEntry? entry;
          entry = OverlayEntry(
            builder: (_) => DesignSystemSnackbar(
              message: 'Đã thêm công ty thành công!',
              icon: Icons.check_circle,
              onDismissed: () => entry?.remove(),
            ),
          );
          Overlay.of(context).insert(entry);
          widget.onBack?.call();
        }
      } catch (e) {
        if (mounted) {
           OverlayEntry? entry;
          entry = OverlayEntry(
            builder: (_) => DesignSystemSnackbar(
              message: 'Lỗi khi thêm công ty: $e',
              icon: Icons.error,
              onDismissed: () => entry?.remove(),
            ),
          );
          Overlay.of(context).insert(entry);
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  void _fillWithSampleData() {
    setState(() {
      _nameController.text = 'Công ty Dược phẩm Pharmacity';
      _taxCodeController.text = '0311602955';
      _emailController.text = 'cskh@pharmacity.vn';
      _hotlineController.text = '028 3838 3838';
      _mainContactController.text = 'Lê Nguyễn Nhật Tường';
      _addressController.text = '248A Nơ Trang Long, P. 12, Q. Bình Thạnh, TP. HCM';
      _websiteController.text = 'https://www.pharmacity.vn';
      _status = 'active';
      _paymentTermController.text = 'Thanh toán ngay';
      _bankAccountController.text = '060199998888';
      _bankNameController.text = 'Sacombank';
      _notesController.text = 'Đối tác lớn, ưu tiên giao hàng.';
      _tags = ['Tag1', 'Tag2'];
      _isSupplier = true;
      _isCustomer = false;
    });
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _fillWithSampleData,
          style: ghostBorderButtonStyle,
          child: const Text('Dữ liệu mẫu'),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          style: ghostBorderButtonStyle,
          child: const Text('Hủy'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveCompany,
          style: primaryButtonStyle,
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Thêm công ty'),
        ),
      ],
    );
  }
} 