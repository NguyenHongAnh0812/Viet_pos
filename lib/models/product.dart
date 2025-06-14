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
  final int actualStock;     // Số lượng thực tế
  final int invoiceStock;    // Số lượng trong hóa đơn
  final double importPrice;   // Giá nhập
  final double salePrice;     // Giá bán
  final bool isActive;        // Trạng thái
  final DateTime createdAt;   // Ngày tạo
  final DateTime updatedAt;   // Ngày cập nhật

  Product({
    required this.id,
    this.name = '',
    this.commonName = '',
    this.category = 'Khác',
    this.barcode,
    this.sku,
    this.unit = '',
    this.tags = const [],
    this.description = '',
    this.usage = '',
    this.ingredients = '',
    this.notes = '',
    this.stock = 0,
    this.actualStock = 0,
    this.invoiceStock = 0,
    this.importPrice = 0,
    this.salePrice = 0,
    this.isActive = true,
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
      'actualStock': actualStock,
      'invoiceStock': invoiceStock,
      'importPrice': importPrice,
      'salePrice': salePrice,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create from Firestore document
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    DateTime? createdAt;
    DateTime? updatedAt;
    try {
      if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is DateTime) {
        createdAt = map['createdAt'] as DateTime;
      } else if (map['createdAt'] != null) {
        createdAt = DateTime.tryParse(map['createdAt'].toString());
      }
    } catch (_) {}
    try {
      if (map['updatedAt'] is Timestamp) {
        updatedAt = (map['updatedAt'] as Timestamp).toDate();
      } else if (map['updatedAt'] is DateTime) {
        updatedAt = map['updatedAt'] as DateTime;
      } else if (map['updatedAt'] != null) {
        updatedAt = DateTime.tryParse(map['updatedAt'].toString());
      }
    } catch (_) {}
    createdAt ??= DateTime.now();
    updatedAt ??= DateTime.now();

    return Product(
      id: id,
      name: map['name'] ?? map['commonName'] ?? '', // Cho phép sử dụng commonName nếu name trống
      commonName: map['commonName'] ?? '',
      category: map['category'] ?? 'Khác',
      barcode: map['barcode'],
      sku: map['sku'],
      unit: map['unit'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      description: map['description'] ?? '',
      usage: map['usage'] ?? '',
      ingredients: map['ingredients'] ?? '',
      notes: map['notes'] ?? '',
      stock: map['stock'] ?? 0,
      actualStock: map['actualStock'] ?? 0,
      invoiceStock: map['invoiceStock'] ?? 0,
      importPrice: (map['importPrice'] ?? 0).toDouble(),
      salePrice: (map['salePrice'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? commonName,
    String? category,
    String? barcode,
    String? sku,
    String? unit,
    List<String>? tags,
    String? description,
    String? usage,
    String? ingredients,
    String? notes,
    int? stock,
    int? actualStock,
    int? invoiceStock,
    double? importPrice,
    double? salePrice,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      commonName: commonName ?? this.commonName,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      usage: usage ?? this.usage,
      ingredients: ingredients ?? this.ingredients,
      notes: notes ?? this.notes,
      stock: stock ?? this.stock,
      actualStock: actualStock ?? this.actualStock,
      invoiceStock: invoiceStock ?? this.invoiceStock,
      importPrice: importPrice ?? this.importPrice,
      salePrice: salePrice ?? this.salePrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 