import 'package:flutter/foundation.dart';
import 'package:tstripe/src/features/cart/models/cart_item.dart';
import 'package:tstripe/src/features/shop/models/product.dart';

class CartDataController with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get totalInCents =>
      _items.fold(0, (sum, item) => sum + (item.product.price * 100 * item.quantity).round());

  double get totalAmount => totalInCents / 100;

  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => _items.isEmpty;

  void add(Product product) {
    final index = _items.indexWhere((item) => item.product == product);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
  }

  void increment(Product product) => add(product);

  void decrement(Product product) {
    final index = _items.indexWhere((item) => item.product == product);
    if (index < 0) return;
    if (_items[index].quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity - 1);
    }
    notifyListeners();
  }

  void remove(Product product) {
    _items.removeWhere((item) => item.product == product);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
