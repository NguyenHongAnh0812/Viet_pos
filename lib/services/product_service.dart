import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'product_company_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';
  final ProductCompanyService _productCompanyService = ProductCompanyService();

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
          .where('internalName', isEqualTo: product.internalName)
          .get();
      if (nameQuery.docs.isNotEmpty) {
        throw 'Tên danh pháp đã tồn tại';
      }

      // Thêm sản phẩm mới
      final docRef = await _firestore.collection(_collection).add(Product.normalizeProductData(product.toMap()));
      return docRef.id;
    } catch (e) {
      throw 'Lỗi khi thêm sản phẩm: $e';
    }
  }

  // Lấy danh sách sản phẩm
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .asyncMap((snapshot) async {
      // Tự động fix dữ liệu category_id nếu cần
      await _autoFixCategoryIdData(snapshot.docs);
      
      final products = <Product>[];
      for (final doc in snapshot.docs) {
        try {
          final product = Product.fromMap(doc.id, doc.data());
          products.add(product);
        } catch (e) {
          print('ERROR: Failed to parse product ${doc.id}: $e');
        }
      }
      return products;
    });
  }

  // Hàm tự động fix dữ liệu category_id
  Future<void> _autoFixCategoryIdData(List<QueryDocumentSnapshot> docs) async {
    try {
      int fixedCount = 0;
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Kiểm tra nếu có category_id cũ (String) và chưa có category_ids
        if (data.containsKey('category_id') && !data.containsKey('category_ids')) {
          final oldCategoryId = data['category_id'];
          List<String> newCategoryIds = [];
          
          if (oldCategoryId is String && oldCategoryId.isNotEmpty) {
            newCategoryIds = [oldCategoryId];
          } else if (oldCategoryId is List) {
            newCategoryIds = List<String>.from(oldCategoryId);
          }
          
          print('Migrate document ${doc.id}: category_id "$oldCategoryId" -> category_ids $newCategoryIds');
          
          await _firestore.collection(_collection).doc(doc.id).update({
            'category_ids': newCategoryIds,
            'category_id': FieldValue.delete(), // Xóa trường cũ
          });
          fixedCount++;
        }
        // Kiểm tra nếu category_ids là List<dynamic> thay vì List<String>
        else if (data.containsKey('category_ids') && data['category_ids'] is List) {
          final categoryIds = data['category_ids'] as List;
          if (categoryIds.isNotEmpty && categoryIds.first is! String) {
            final stringCategoryIds = List<String>.from(categoryIds.map((e) => e.toString()));
            print('Fix document ${doc.id}: category_ids $categoryIds -> $stringCategoryIds');
            
            await _firestore.collection(_collection).doc(doc.id).update({
              'category_ids': stringCategoryIds,
            });
            fixedCount++;
          }
        }
      }
      
      if (fixedCount > 0) {
        print('Auto-fixed $fixedCount documents for category_ids migration');
      }
    } catch (e) {
      print('Lỗi khi auto-fix dữ liệu: $e');
    }
  }

  // Cập nhật sản phẩm
  Future<void> updateProduct(String id, Product product) async {
    try {
      await _firestore.collection(_collection).doc(id).update(Product.normalizeProductData(product.toMap()));
    } catch (e) {
      throw 'Lỗi khi cập nhật sản phẩm: $e';
    }
  }

  // Xóa sản phẩm
  Future<void> deleteProduct(String id) async {
    try {
      // Xóa tất cả mối quan hệ Product-Company trước
      await _productCompanyService.deleteProductCompanies(id);
      
      // Sau đó xóa sản phẩm
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
      batch.set(docRef, Product.normalizeProductData(product));
    }

    await batch.commit();
  }

  Future<void> updateProductCategory(String productId, String categoryName) async {
    await _firestore.collection(_collection).doc(productId).update({'category_ids': [categoryName]});
  }

  Future<List<String>> getProductIdsByCategory(String categoryId) async {
    final snapshot = await _firestore
        .collection('product_category')
        .where('category_id', isEqualTo: categoryId)
        .get();
    return snapshot.docs.map((doc) => doc['product_id'] as String).toList();
  }

  Future<List<Product>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot = await _firestore.collection('products').where(FieldPath.documentId, whereIn: ids).get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }
} 