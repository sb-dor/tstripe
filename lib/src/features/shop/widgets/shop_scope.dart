import 'package:flutter/widgets.dart';
import 'package:tstripe/src/features/cart/controller/cart_controller.dart';
import 'package:tstripe/src/features/initialization/models/dependencies.dart';
import 'package:tstripe/src/features/shop/controller/products_controller.dart';

/// {@template shop_scope}
/// Scopes [ProductsController] and [CartController] to the subtree.
///
/// Both controllers are created in [State.initState] and disposed in
/// [State.dispose]. Access them from any descendant via the static accessors.
/// {@endtemplate}
class ShopScope extends StatefulWidget {
  const ShopScope({required this.child, super.key});

  final Widget child;

  static ProductsController productsControllerOf(BuildContext context) =>
      _InheritedShopScope._of(context)._productsController;

  @override
  State<ShopScope> createState() => _ShopScopeState();
}

class _ShopScopeState extends State<ShopScope> {
  late final ProductsController _productsController;

  @override
  void initState() {
    super.initState();
    _productsController = ProductsController(repository: Dependencies.of(context).shopRepository);
  }

  @override
  void dispose() {
    _productsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _InheritedShopScope(state: this, child: widget.child);
}

class _InheritedShopScope extends InheritedWidget {
  const _InheritedShopScope({required this.state, required super.child});

  static _ShopScopeState _of(BuildContext context) {
    final widget = context.getElementForInheritedWidgetOfExactType<_InheritedShopScope>()?.widget;
    assert(widget != null, 'No _InheritedShopScope found in tree');
    return (widget as _InheritedShopScope).state;
  }

  final _ShopScopeState state;

  @override
  bool updateShouldNotify(covariant _InheritedShopScope oldWidget) => false;
}
