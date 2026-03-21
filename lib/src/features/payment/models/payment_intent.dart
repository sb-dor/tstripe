import 'package:flutter/foundation.dart';

/// {@template payment_intent}
/// Represents a Stripe PaymentIntent returned from the API.
/// {@endtemplate}
@immutable
class PaymentIntent {
  /// {@macro payment_intent}
  const PaymentIntent({
    required this.id,
    required this.clientSecret,
    required this.amount,
    required this.currency,
    required this.status,
  });

  /// Creates a [PaymentIntent] from a Stripe API response map.
  factory PaymentIntent.fromMap(Map<String, Object?> map) => PaymentIntent(
    id: map['id'] as String,
    clientSecret: map['client_secret'] as String,
    amount: map['amount'] as int,
    currency: map['currency'] as String,
    status: map['status'] as String,
  );

  /// Stripe PaymentIntent ID (e.g. pi_xxx).
  final String id;

  /// Client secret used to confirm the payment on the client side.
  final String clientSecret;

  /// Amount in the smallest currency unit (e.g. cents for USD).
  final int amount;

  /// Three-letter ISO currency code (e.g. 'usd').
  final String currency;

  /// Current status of the PaymentIntent (e.g. 'requires_payment_method').
  final String status;

  /// Returns a copy with the given fields replaced.
  PaymentIntent copyWith({
    String? id,
    String? clientSecret,
    int? amount,
    String? currency,
    String? status,
  }) => PaymentIntent(
    id: id ?? this.id,
    clientSecret: clientSecret ?? this.clientSecret,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    status: status ?? this.status,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentIntent &&
          id == other.id &&
          clientSecret == other.clientSecret &&
          amount == other.amount &&
          currency == other.currency &&
          status == other.status);

  @override
  int get hashCode =>
      id.hashCode ^ clientSecret.hashCode ^ amount.hashCode ^ currency.hashCode ^ status.hashCode;

  @override
  String toString() =>
      'PaymentIntent{id: $id, amount: $amount, currency: $currency, status: $status}';
}
