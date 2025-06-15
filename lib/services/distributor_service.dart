import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/distributor.dart';

class DistributorService {
  final _collection = FirebaseFirestore.instance.collection('distributors');

  Stream<List<Distributor>> getDistributors() {
    return _collection.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Distributor.fromMap(doc.id, doc.data())).toList()
    );
  }

  Future<void> addDistributor(Distributor distributor) async {
    await _collection.add(distributor.toMap());
  }

  Future<void> updateDistributor(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  Future<void> deleteDistributor(String id) async {
    await _collection.doc(id).delete();
  }
} 