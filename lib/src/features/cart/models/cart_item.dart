import 'package:flutter/foundation.dart';
import 'package:tstripe/src/features/shop/models/product.dart';

@immutable
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get subtotal => product.price * quantity;

  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';

  CartItem copyWith({Product? product, int? quantity}) =>
      CartItem(product: product ?? this.product, quantity: quantity ?? this.quantity);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CartItem && product == other.product);

  @override
  int get hashCode => product.hashCode;

  @override
  String toString() => 'CartItem{product: ${product.name}, quantity: $quantity}';
}
