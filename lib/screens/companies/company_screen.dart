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
    return Scaffold(
      backgroundColor: appBackground,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        elevation: 8,
        onPressed: () {
          context.findAncestorStateOfType<MainLayoutState>()?.onSidebarTap(MainPage.addCompany);
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: SafeArea(
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
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text('Danh sách nhà cung cấp', style: h2Mobile),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: textPrimary),
                    onPressed: () {
                      // TODO: Hiển thị popup tìm kiếm
                    },
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredCompanies.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.business, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.trim().isEmpty
                                      ? 'Chưa có nhà cung cấp nào'
                                      : 'Không tìm thấy nhà cung cấp phù hợp',
                                  style: bodyMobile,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _filteredCompanies.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final company = _filteredCompanies[index];
                              return GestureDetector(
                                onTap: () => widget.onCompanySelected(company),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(company.name, style: h3Mobile),
                                            const SizedBox(height: 4),
                                            if (company.email != null && company.email!.isNotEmpty)
                                              Text(company.email!, style: smallMobile),
                                            if (company.taxCode != null && company.taxCode!.isNotEmpty)
                                              Text('MST: ${company.taxCode}', style: smallMobile),
                                            if (company.mainContact != null && company.mainContact!.isNotEmpty)
                                              Text('Liên hệ: ${company.mainContact}', style: smallMobile),
                                          ],
                                        ),
                                      ),
                                      DesignSystemBadge(
                                        text: company.status == 'active' || company.status.isEmpty ? 'Hoạt động' : 'Ngừng',
                                        variant: company.status == 'active' || company.status.isEmpty ? BadgeVariant.secondary : BadgeVariant.outline,
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.chevron_right, color: textSecondary, size: 20),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 