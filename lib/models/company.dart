import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final String? taxCode;
  final String? email;
  final String? address;
  final String? contactPerson;
  final String? website;
  final String status;
  final String? paymentTerm;
  final String? bankAccountNumber;
  final String? bankName;
  final List<String> tags;
  final String? notes;

  Company({
    required this.id,
    required this.name,
    this.taxCode,
    this.email,
    this.address,
    this.contactPerson,
    this.website,
    required this.status,
    this.paymentTerm,
    this.bankAccountNumber,
    this.bankName,
    this.tags = const [],
    this.notes,
  });

  factory Company.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Company(
      id: doc.id,
      name: data['name'] ?? '',
      taxCode: data['taxCode'],
      email: data['email'],
      address: data['address'],
      contactPerson: data['contactPerson'],
      website: data['website'],
      status: data['status'] ?? 'Hoạt động',
      paymentTerm: data['paymentTerm'],
      bankAccountNumber: data['bankAccountNumber'],
      bankName: data['bankName'],
      tags: List<String>.from(data['tags'] ?? []),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'taxCode': taxCode,
      'email': email,
      'address': address,
      'contactPerson': contactPerson,
      'website': website,
      'status': status,
      'paymentTerm': paymentTerm,
      'bankAccountNumber': bankAccountNumber,
      'bankName': bankName,
      'tags': tags,
      'notes': notes,
    };
  }
} 