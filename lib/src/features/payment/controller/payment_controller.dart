import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:tstripe/src/features/payment/data/payment_repository.dart';
import 'package:tstripe/src/features/payment/models/payment_intent.dart';

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────

@immutable
sealed class PaymentState {
  const PaymentState();

  const factory PaymentState.idle() = Payment$IdleState;
  const factory PaymentState.inProgress() = Payment$InProgressState;
  const factory PaymentState.error(String? message) = Payment$ErrorState;
  const factory PaymentState.completed(PaymentIntent intent) = Payment$CompletedState;

  String? get errorMessage => switch (this) {
    final Payment$ErrorState s => s.message,
    _ => null,
  };

  PaymentIntent? get intent => switch (this) {
    final Payment$CompletedState s => s.intent,
    _ => null,
  };
}

final class Payment$IdleState extends PaymentState {
  const Payment$IdleState();

  @override
  String toString() => 'PaymentState.idle()';
}

final class Payment$InProgressState extends PaymentState {
  const Payment$InProgressState();

  @override
  String toString() => 'PaymentState.inProgress()';
}

final class Payment$ErrorState extends PaymentState {
  const Payment$ErrorState(this.message);

  final String? message;

  Payment$ErrorState copyWith({String? message}) => Payment$ErrorState(message ?? this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Payment$ErrorState && message == other.message);

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'PaymentState.error(message: $message)';
}

final class Payment$CompletedState extends PaymentState {
  const Payment$CompletedState(this.intent);

  @override
  final PaymentIntent intent;

  Payment$CompletedState copyWith({PaymentIntent? intent}) =>
      Payment$CompletedState(intent ?? this.intent);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Payment$CompletedState && intent == other.intent);

  @override
  int get hashCode => intent.hashCode;

  @override
  String toString() => 'PaymentState.completed(intent: $intent)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

/// {@template payment_controller}
/// Manages the lifecycle of a single Stripe one-time payment.
///
/// Uses [DroppableControllerHandler] so that a second tap while a payment is
/// already in-flight is silently dropped (prevents duplicate charges).
/// {@endtemplate}
class PaymentController extends StateController<PaymentState> with DroppableControllerHandler {
  /// {@macro payment_controller}
  PaymentController({required this.repository, super.initialState = const PaymentState.idle()});

  final IPaymentRepository repository;

  /// Resets back to idle (e.g. after showing an error or success banner).
  void reset() => handle(() async {
    setState(const PaymentState.idle());
  });

  /// Creates a PaymentIntent and delegates sheet presentation to [onClientSecret].
  ///
  /// The [onClientSecret] callback is called with the Stripe `client_secret`.
  /// The widget layer is responsible for calling `Stripe.instance.initPaymentSheet`
  /// and `Stripe.instance.presentPaymentSheet` inside that callback.
  /// This keeps `flutter_stripe` out of the controller layer entirely.
  void pay({
    required int amountInCents,
    required String currency,
    required Future<void> Function(String clientSecret) onClientSecret,
  }) => handle(() async {
    setState(const PaymentState.inProgress());
    final intent = await repository.createPaymentIntent(
      amountInCents: amountInCents,
      currency: currency,
    );
    await onClientSecret(intent.clientSecret);
    setState(PaymentState.completed(intent));
  }, error: (e, st) async => setState(PaymentState.error(e.toString())));
}
