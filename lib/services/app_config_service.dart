import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_config.dart';

class AppConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'app_config';

  // Get the app configuration
  Stream<AppConfig> getConfig() {
    return _firestore
        .collection(_collection)
        .doc('main')
        .snapshots()
        .map((doc) => AppConfig.fromFirestore(doc));
  }

  // Initialize default configuration if not exists
  Future<void> initializeConfig() async {
    final docRef = _firestore.collection(_collection).doc('main');
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'showProductDetails': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update show product details setting
  Future<void> updateShowProductDetails(bool value) async {
    await _firestore.collection(_collection).doc('main').update({
      'showProductDetails': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
} 