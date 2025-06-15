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
  final int invoiceStock;    // Số lượng trong hóa đơn
  final double importPrice;   // Giá nhập
  final double salePrice;     // Giá bán
  final bool isActive;        // Trạng thái
  final DateTime createdAt;   // Ngày tạo
  final DateTime updatedAt;   // Ngày cập nhật
  final String? distributor; // Tên nhà phân phối (optional)
  final double? taxRate; // Thuế suất (optional)

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
    this.invoiceStock = 0,
    this.importPrice = 0,
    this.salePrice = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.distributor,
    this.taxRate,
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
      'invoiceStock': invoiceStock,
      'importPrice': importPrice,
      'salePrice': salePrice,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'distributor': distributor,
      'taxRate': taxRate,
    };
  }

  // Create from Firestore document
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    print('\nDEBUG: Parsing product from map:');
    print('ID: $id');
    print('Raw map: $map');
    
    DateTime? createdAt;
    DateTime? updatedAt;
    try {
      print('DEBUG: Parsing createdAt...');
      if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
        print('createdAt is Timestamp: $createdAt');
      } else if (map['createdAt'] is DateTime) {
        createdAt = map['createdAt'] as DateTime;
        print('createdAt is DateTime: $createdAt');
      } else if (map['createdAt'] != null) {
        createdAt = DateTime.tryParse(map['createdAt'].toString());
        print('createdAt parsed from string: $createdAt');
      }
    } catch (e) {
      print('ERROR parsing createdAt: $e');
    }
    
    try {
      print('DEBUG: Parsing updatedAt...');
      if (map['updatedAt'] is Timestamp) {
        updatedAt = (map['updatedAt'] as Timestamp).toDate();
        print('updatedAt is Timestamp: $updatedAt');
      } else if (map['updatedAt'] is DateTime) {
        updatedAt = map['updatedAt'] as DateTime;
        print('updatedAt is DateTime: $updatedAt');
      } else if (map['updatedAt'] != null) {
        updatedAt = DateTime.tryParse(map['updatedAt'].toString());
        print('updatedAt parsed from string: $updatedAt');
      }
    } catch (e) {
      print('ERROR parsing updatedAt: $e');
    }

    if (createdAt == null) {
      print('WARNING: createdAt is null, using current time');
      createdAt = DateTime.now();
    }
    if (updatedAt == null) {
      print('WARNING: updatedAt is null, using current time');
      updatedAt = DateTime.now();
    }

    print('DEBUG: Parsing category...');
    String category = 'Khác';
    if (map['category'] != null) {
      if (map['category'] is List) {
        final categories = (map['category'] as List).map((e) => e.toString()).toList();
        category = categories.isNotEmpty ? categories.first : 'Khác';
        print('Category is List, using first item: $category');
      } else {
        category = map['category'].toString();
        print('Category is String: $category');
      }
    }

    print('DEBUG: Parsing tags...');
    List<String> tags = [];
    if (map['tags'] != null) {
      if (map['tags'] is List) {
        tags = (map['tags'] as List).map((e) => e.toString()).toList();
        print('Tags is List: $tags');
      } else if (map['tags'] is String) {
        tags = (map['tags'] as String).split(',').map((e) => e.trim()).toList();
        print('Tags is String, split by comma: $tags');
      }
    }

    final product = Product(
      id: id,
      name: map['name'] ?? map['commonName'] ?? '',
      commonName: map['commonName'] ?? '',
      category: category,
      barcode: map['barcode'],
      sku: map['sku'],
      unit: map['unit'] ?? '',
      tags: tags,
      description: map['description'] ?? '',
      usage: map['usage'] ?? '',
      ingredients: map['ingredients'] ?? '',
      notes: map['notes'] ?? '',
      stock: map['stock'] ?? 0,
      invoiceStock: map['invoiceStock'] ?? 0,
      importPrice: (map['importPrice'] ?? 0).toDouble(),
      salePrice: (map['salePrice'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
      distributor: map['distributor'],
      taxRate: map['taxRate'],
    );
    
    print('DEBUG: Successfully created product:');
    print('- Name: ${product.name}');
    print('- Category: ${product.category}');
    print('- Stock: ${product.stock}');
    print('- Price: ${product.salePrice}');
    print('=== End Product Parse ===\n');
    
    return product;
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
    int? invoiceStock,
    double? importPrice,
    double? salePrice,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? distributor,
    double? taxRate,
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
      invoiceStock: invoiceStock ?? this.invoiceStock,
      importPrice: importPrice ?? this.importPrice,
      salePrice: salePrice ?? this.salePrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      distributor: distributor ?? this.distributor,
      taxRate: taxRate ?? this.taxRate,
    );
  }
} 