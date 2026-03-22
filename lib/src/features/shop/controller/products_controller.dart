import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:tstripe/src/features/shop/data/shop_repository.dart';
import 'package:tstripe/src/features/shop/models/product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────

@immutable
sealed class ProductsState {
  const ProductsState();

  const factory ProductsState.idle() = Products$IdleState;
  const factory ProductsState.loading() = Products$LoadingState;
  const factory ProductsState.loaded(List<Product> products) = Products$LoadedState;
  const factory ProductsState.error(String? message) = Products$ErrorState;

  List<Product> get products => switch (this) {
    final Products$LoadedState s => s.products,
    _ => const [],
  };
}

final class Products$IdleState extends ProductsState {
  const Products$IdleState();
}

final class Products$LoadingState extends ProductsState {
  const Products$LoadingState();
}

final class Products$LoadedState extends ProductsState {
  const Products$LoadedState(this.products);

  @override
  final List<Product> products;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Products$LoadedState && products == other.products);

  @override
  int get hashCode => products.hashCode;
}

final class Products$ErrorState extends ProductsState {
  const Products$ErrorState(this.message);

  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Products$ErrorState && message == other.message);

  @override
  int get hashCode => message.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class ProductsController extends StateController<ProductsState> with SequentialControllerHandler {
  ProductsController({required this.repository, super.initialState = const ProductsState.idle()});

  final IShopRepository repository;

  void load({required String token}) => handle(() async {
    setState(const ProductsState.loading());
    final products = await repository.getProducts(token: token);
    setState(ProductsState.loaded(products));
  }, error: (e, st) async => setState(ProductsState.error(e.toString())));
}
