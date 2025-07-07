import 'package:flutter/material.dart';
import '../../models/company.dart';
import '../../services/company_service.dart';
import '../../widgets/common/design_system.dart';

class CompanyDetailScreen extends StatefulWidget {
  final Company company;
  final VoidCallback onBack;
  const CompanyDetailScreen({Key? key, required this.company, required this.onBack})
      : super(key: key);

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyService = CompanyService();
  bool _isSaving = false;

  // Controllers for text fields
  late TextEditingController _nameController;
  late TextEditingController _taxCodeController;
  late TextEditingController _emailController;
  late TextEditingController _hotlineController;
  late TextEditingController _mainContactController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _paymentTermController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankNameController;
  late TextEditingController _notesController;
  final _tagsController = TextEditingController();

  late String _status;
  late List<String> _tags;
  late bool _isSupplier;
  late bool _isCustomer;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company.name);
    _taxCodeController = TextEditingController(text: widget.company.taxCode);
    _emailController = TextEditingController(text: widget.company.email);
    _hotlineController = TextEditingController(text: widget.company.hotline);
    _mainContactController = TextEditingController(text: widget.company.mainContact);
    _addressController = TextEditingController(text: widget.company.address);
    _websiteController = TextEditingController(text: widget.company.website);
    _paymentTermController = TextEditingController(text: widget.company.paymentTerm);
    _bankAccountController = TextEditingController(text: widget.company.bankAccount);
    _bankNameController = TextEditingController(text: widget.company.bankName);
    _notesController = TextEditingController(text: widget.company.note);
    _status = widget.company.status;
    _tags = List<String>.from(widget.company.tags);
    _isSupplier = widget.company.isSupplier;
    _isCustomer = widget.company.isCustomer;
  }

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

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final newTaxCode = _taxCodeController.text.trim();
        if (newTaxCode.isNotEmpty && newTaxCode != widget.company.taxCode) {
          final isUnique = await _companyService.isTaxCodeUnique(
            newTaxCode,
            excludeCompanyId: widget.company.id,
          );
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
        }

        final updatedCompany = widget.company.copyWith(
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
          updatedAt: DateTime.now(),
        );

        await _companyService.updateCompany(widget.company.id, updatedCompany.toMap());

        if (mounted) {
          OverlayEntry? entry;
          entry = OverlayEntry(
            builder: (_) => DesignSystemSnackbar(
              message: 'Đã cập nhật công ty thành công!',
              icon: Icons.check_circle,
              onDismissed: () => entry?.remove(),
            ),
          );
          Overlay.of(context).insert(entry);
          widget.onBack();
        }
      } catch (e) {
        if (mounted) {
          OverlayEntry? entry;
          entry = OverlayEntry(
            builder: (_) => DesignSystemSnackbar(
              message: 'Lỗi khi cập nhật công ty: $e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
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
                      onPressed: widget.onBack,
                    ),
                    Expanded(
                      child: Text('Chi tiết nhà cung cấp', style: h2Mobile),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: borderColor,
              ),
              // Body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thông tin nhà cung cấp', style: h3Mobile),
                        const SizedBox(height: 16),
                        _buildField('Tên nhà cung cấp', _nameController, true),
                        _buildField('Mã số thuế', _taxCodeController, false),
                        _buildField('Email', _emailController, false),
                        _buildField('Hotline', _hotlineController, false),
                        _buildField('Liên hệ chính', _mainContactController, false),
                        _buildField('Địa chỉ', _addressController, false),
                        _buildStatusField(),
                        _buildField('Ghi chú', _notesController, false, maxLines: 2),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveChanges,
                            style: primaryButtonStyle,
                            child: _isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Lưu thay đổi'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, bool required, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: labelMedium.copyWith(fontWeight: FontWeight.w600)),
              if (required) ...[
                const SizedBox(width: 2),
                const Text('*', style: TextStyle(color: destructiveRed, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            style: bodyMobile,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: appBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: mainGreen, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            validator: required
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập $label';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trạng thái', style: labelMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _status,
            items: const [
              DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
              DropdownMenuItem(value: 'inactive', child: Text('Ngừng hoạt động')),
            ],
            onChanged: (v) => setState(() => _status = v ?? 'active'),
            decoration: InputDecoration(
              filled: true,
              fillColor: appBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: mainGreen, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }
} 