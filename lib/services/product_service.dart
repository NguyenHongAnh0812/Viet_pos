import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  // Thêm sản phẩm mới
  Future<String> addProduct(Product product) async {
    try {
      // Kiểm tra trùng lặp
      if (product.barcode != null) {
        final barcodeQuery = await _firestore
            .collection(_collection)
            .where('barcode', isEqualTo: product.barcode)
            .get();
        if (barcodeQuery.docs.isNotEmpty) {
          throw 'Mã vạch đã tồn tại';
        }
      }

      if (product.sku != null) {
        final skuQuery = await _firestore
            .collection(_collection)
            .where('sku', isEqualTo: product.sku)
            .get();
        if (skuQuery.docs.isNotEmpty) {
          throw 'Mã SKU đã tồn tại';
        }
      }

      final nameQuery = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: product.name)
          .get();
      if (nameQuery.docs.isNotEmpty) {
        throw 'Tên danh pháp đã tồn tại';
      }

      // Thêm sản phẩm mới
      final docRef = await _firestore.collection(_collection).add(product.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Lỗi khi thêm sản phẩm: $e';
    }
  }

  // Lấy danh sách sản phẩm
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Cập nhật sản phẩm
  Future<void> updateProduct(String id, Product product) async {
    try {
      await _firestore.collection(_collection).doc(id).update(product.toMap());
    } catch (e) {
      throw 'Lỗi khi cập nhật sản phẩm: $e';
    }
  }

  // Xóa sản phẩm
  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw 'Lỗi khi xóa sản phẩm: $e';
    }
  }

  // Import từ Excel
  Future<void> importFromExcel(List<Map<String, dynamic>> products) async {
    final batch = _firestore.batch();
    
    for (var product in products) {
      final docRef = _firestore.collection(_collection).doc();
      batch.set(docRef, {
        ...product,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
} 