import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_session.dart';

class InventoryService {
  final _firestore = FirebaseFirestore.instance;
  final String _collection = 'inventory_sessions';

  Future<void> addSession(InventorySession session) async {
    await _firestore.collection(_collection).add(session.toMap());
  }

  Stream<List<InventorySession>> getSessionsByMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _firestore
        .collection(_collection)
        .where('created_at', isGreaterThanOrEqualTo: start)
        .where('created_at', isLessThan: end)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => InventorySession.fromFirestore(doc)).toList());
  }

  Future<InventorySession?> getLastSession() async {
    final snap = await _firestore.collection(_collection).orderBy('created_at', descending: true).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return InventorySession.fromFirestore(snap.docs.first);
  }

  Stream<List<InventorySession>> getAllSessions() {
    return _firestore
        .collection(_collection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => InventorySession.fromFirestore(doc)).toList());
  }
} 