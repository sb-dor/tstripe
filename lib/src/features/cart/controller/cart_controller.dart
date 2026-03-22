import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:tstripe/src/features/cart/data/cart_repository.dart';
import 'package:tstripe/src/features/cart/models/cart_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

@immutable
sealed class CartState {
  const CartState();

  const factory CartState.idle() = Cart$IdleState;
  const factory CartState.processing() = Cart$ProcessingState;
  const factory CartState.error({final String? message}) = Cart$ErrorState;
  const factory CartState.completed() = Cart$CompletedState;
}

final class Cart$IdleState extends CartState {
  const Cart$IdleState();
}

final class Cart$ProcessingState extends CartState {
  const Cart$ProcessingState();
}

final class Cart$ErrorState extends CartState {
  const Cart$ErrorState({this.message});

  final String? message;
}

final class Cart$CompletedState extends CartState {
  const Cart$CompletedState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class CartController extends StateController<CartState> with SequentialControllerHandler {
  CartController({required ICartRepository iCartRepository})
    : _cartRepository = iCartRepository,
      super(initialState: const CartState.idle());

  final ICartRepository _cartRepository;

  /// Creates a server-side order then delegates sheet presentation to [onClientSecret].
  ///
  /// [onClientSecret] is called with the Stripe `client_secret`. The widget layer
  /// is responsible for calling `Stripe.instance.initPaymentSheet` and
  /// `Stripe.instance.presentPaymentSheet` inside that callback.
  /// This keeps `flutter_stripe` out of the controller entirely.
  ///
  /// On success: transitions processing → completed (with paid items) → idle (empty).
  /// On error: transitions back to idle (items preserved) and rethrows.
  Future<void> checkout({
    required final List<CartItem> cartItems,
    required String token,
    required Future<void> Function(String clientSecret) onClientSecret,
  }) => handle<void>(() async {
    setState(const CartState.processing());
    final intent = await _cartRepository.checkout(items: cartItems, token: token);
    await onClientSecret(intent.clientSecret);
    setState(const CartState.completed());
    setState(const CartState.idle());
  }, error: (error, stackTrace) async => setState(const CartState.error()));
}
