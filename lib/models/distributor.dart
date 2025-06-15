import 'package:cloud_firestore/cloud_firestore.dart';

class Distributor {
  final String id;
  final String name;
  final String? phone;
  final String? address;

  Distributor({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });

  factory Distributor.fromMap(String id, Map<String, dynamic> map) {
    return Distributor(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'],
      address: map['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
    };
  }

  Distributor copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
  }) {
    return Distributor(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
} 