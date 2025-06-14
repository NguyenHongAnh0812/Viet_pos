import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItemService {
  final _firestore = FirebaseFirestore.instance;
  final String _collection = 'inventory_items';

  Future<void> addItem(Map<String, dynamic> item) async {
    await _firestore.collection(_collection).add(item);
  }

  Stream<List<Map<String, dynamic>>> getItemsBySession(String sessionId) {
    return _firestore
        .collection(_collection)
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(itemId).update(data);
  }
} 