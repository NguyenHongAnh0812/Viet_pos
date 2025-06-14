import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfig {
  final String id;
  final bool showProductDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppConfig({
    required this.id,
    required this.showProductDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppConfig(
      id: doc.id,
      showProductDetails: data['showProductDetails'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showProductDetails': showProductDetails,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AppConfig copyWith({
    String? id,
    bool? showProductDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppConfig(
      id: id ?? this.id,
      showProductDetails: showProductDetails ?? this.showProductDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 