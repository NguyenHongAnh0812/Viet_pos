import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final String? taxCode;
  final String? address;
  final String? hotline;
  final String? email;
  final String? website;
  final String? mainContact;
  final String? bankAccount;
  final String? bankName;
  final String? paymentTerm;
  final String status;
  final List<String> tags;
  final String? note;
  final bool isSupplier;
  final bool isCustomer;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    this.taxCode,
    this.address,
    this.hotline,
    this.email,
    this.website,
    this.mainContact,
    this.bankAccount,
    this.bankName,
    this.paymentTerm,
    this.status = 'active',
    this.tags = const [],
    this.note,
    this.isSupplier = true,
    this.isCustomer = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'taxCode': taxCode,
      'address': address,
      'hotline': hotline,
      'email': email,
      'website': website,
      'mainContact': mainContact,
      'bankAccount': bankAccount,
      'bankName': bankName,
      'paymentTerm': paymentTerm,
      'status': status,
      'tags': tags,
      'note': note,
      'isSupplier': isSupplier,
      'isCustomer': isCustomer,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Company.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String status = data['status'] ?? 'active';
    if (status.isEmpty) {
      status = 'active';
    }
    
    return Company(
      id: doc.id,
      name: data['name'] ?? '',
      taxCode: data['taxCode'],
      address: data['address'],
      hotline: data['hotline'],
      email: data['email'],
      website: data['website'],
      mainContact: data['mainContact'],
      bankAccount: data['bankAccount'],
      bankName: data['bankName'],
      paymentTerm: data['paymentTerm'],
      status: status,
      tags: List<String>.from(data['tags'] ?? []),
      note: data['note'],
      isSupplier: data['isSupplier'] ?? true,
      isCustomer: data['isCustomer'] ?? false,
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  Company copyWith({
    String? id,
    String? name,
    String? taxCode,
    String? address,
    String? hotline,
    String? email,
    String? website,
    String? mainContact,
    String? bankAccount,
    String? bankName,
    String? paymentTerm,
    String? status,
    List<String>? tags,
    String? note,
    bool? isSupplier,
    bool? isCustomer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      taxCode: taxCode ?? this.taxCode,
      address: address ?? this.address,
      hotline: hotline ?? this.hotline,
      email: email ?? this.email,
      website: website ?? this.website,
      mainContact: mainContact ?? this.mainContact,
      bankAccount: bankAccount ?? this.bankAccount,
      bankName: bankName ?? this.bankName,
      paymentTerm: paymentTerm ?? this.paymentTerm,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      isSupplier: isSupplier ?? this.isSupplier,
      isCustomer: isCustomer ?? this.isCustomer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 