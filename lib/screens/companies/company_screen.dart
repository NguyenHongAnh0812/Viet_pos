import 'package:flutter/material.dart';
import '../../models/company.dart';
import '../../services/company_service.dart';
import '../../widgets/common/design_system.dart';
import '../../widgets/main_layout.dart';

class CompanyScreen extends StatefulWidget {
  final Function(Company) onCompanySelected;
  const CompanyScreen({Key? key, required this.onCompanySelected})
      : super(key: key);

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

const TextStyle tableHeaderStyle =
    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6C757D));

class _CompanyScreenState extends State<CompanyScreen> {
  final CompanyService _service = CompanyService();
  final TextEditingController _searchController = TextEditingController();
  List<Company> _allCompanies = [];
  List<Company> _filteredCompanies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCompanies() {
    _service.getCompanies().listen((companies) {
      if (mounted) {
        setState(() {
          _allCompanies = companies;
          _filteredCompanies = companies;
          _isLoading = false;
        });
      }
    });
  }

  void _filterCompanies(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredCompanies = _allCompanies;
      });
            } else {
      final lowercaseQuery = query.toLowerCase();
      setState(() {
        _filteredCompanies = _allCompanies.where((company) {
          return company.name.toLowerCase().contains(lowercaseQuery) ||
              (company.taxCode?.toLowerCase().contains(lowercaseQuery) ?? false) ||
              (company.email?.toLowerCase().contains(lowercaseQuery) ?? false);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Text('Danh sách công ty', style: h2),
                ElevatedButton.icon(
                onPressed: () {
                  context
                      .findAncestorStateOfType<MainLayoutState>()
                      ?.onSidebarTap(MainPage.addCompany);
                },
                  icon: const Icon(Icons.add),
                label: const Text('Thêm công ty'),
                  style: primaryButtonStyle,
                ),
              ],
            ),
            const SizedBox(height: 24),

          // Search bar
          SizedBox(
            width: 400,
            child: TextField(
              controller: _searchController,
              onChanged: _filterCompanies,
              decoration: searchInputDecoration(
                  hint: 'Tìm kiếm theo tên, mã số thuế, email...'),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),

          // Company List
            Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFE0E0E0), width: 1.5)),
                    ),
                    child: const Row(
                          children: [
                        Expanded(
                            flex: 3,
                            child: Text('Tên công ty', style: tableHeaderStyle)),
                        SizedBox(width: 16),
                        Expanded(
                            flex: 2,
                            child: Text('Mã số thuế', style: tableHeaderStyle)),
                        SizedBox(width: 16),
                        Expanded(
                            flex: 2,
                            child: Text('Email', style: tableHeaderStyle)),
                        SizedBox(width: 16),
                        Expanded(
                            flex: 2,
                            child: Text('Người liên hệ chính',
                                style: tableHeaderStyle)),
                        SizedBox(width: 16),
                        Expanded(
                            flex: 2,
                            child: Text('Website', style: tableHeaderStyle)),
                        SizedBox(width: 16),
                        Expanded(
                            flex: 2,
                            child: Text('Trạng thái', style: tableHeaderStyle)),
                          ],
                        ),
                  ),
                  // Table Body
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredCompanies.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                                    Icon(Icons.business,
                                        size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.trim().isEmpty
                                          ? 'Chưa có công ty nào'
                                          : 'Không tìm thấy công ty phù hợp',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredCompanies.length,
                                itemBuilder: (context, index) {
                                  final company = _filteredCompanies[index];
                                  return _buildCompanyRow(company);
                              },
                              ),
                  ),
                ],
              ),
            ),
                            ),
                          ],
                        ),
                      );
  }

  Widget _buildCompanyRow(Company company) {
    final bool isActive = company.status == 'active' || company.status.isEmpty;
    final statusColor =
        isActive ? const Color(0xFF28A745) : const Color(0xFF6C757D);
    final statusBgColor = isActive
        ? const Color(0xFF28A745).withOpacity(0.1)
        : const Color(0xFF6C757D).withOpacity(0.1);

    return InkWell(
      onTap: () => widget.onCompanySelected(company),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
                flex: 3,
                child: Text(company.name,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF212529)))),
            const SizedBox(width: 16),
            Expanded(
                flex: 2,
                child: Text(company.taxCode ?? '',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF212529)))),
            const SizedBox(width: 16),
            Expanded(
                flex: 2,
                child: Text(company.email ?? '',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF212529)))),
            const SizedBox(width: 16),
            Expanded(
                flex: 2,
                child: Text(company.mainContact ?? '',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF212529)))),
            const SizedBox(width: 16),
            Expanded(
                flex: 2,
                child: Text(company.website ?? '',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF007BFF)))),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    (company.status == 'active' || company.status.isEmpty) ? 'Đang hoạt động' : 'Ngừng hoạt động',
                    style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 