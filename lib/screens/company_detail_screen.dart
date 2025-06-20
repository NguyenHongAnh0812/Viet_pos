import 'package:flutter/material.dart';
import '../models/company.dart';
import '../services/company_service.dart';
import '../widgets/common/design_system.dart';

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
  late TextEditingController _contactPersonController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _paymentTermController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankNameController;
  late TextEditingController _notesController;
  final _tagsController = TextEditingController();

  late String _status;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company.name);
    _taxCodeController = TextEditingController(text: widget.company.taxCode);
    _emailController = TextEditingController(text: widget.company.email);
    _contactPersonController = TextEditingController(text: widget.company.contactPerson);
    _addressController = TextEditingController(text: widget.company.address);
    _websiteController = TextEditingController(text: widget.company.website);
    _paymentTermController = TextEditingController(text: widget.company.paymentTerm);
    _bankAccountController = TextEditingController(text: widget.company.bankAccountNumber);
    _bankNameController = TextEditingController(text: widget.company.bankName);
    _notesController = TextEditingController(text: widget.company.notes);
    _status = widget.company.status;
    _tags = List<String>.from(widget.company.tags);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxCodeController.dispose();
    _emailController.dispose();
    _contactPersonController.dispose();
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
        if (newTaxCode != widget.company.taxCode) {
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

        final updatedData = {
          'name': _nameController.text,
          'taxCode': _taxCodeController.text,
          'email': _emailController.text,
          'address': _addressController.text,
          'contactPerson': _contactPersonController.text,
          'website': _websiteController.text,
          'paymentTerm': _paymentTermController.text,
          'bankAccountNumber': _bankAccountController.text,
          'bankName': _bankNameController.text,
          'notes': _notesController.text,
          'status': _status,
          'tags': _tags,
        };

        await _companyService.updateCompany(widget.company.id, updatedData);

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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildCompanyInfoForm(),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 1,
                  child: _buildLinkedContacts(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nameController.text, style: h1),
                if (_taxCodeController.text.isNotEmpty)
                  Text(_taxCodeController.text, style: body.copyWith(color: textSecondary)),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveChanges,
          icon: _isSaving 
              ? Container(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_outlined, size: 18),
          label: const Text('Lưu thay đổi'),
          style: primaryButtonStyle,
        )
      ],
    );
  }

  Widget _buildCompanyInfoForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thông tin công ty', style: h3),
            const SizedBox(height: 24),
            _buildEditableField('Tên công ty', _nameController),
            _buildEditableField('Mã số thuế', _taxCodeController),
            _buildEditableField('Email', _emailController),
            _buildEditableField('Địa chỉ', _addressController),
            _buildEditableField('Người liên hệ chính', _contactPersonController),
            _buildEditableField('Website', _websiteController),
            _buildEditableField('Số tài khoản ngân hàng', _bankAccountController),
            _buildEditableField('Tên ngân hàng', _bankNameController),
            _buildEditableField('Điều khoản thanh toán', _paymentTermController),
            _buildStatusDropdown(),
            _buildTagsSection(),
            _buildEditableField('Ghi chú', _notesController, maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {int? maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelLarge.copyWith(color: textThird)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: designSystemInputDecoration(hint: ''),
            style: body,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trạng thái', style: labelLarge.copyWith(color: textThird)),
          const SizedBox(height: 8),
          ShopifyDropdown<String>(
            items: const ['Hoạt động', 'Ngừng hoạt động'],
            value: _status,
            getLabel: (s) => s,
            onChanged: (val) {
              if (val != null) setState(() => _status = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tags', style: labelLarge.copyWith(color: textThird)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
              label: Text(tag),
              onDeleted: () {
                setState(() => _tags.remove(tag));
              },
              deleteIcon: const Icon(Icons.close, size: 16),
            )).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagsController,
                  decoration: designSystemInputDecoration(hint: 'Thêm tag...'),
                  onSubmitted: (val) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addTag,
                style: iconButtonStyle.copyWith(
                  backgroundColor: MaterialStateProperty.all(primaryBlue),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedContacts() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Khách hàng liên kết', style: h3),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tên', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('SĐT', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          // Sample Data
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nguyễn Văn A'),
              Text('0901234567'),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trần Thị B'),
              Text('0987654321'),
            ],
          )
        ],
      ),
    );
  }
} 