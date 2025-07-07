import 'package:flutter/material.dart';
import '../services/migration_service.dart';
import '../widgets/common/design_system.dart';

class MigrationScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MigrationScreen({super.key, this.onBack});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  final MigrationService _migrationService = MigrationService();
  MigrationStatus? _status;
  MigrationResult? _result;
  bool _isLoading = false;
  bool _isMigrating = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await _migrationService.getMigrationStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi kiểm tra trạng thái: $e')),
        );
      }
    }
  }

  Future<void> _runMigration() async {
    setState(() => _isMigrating = true);
    try {
      final result = await _migrationService.migrateCompanyData();
      if (mounted) {
        setState(() {
          _result = result;
          _isMigrating = false;
        });
        
        // Reload status after migration
        await _loadStatus();
        
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Migration thành công! Đã chuyển đổi ${result.migratedCount} sản phẩm.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Migration thất bại: ${result.errors.first}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isMigrating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thực hiện migration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 1400),
              padding: const EdgeInsets.only(top: 0, left: 16, right: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Text(
                        'Migration Dữ Liệu',
                        style: MediaQuery.of(context).size.width < 600 ? h1Mobile : h2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                designSystemCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: mainGreen),
                          const SizedBox(width: 8),
                          Text('Thông tin Migration', style: h3),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Migration này sẽ chuyển đổi dữ liệu từ trường "company" cũ trong bảng products sang bảng trung gian "product_companies" để hỗ trợ mối quan hệ many-to-many giữa Product và Company.',
                        style: bodyLarge.copyWith(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                if (_isLoading)
                  designSystemCard(
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (_status != null)
                  designSystemCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trạng thái hiện tại', style: h3),
                        const SizedBox(height: 16),
                        _buildStatusItem(
                          'Cần migration',
                          _status!.needsMigration ? 'Có' : 'Không',
                          Icons.warning,
                          Colors.orange,
                        ),
                        _buildStatusItem(
                          'Có dữ liệu product_companies',
                          _status!.hasProductCompanyData ? 'Có' : 'Không',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildStatusItem(
                          'Migration hoàn tất',
                          _status!.isComplete ? 'Có' : 'Không',
                          Icons.done_all,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                if (_status != null && _status!.needsMigration)
                  designSystemCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thực hiện Migration', style: h3),
                        const SizedBox(height: 16),
                        Text(
                          'Nhấn nút bên dưới để bắt đầu quá trình migration. Quá trình này sẽ:',
                          style: bodyLarge.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 8),
                        _buildMigrationStep('1. Tìm tất cả sản phẩm có trường "company"'),
                        _buildMigrationStep('2. Tạo mối quan hệ trong bảng "product_companies"'),
                        _buildMigrationStep('3. Tạo company mới nếu chưa tồn tại'),
                        _buildMigrationStep('4. Xóa trường "company" cũ'),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isMigrating ? null : _runMigration,
                            icon: _isMigrating 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync, size: 24),
                            label: Text(_isMigrating ? 'Đang migration...' : 'Bắt đầu Migration'),
                            style: primaryButtonStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  designSystemCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kết quả Migration', style: h3),
                        const SizedBox(height: 16),
                        _buildResultItem(
                          'Thành công',
                          _result!.success ? 'Thành công' : 'Thất bại',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildResultItem(
                          'Số sản phẩm đã migration',
                          '${_result!.migratedCount}',
                          Icons.inventory,
                          Colors.blue,
                        ),
                        _buildResultItem(
                          'Số lỗi',
                          '${_result!.errorCount}',
                          Icons.error,
                          _result!.errorCount > 0 ? Colors.red : Colors.green,
                        ),
                        _buildResultItem(
                          'Thời gian thực hiện',
                          '${_result!.duration.inMilliseconds}ms',
                          Icons.timer,
                          Colors.orange,
                        ),
                        if (_result!.errors.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Chi tiết lỗi:', style: bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ..._result!.errors.map((error) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $error', style: body.copyWith(color: Colors.red)),
                          )),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, dynamic value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: bodyLarge),
          ),
          Text(
            value is bool ? (value ? 'Có' : 'Không') : value.toString(),
            style: bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: value is bool ? (value ? Colors.green : Colors.red) : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMigrationStep(String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.arrow_right, color: textSecondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(step, style: body.copyWith(color: textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: bodyLarge),
          ),
          Text(
            value,
            style: bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 