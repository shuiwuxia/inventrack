// lib/product_model.dart

class Product {
  final int id;
  final String name;
  final int quantity; // Assuming 'quantity' is a field in your MySQL table

  Product({required this.id, required this.name, required this.quantity});

  factory Product.fromJson(Map<String, dynamic> json) {
    // Ensure key names (e.g., 'product_id', 'product_name') match
    // the keys returned by your FastAPI endpoint exactly!
    return Product(
      id: (json['id'] is String) ? int.parse(json['id']) : json['id'] as int,
      name: json['name'] as String,
      quantity: (json['quantity'] is String) ? int.parse(json['quantity']) : json['quantity'] as int,
    );
  }
}