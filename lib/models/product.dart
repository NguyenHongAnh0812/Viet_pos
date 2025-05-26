import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;           // Tên danh pháp
  final String commonName;     // Tên thông dụng
  final String category;       // Danh mục
  final String? barcode;       // Mã vạch (optional)
  final String? sku;          // SKU (optional)
  final String unit;          // Đơn vị tính
  final List<String> tags;    // Tags
  final String description;   // Mô tả
  final String usage;         // Công dụng
  final String ingredients;   // Thành phần
  final String notes;         // Ghi chú
  final int stock;           // Số lượng
  final double importPrice;   // Giá nhập
  final double salePrice;     // Giá bán
  final bool isActive;        // Trạng thái
  final DateTime createdAt;   // Ngày tạo
  final DateTime updatedAt;   // Ngày cập nhật

  Product({
    required this.id,
    required this.name,
    required this.commonName,
    required this.category,
    this.barcode,
    this.sku,
    required this.unit,
    required this.tags,
    required this.description,
    required this.usage,
    required this.ingredients,
    required this.notes,
    required this.stock,
    required this.importPrice,
    required this.salePrice,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'commonName': commonName,
      'category': category,
      'barcode': barcode,
      'sku': sku,
      'unit': unit,
      'tags': tags,
      'description': description,
      'usage': usage,
      'ingredients': ingredients,
      'notes': notes,
      'stock': stock,
      'importPrice': importPrice,
      'salePrice': salePrice,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create from Firestore document
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      commonName: map['commonName'] ?? '',
      category: map['category'] ?? '',
      barcode: map['barcode'],
      sku: map['sku'],
      unit: map['unit'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      description: map['description'] ?? '',
      usage: map['usage'] ?? '',
      ingredients: map['ingredients'] ?? '',
      notes: map['notes'] ?? '',
      stock: map['stock'] ?? 0,
      importPrice: (map['importPrice'] ?? 0).toDouble(),
      salePrice: (map['salePrice'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
} 