import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company.dart';

class CompanyService {
  final CollectionReference _companiesCollection =
      FirebaseFirestore.instance.collection('companies');

  Stream<List<Company>> getCompanies() {
    return _companiesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Company.fromFirestore(doc)).toList();
    });
  }

  Future<DocumentReference> addCompany(Company company) {
    return _companiesCollection.add(company.toMap());
  }

  Future<void> updateCompany(String id, Map<String, dynamic> data) {
    return _companiesCollection.doc(id).update(data);
  }

  Future<void> deleteCompany(String id) {
    return _companiesCollection.doc(id).delete();
  }

  Future<bool> isTaxCodeUnique(String taxCode, {String? excludeCompanyId}) async {
    if (taxCode.trim().isEmpty) return true;
    
    Query query = _companiesCollection
        .where('taxCode', isEqualTo: taxCode.trim());

    if (excludeCompanyId != null) {
      // This is a workaround for Firestore's limitation on inequality filters on different fields.
      // We fetch all potential matches and then filter in code.
      // For larger datasets, a more complex data model or Cloud Function might be needed.
    }

    final querySnapshot = await query.get();

    if (excludeCompanyId != null) {
      return querySnapshot.docs.where((doc) => doc.id != excludeCompanyId).isEmpty;
    }
    
    return querySnapshot.docs.isEmpty;
  }
} 