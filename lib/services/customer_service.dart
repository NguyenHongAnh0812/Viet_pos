import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';

class CustomerService {
  final _collection = FirebaseFirestore.instance.collection('customers');

  Stream<List<Customer>> getCustomers() {
    return _collection.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList()
    );
  }

  Future<Customer?> getCustomerById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Customer.fromFirestore(doc);
  }

  Future<void> addCustomer(Customer customer) async {
    await _collection.add(customer.toMap());
  }

  Future<DocumentReference> addCustomerAndGetId(Customer customer) async {
    final docRef = await _collection.add(customer.toMap());
    return docRef;
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  Future<void> deleteCustomer(String id) async {
    await _collection.doc(id).delete();
  }

  // Tạo dữ liệu demo cho testing
  Future<void> createDemoData() async {
    final demoCustomers = [
      {
        'name': 'Nguyễn Văn An',
        'gender': 'Nam',
        'phone': '0901234567',
        'email': 'nguyenvanan@gmail.com',
        'address': '123 Đường ABC, Quận 1, TP.HCM',
        'discount': 5.0,
        'tax_code': '0123456789',
        'tags': ['VIP', 'Thường xuyên'],
        'company_id': null,
        'birthday': '15/03/1985',
        'note': 'Khách hàng VIP, thường xuyên mua hàng',
        'customer_type': 'individual',
      },
      {
        'name': 'Trần Thị Bình',
        'gender': 'Nữ',
        'phone': '0912345678',
        'email': 'tranthibinh@yahoo.com',
        'address': '456 Đường XYZ, Quận 3, TP.HCM',
        'discount': 10.0,
        'tax_code': '0987654321',
        'tags': ['VIP'],
        'company_id': null,
        'birthday': '22/07/1990',
        'note': 'Khách hàng VIP, ưu tiên chiết khấu cao',
        'customer_type': 'individual',
      },
      {
        'name': 'Lê Văn Cường',
        'gender': 'Nam',
        'phone': '0923456789',
        'email': 'levancuong@gmail.com',
        'address': '789 Đường DEF, Quận 7, TP.HCM',
        'discount': 0.0,
        'tax_code': null,
        'tags': ['Mới'],
        'company_id': null,
        'birthday': '08/12/1995',
        'note': 'Khách hàng mới, cần tư vấn thêm',
        'customer_type': 'individual',
      },
      {
        'name': 'Phạm Thị Dung',
        'gender': 'Nữ',
        'phone': '0934567890',
        'email': 'phamthidung@gmail.com',
        'address': '321 Đường GHI, Quận 2, TP.HCM',
        'discount': 15.0,
        'tax_code': '1122334455',
        'tags': ['VIP', 'Doanh nghiệp'],
        'company_id': 'company_001',
        'birthday': '30/01/1988',
        'note': 'Khách hàng doanh nghiệp, chiết khấu cao',
        'customer_type': 'organization',
      },
      {
        'name': 'Hoàng Văn Em',
        'gender': 'Nam',
        'phone': '0945678901',
        'email': 'hoangvanem@hotmail.com',
        'address': '654 Đường JKL, Quận 5, TP.HCM',
        'discount': 8.0,
        'tax_code': null,
        'tags': ['Thường xuyên'],
        'company_id': null,
        'birthday': '14/09/1982',
        'note': 'Khách hàng thường xuyên, ổn định',
        'customer_type': 'individual',
      },
      {
        'name': 'Vũ Thị Phương',
        'gender': 'Nữ',
        'phone': '0956789012',
        'email': 'vuthiphuong@gmail.com',
        'address': '987 Đường MNO, Quận 10, TP.HCM',
        'discount': 12.0,
        'tax_code': '5566778899',
        'tags': ['VIP', 'Doanh nghiệp'],
        'company_id': 'company_002',
        'birthday': '25/11/1987',
        'note': 'Khách hàng VIP doanh nghiệp',
        'customer_type': 'organization',
      },
      {
        'name': 'Đặng Văn Giang',
        'gender': 'Nam',
        'phone': '0967890123',
        'email': 'dangvangiang@gmail.com',
        'address': '147 Đường PQR, Quận 11, TP.HCM',
        'discount': 3.0,
        'tax_code': null,
        'tags': ['Mới'],
        'company_id': null,
        'birthday': '03/06/1993',
        'note': 'Khách hàng mới, cần theo dõi',
        'customer_type': 'individual',
      },
      {
        'name': 'Bùi Thị Hoa',
        'gender': 'Nữ',
        'phone': '0978901234',
        'email': 'buithihoa@yahoo.com',
        'address': '258 Đường STU, Quận 4, TP.HCM',
        'discount': 7.0,
        'tax_code': '9988776655',
        'tags': ['Thường xuyên'],
        'company_id': null,
        'birthday': '19/04/1989',
        'note': 'Khách hàng thường xuyên, ổn định',
        'customer_type': 'individual',
      },
    ];

    // Thêm từng customer vào Firestore
    for (final customerData in demoCustomers) {
      await _collection.add(customerData);
    }
  }

  // Xóa tất cả dữ liệu demo (cẩn thận khi sử dụng)
  Future<void> clearAllData() async {
    final snapshot = await _collection.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
} 