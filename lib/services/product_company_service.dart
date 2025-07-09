import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_company.dart';

class ProductCompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'product_companies';

  // Thêm mối quan hệ Product-Company
  Future<void> addProductCompany(ProductCompany productCompany) async {
    await _firestore.collection(_collection).add(productCompany.toMap());
  }

  // Thêm nhiều mối quan hệ cho một sản phẩm
  Future<void> addProductCompanies(String productId, List<String> companyIds) async {
    final batch = _firestore.batch();
    
    for (int i = 0; i < companyIds.length; i++) {
      final docRef = _firestore.collection(_collection).doc();
      final productCompany = ProductCompany(
        id: docRef.id,
        productId: productId,
        companyId: companyIds[i],
        isPrimary: i == 0, // Công ty đầu tiên là chính
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      batch.set(docRef, productCompany.toMap());
    }
    
    await batch.commit();
  }

  // Cập nhật mối quan hệ Product-Company
  Future<void> updateProductCompany(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Xóa mối quan hệ Product-Company
  Future<void> deleteProductCompany(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Xóa tất cả mối quan hệ của một sản phẩm
  Future<void> deleteProductCompanies(String productId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('product_id', isEqualTo: productId)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Lấy tất cả mối quan hệ của một sản phẩm
  Stream<List<ProductCompany>> getProductCompanies(String productId) {
    return _firestore
        .collection(_collection)
        .where('product_id', isEqualTo: productId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCompany.fromFirestore(doc))
            .toList());
  }

  // Lấy tất cả mối quan hệ của một công ty
  Stream<List<ProductCompany>> getCompanyProducts(String companyId) {
    return _firestore
        .collection(_collection)
        .where('company_id', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCompany.fromFirestore(doc))
            .toList());
  }

  // Lấy danh sách ID công ty của một sản phẩm
  Future<List<String>> getCompanyIdsForProduct(String productId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('product_id', isEqualTo: productId)
        .get();
    
    return querySnapshot.docs
        .map((doc) => doc.data()['company_id'] as String)
        .toList();
  }

  // Lấy danh sách ID sản phẩm của một công ty
  Future<List<String>> getProductIdsForCompany(String companyId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('company_id', isEqualTo: companyId)
        .get();
    
    return querySnapshot.docs
        .map((doc) => doc.data()['product_id'] as String)
        .toList();
  }

  // Cập nhật mối quan hệ cho một sản phẩm
  Future<void> updateProductCompanies(String productId, List<String> companyIds) async {
    // Xóa tất cả mối quan hệ cũ
    await deleteProductCompanies(productId);
    
    // Thêm mối quan hệ mới
    if (companyIds.isNotEmpty) {
      await addProductCompanies(productId, companyIds);
    }
  }
} 