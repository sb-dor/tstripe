import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:tstripe/src/common/constant/config.dart';
import 'package:tstripe/src/features/authentication/widget/authentication_scope.dart';
import 'package:tstripe/src/features/cart/controller/cart_controller.dart';
import 'package:tstripe/src/features/cart/data/cart_repository.dart';
import 'package:tstripe/src/features/cart/models/cart_item.dart';
import 'package:tstripe/src/features/cart/widgets/cart_data_controller.dart';
import 'package:tstripe/src/features/initialization/models/dependencies.dart';

/// {@template cart_screen}
/// CartScope widget.
/// {@endtemplate}
class CartScope extends InheritedWidget {
  /// {@macro cart_screen}
  const CartScope({
    required this.state,
    required super.child,
    super.key, // ignore: unused_element_parameter
  });

  static CartScreenState of(BuildContext context) {
    final widget = context.getElementForInheritedWidgetOfExactType<CartScope>()?.widget;
    assert(widget != null, 'CartScope was not found in element tree');
    return (widget as CartScope).state;
  }

  final CartScreenState state;

  @override
  bool updateShouldNotify(covariant CartScope oldWidget) => false;
}

/// {@template cart_screen}
/// Cart screen — must be pushed while [ShopScope] is in the tree (it is,
/// because [ProductsScreen] wraps its body in [ShopScope]).
/// {@endtemplate}
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  late final CartController cartController;
  late final CartDataController cartDataController;
  late final String token;

  @override
  void initState() {
    super.initState();
    final dependencies = Dependencies.of(context);
    cartDataController = dependencies.cartDataController;
    cartController = CartController(
      iCartRepository: CartRepositoryImpl(baseUrl: Config.backendBaseUrl),
    );
    token = AuthenticationScope.userOf(context, listen: false)?.token ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return CartScope(state: this, child: const _CartScreenBuilder());
  }
}

/// {@template cart_screen}
/// _CartScreenBuilder widget.
/// {@endtemplate}
class _CartScreenBuilder extends StatefulWidget {
  /// {@macro cart_screen}
  const _CartScreenBuilder({
    super.key, // ignore: unused_element_parameter
  });

  @override
  State<_CartScreenBuilder> createState() => __CartScreenBuilderState();
}

/// State for widget _CartScreenBuilder.
class __CartScreenBuilderState extends State<_CartScreenBuilder> {
  late final CartController _cartController;
  late final CartDataController _cartDataController;
  late final String _token;

  /* #region Lifecycle */
  @override
  void initState() {
    super.initState();
    // Initial state initialization
    final cartScope = CartScope.of(context);
    _cartController = cartScope.cartController;
    _cartDataController = cartScope.cartDataController;
    _token = cartScope.token;
  }

  @override
  void dispose() {
    // Permanent removal of a tree stent
    super.dispose();
  }

  Future<void> _checkout() async {
    await _cartController.checkout(
      cartItems: _cartDataController.items,
      token: _token,
      onClientSecret: (clientSecret) async {
        try {
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: 'TStripe Shop',
              returnURL: 'tstripe://payment-return',
            ),
          );
          await Stripe.instance.presentPaymentSheet();

          if (!mounted) return;

          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Payment successful'),
              content: const Text('Your order has been placed.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop(); // back to products
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );

          _cartDataController.clear();
        } on StripeException catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.error.message ?? 'Payment cancelled')));
        } on Object catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_cartController, _cartDataController]),
    builder: (context, _) {
      final cartState = _cartController.state;
      final isProcessing = cartState is Cart$ProcessingState;
      final items = _cartDataController.items;
      return PopScope(
        canPop: !isProcessing,
        child: Scaffold(
          appBar: AppBar(title: const Text('My Cart')),
          body: items.isEmpty
              ? const Center(child: Text('Your cart is empty.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) => _CartItemTile(item: items[index]),
                ),
          bottomNavigationBar: items.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _cartDataController.formattedTotal,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isProcessing ? null : _checkout,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('Checkout · ${_cartDataController.formattedTotal}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    },
  );
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  item.product.formattedPrice,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => CartScope.of(context).cartDataController.decrement(item.product),
              ),
              SizedBox(
                width: 24,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => CartScope.of(context).cartDataController.increment(item.product),
              ),
            ],
          ),
          SizedBox(
            width: 60,
            child: Text(
              item.formattedSubtotal,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
