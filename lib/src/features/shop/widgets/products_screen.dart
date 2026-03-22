// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

import 'package:tstripe/src/common/router/routes.dart';
import 'package:tstripe/src/features/authentication/widget/authentication_scope.dart';
import 'package:tstripe/src/features/cart/widgets/cart_data_controller.dart';
import 'package:tstripe/src/features/initialization/models/dependencies.dart';
import 'package:tstripe/src/features/shop/controller/products_controller.dart';
import 'package:tstripe/src/features/shop/models/product.dart';
import 'package:tstripe/src/features/shop/widgets/shop_scope.dart';

/// {@template products_screen}
/// Product grid — wrapped in [ShopScope] for DI.
/// {@endtemplate}
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ShopScope(child: _ProductsBody());
}

class _ProductsBody extends StatefulWidget {
  const _ProductsBody();

  @override
  State<_ProductsBody> createState() => _ProductsBodyState();
}

class _ProductsBodyState extends State<_ProductsBody> {
  late final ProductsController _productsController;
  late final CartDataController _cartDataController;
  late final String token;

  @override
  void initState() {
    super.initState();
    final dependencies = Dependencies.of(context);
    token = AuthenticationScope.userOf(context, listen: false)?.token ?? '';
    _productsController = ShopScope.productsControllerOf(context)..load(token: token);
    _cartDataController = dependencies.cartDataController;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_productsController, _cartDataController]),
      builder: (context, child) {
        final productsState = _productsController.state;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Products'),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: _cartDataController.items.isEmpty
                        ? null
                        : () => Octopus.of(context).push(Routes.cart),
                  ),
                  if (_cartDataController.itemCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          '${_cartDataController.itemCount}',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: switch (productsState) {
            Products$LoadingState() ||
            Products$IdleState() => const Center(child: CircularProgressIndicator()),
            Products$ErrorState(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message ?? 'Failed to load products'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ShopScope.productsControllerOf(context).load(token: token),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            Products$LoadedState(:final products) => RefreshIndicator(
              onRefresh: () async => ShopScope.productsControllerOf(context).load(token: token),
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) => _ProductCard(
                  product: products[index],
                  inCart: _cartDataController.items.any(
                    (el) => el.product.id == products[index].id,
                  ),
                  addToCart: () => _cartDataController.add(products[index]),
                ),
              ),
            ),
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.inCart, required this.addToCart});

  final Product product;
  final bool inCart;
  final void Function() addToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product image placeholder
          Expanded(
            child: Container(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.formattedPrice,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: addToCart,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      backgroundColor: inCart ? theme.colorScheme.primary : null,
                    ),
                    child: Text(
                      inCart ? 'Added' : 'Add to Cart',
                      style: TextStyle(
                        fontSize: 12,
                        color: inCart ? theme.colorScheme.onPrimary : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
