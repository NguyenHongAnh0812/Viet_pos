import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String internalName; // internal_name
  final String tradeName;    // trade_name
  final String categoryId;   // category_id
  final String? barcode;
  final String? sku;
  final String unit;
  final List<String> tags;
  final String description;
  final String usage;
  final String ingredients; 
  final String notes;
  final int stockSystem;   // stock_system
  final int stockInvoice;    // stock_invoice
  final double costPrice;
  final double salePrice;
  final double grossProfit;  // gross_profit
  final bool autoPrice;      // auto_price
  final String status;       // status (active/inactive/discontinued)
  final String? discontinueReason; // discontinue_reason
  final DateTime createdAt;  // created_at
  final DateTime updatedAt;  // updated_at

  Product({
    required this.id,
    this.internalName = '',
    this.tradeName = '',
    this.categoryId = '',
    this.barcode,
    this.sku,
    this.unit = '',
    this.tags = const [],
    this.description = '',
    this.usage = '',
    this.ingredients = '',
    this.notes = '',
    this.stockSystem = 0,
    this.stockInvoice = 0,
    this.costPrice = 0,
    this.salePrice = 0,
    this.grossProfit = 0,
    this.autoPrice = false,
    this.status = 'active',
    this.discontinueReason,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'internal_name': internalName,
      'trade_name': tradeName,
      'category_id': categoryId,
      'barcode': barcode,
      'sku': sku,
      'unit': unit,
      'tags': tags,
      'description': description,
      'usage': usage,
      'ingredients': ingredients,
      'notes': notes,
      'stock_system': stockSystem,
      'stock_invoice': stockInvoice,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'gross_profit': grossProfit,
      'auto_price': autoPrice,
      'status': status,
      'discontinue_reason': discontinueReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    DateTime? createdAt;
    DateTime? updatedAt;
    try {
      if (map['created_at'] is Timestamp) {
        createdAt = (map['created_at'] as Timestamp).toDate();
      } else if (map['created_at'] is DateTime) {
        createdAt = map['created_at'] as DateTime;
      } else if (map['created_at'] != null) {
        createdAt = DateTime.tryParse(map['created_at'].toString());
      }
      if (map['updated_at'] is Timestamp) {
        updatedAt = (map['updated_at'] as Timestamp).toDate();
      } else if (map['updated_at'] is DateTime) {
        updatedAt = map['updated_at'] as DateTime;
      } else if (map['updated_at'] != null) {
        updatedAt = DateTime.tryParse(map['updated_at'].toString());
      }
    } catch (e) {}
    return Product(
      id: id,
      internalName: map['internal_name'] ?? '',
      tradeName: map['trade_name'] ?? '',
      categoryId: map['category_id'] ?? '',
      barcode: map['barcode'],
      sku: map['sku'],
      unit: map['unit'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      description: map['description'] ?? '',
      usage: map['usage'] ?? '',
      ingredients: map['ingredients'] ?? '',
      notes: map['notes'] ?? '',
      stockSystem: map['stock_system'] ?? 0,
      stockInvoice: map['stock_invoice'] ?? 0,
      costPrice: (map['cost_price'] ?? 0).toDouble(),
      salePrice: (map['sale_price'] ?? 0).toDouble(),
      grossProfit: (map['gross_profit'] ?? 0).toDouble(),
      autoPrice: map['auto_price'] ?? false,
      status: map['status'] ?? 'active',
      discontinueReason: map['discontinue_reason'],
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Product copyWith({
    String? id,
    String? internalName,
    String? tradeName,
    String? categoryId,
    String? barcode,
    String? sku,
    String? unit,
    List<String>? tags,
    String? description,
    String? usage,
    String? ingredients,
    String? notes,
    int? stockSystem,
    int? stockInvoice,
    double? costPrice,
    double? salePrice,
    double? grossProfit,
    bool? autoPrice,
    String? status,
    String? discontinueReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      internalName: internalName ?? this.internalName,
      tradeName: tradeName ?? this.tradeName,
      categoryId: categoryId ?? this.categoryId,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      usage: usage ?? this.usage,
      ingredients: ingredients ?? this.ingredients,
      notes: notes ?? this.notes,
      stockSystem: stockSystem ?? this.stockSystem,
      stockInvoice: stockInvoice ?? this.stockInvoice,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      grossProfit: grossProfit ?? this.grossProfit,
      autoPrice: autoPrice ?? this.autoPrice,
      status: status ?? this.status,
      discontinueReason: discontinueReason ?? this.discontinueReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 