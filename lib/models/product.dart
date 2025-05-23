class Product {
  final String id;
  final String name;
  final String description;
  final String barcode;
  final List<String> tags;
  final int price;
  final int stock;
  final String category;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.barcode,
    required this.tags,
    required this.price,
    required this.stock,
    required this.category,
    required this.isActive,
  });
} 