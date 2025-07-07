import 'package:flutter/material.dart';
import '../../widgets/common/design_system.dart';
import '../../models/product.dart';
import 'edit_product_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final VoidCallback? onBack;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: mainGreen,
        foregroundColor: Colors.white,
        title: Text('Chi tiết sản phẩm', style: h4.copyWith(color: Colors.white)),
      actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EditProductScreen(product: product),
              ),
            ),
            tooltip: 'Sửa sản phẩm',
            ),
          ],
        ),
      body: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Header xanh style
              Container(
                color: mainGreen,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  child: Row(
                    children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text(
                        'Chi tiết sản phẩm',
                        style: h2Mobile.copyWith(color: Colors.white),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    if (isMobile)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditProductScreen(product: product),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information
                        _buildSection(
                          'Thông tin cơ bản',
                          [
                            _buildInfoRow('Tên thương mại', product.tradeName),
                            _buildInfoRow('Tên nội bộ', product.internalName),
                            _buildInfoRow('Mã vạch', product.barcode ?? '-'),
                            _buildInfoRow('SKU', product.sku ?? '-'),
                            _buildInfoRow('Đơn vị tính', product.unit),
                            _buildInfoRow('Số lượng', '${product.stockSystem}'),
                            _buildInfoRow('Giá nhập', formatCurrency(product.costPrice)),
                            _buildInfoRow('Giá bán', formatCurrency(product.salePrice)),
                            _buildInfoRow('Trạng thái', product.status == 'active' ? 'Đang kinh doanh' : 'Ngừng kinh doanh'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Detailed Information
                        _buildSection(
                          'Thông tin chi tiết',
                          [
                            _buildInfoRow('Mô tả', product.description),
                            _buildInfoRow('Công dụng', product.usage),
                            _buildInfoRow('Thành phần', product.ingredients),
                            _buildInfoRow('Chống chỉ định', product.contraindication),
                            _buildInfoRow('Hướng dẫn sử dụng', product.direction),
                            _buildInfoRow('Thời gian ngưng thuốc', product.withdrawalTime),
                            _buildInfoRow('Ghi chú', product.notes),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Tags
                        if (product.tags.isNotEmpty)
                          _buildSection(
                            'Tags',
                            [
                              _buildTagsRow(product.tags),
                            ],
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // System Information
                        _buildSection(
                          'Thông tin hệ thống',
                          [
                            _buildInfoRow('Ngày tạo', _formatDate(product.createdAt)),
                            _buildInfoRow('Ngày cập nhật', _formatDate(product.updatedAt)),
                            _buildInfoRow('Tồn kho hóa đơn', '${product.stockInvoice}'),
                            _buildInfoRow('Lợi nhuận gộp', formatCurrency(product.grossProfit)),
                          ],
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: h3.copyWith(color: mainGreen)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontSize: 14,
              ),
            ),
          ),
                const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow(List<String> tags) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          SizedBox(
            width: 150,
            child: Text(
              'Tags',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                  color: mainGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: mainGreen.withOpacity(0.3)),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: mainGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
