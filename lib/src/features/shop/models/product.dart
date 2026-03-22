import 'package:flutter/foundation.dart';

@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
  });

  factory Product.fromMap(Map<String, Object?> map) => Product(
    id: map['id'] as int,
    name: map['name'] as String,
    description: map['description'] as String,
    price: (map['price'] as num).toDouble(),
    imageUrl: map['image_url'] as String?,
  );

  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Product{id: $id, name: $name, price: $price}';
}
