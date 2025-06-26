import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String? gender;
  final String phone;
  final String? email;
  final String? address;
  final double? discount;
  final String? taxCode;
  final List<String>? tags;
  final String? companyId;

  Customer({
    required this.id,
    required this.name,
    this.gender,
    required this.phone,
    this.email,
    this.address,
    this.discount,
    this.taxCode,
    this.tags,
    this.companyId,
  });

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    return Customer(
      id: id,
      name: map['name'] ?? '',
      gender: map['gender'],
      phone: map['phone'] ?? '',
      email: map['email'],
      address: map['address'],
      discount: (map['discount'] is int)
          ? (map['discount'] as int).toDouble()
          : (map['discount'] as num?)?.toDouble(),
      taxCode: map['tax_code'],
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList(),
      companyId: map['company_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender,
      'phone': phone,
      'email': email,
      'address': address,
      'discount': discount,
      'tax_code': taxCode,
      'tags': tags,
      'company_id': companyId,
    };
  }

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    return Customer.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
} 