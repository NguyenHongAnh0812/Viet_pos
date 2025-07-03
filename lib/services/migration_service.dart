import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/company.dart';
import 'product_company_service.dart';
import 'company_service.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductCompanyService _productCompanyService = ProductCompanyService();
  final CompanyService _companyService = CompanyService();

  // Kiểm tra xem có cần migration không
  Future<bool> needsMigration() async {
    final snapshot = await _firestore
        .collection('products')
        .where('company', isNull: false)
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }

  // Thực hiện migration
  Future<MigrationResult> migrateCompanyData() async {
    try {
      final startTime = DateTime.now();
      int migratedCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      // Lấy tất cả sản phẩm có trường company
      final productsSnapshot = await _firestore
          .collection('products')
          .where('company', isNull: false)
          .get();

      // Lấy danh sách tất cả companies để tìm ID
      final companies = await _companyService.getCompanies().first;
      final companyNameToId = <String, String>{};
      for (final company in companies) {
        companyNameToId[company.name.toLowerCase()] = company.id;
      }

      for (final doc in productsSnapshot.docs) {
        try {
          final data = doc.data();
          final companyName = data['company'] as String?;
          
          if (companyName != null && companyName.isNotEmpty) {
            // Tìm company ID từ tên
            final companyId = companyNameToId[companyName.toLowerCase()];
            
            if (companyId != null) {
              // Tạo mối quan hệ trong bảng trung gian
              await _productCompanyService.addProductCompanies(doc.id, [companyId]);
              migratedCount++;
            } else {
              // Tạo company mới nếu không tìm thấy
              final newCompany = Company(
                id: '',
                name: companyName,
                address: '',
                hotline: '',
                email: '',
                taxCode: '',
                isSupplier: true,
                isCustomer: false,
                note: 'Tự động tạo từ migration',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              final docRef = await _companyService.addCompany(newCompany);
              await _productCompanyService.addProductCompanies(doc.id, [docRef.id]);
              migratedCount++;
            }
          }
        } catch (e) {
          errorCount++;
          errors.add('Product ${doc.id}: $e');
        }
      }

      // Xóa trường company cũ sau khi migration thành công
      if (migratedCount > 0) {
        final batch = _firestore.batch();
        for (final doc in productsSnapshot.docs) {
          batch.update(doc.reference, {'company': FieldValue.delete()});
        }
        await batch.commit();
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      return MigrationResult(
        success: true,
        migratedCount: migratedCount,
        errorCount: errorCount,
        errors: errors,
        duration: duration,
      );
    } catch (e) {
      return MigrationResult(
        success: false,
        migratedCount: 0,
        errorCount: 1,
        errors: ['Migration failed: $e'],
        duration: Duration.zero,
      );
    }
  }

  // Kiểm tra trạng thái migration
  Future<MigrationStatus> getMigrationStatus() async {
    final needsMigration = await this.needsMigration();
    final hasProductCompanyData = await _hasProductCompanyData();
    
    return MigrationStatus(
      needsMigration: needsMigration,
      hasProductCompanyData: hasProductCompanyData,
      isComplete: !needsMigration && hasProductCompanyData,
    );
  }

  // Kiểm tra xem có dữ liệu trong bảng product_company không
  Future<bool> _hasProductCompanyData() async {
    final snapshot = await _firestore
        .collection('product_companies')
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }
}

class MigrationResult {
  final bool success;
  final int migratedCount;
  final int errorCount;
  final List<String> errors;
  final Duration duration;

  MigrationResult({
    required this.success,
    required this.migratedCount,
    required this.errorCount,
    required this.errors,
    required this.duration,
  });
}

class MigrationStatus {
  final bool needsMigration;
  final bool hasProductCompanyData;
  final bool isComplete;

  MigrationStatus({
    required this.needsMigration,
    required this.hasProductCompanyData,
    required this.isComplete,
  });
} 