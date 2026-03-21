import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:l/l.dart';
import 'package:tstripe/src/features/payment/models/payment_intent.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Interface
// ─────────────────────────────────────────────────────────────────────────────

/// {@template i_payment_repository}
/// Contract for creating Stripe PaymentIntents.
/// {@endtemplate}
abstract interface class IPaymentRepository {
  /// Creates a Stripe PaymentIntent for [amountInCents] in [currency].
  ///
  /// Returns a [PaymentIntent] containing the client secret required
  /// to present the Stripe payment sheet.
  Future<PaymentIntent> createPaymentIntent({required int amountInCents, required String currency});
}

// ─────────────────────────────────────────────────────────────────────────────
// Implementation
// ─────────────────────────────────────────────────────────────────────────────

/// {@template payment_repository_impl}
/// Stripe-backed implementation of [IPaymentRepository].
///
/// ⚠️  WARNING: This implementation calls the Stripe API directly with the
/// secret key from the client.  This is ONLY acceptable for local development
/// and testing.  Never ship a live secret key (sk_live_*) — or any secret key
/// — in production client code.  In production, replace this with a call to
/// your own backend endpoint that creates the PaymentIntent server-side.
/// {@endtemplate}
final class PaymentRepositoryImpl implements IPaymentRepository {
  /// {@macro payment_repository_impl}
  PaymentRepositoryImpl({required this.secretKey});

  /// Stripe secret key (sk_test_...).
  final String secretKey;

  static const _baseUrl = 'https://api.stripe.com/v1';

  @override
  Future<PaymentIntent> createPaymentIntent({
    required int amountInCents,
    required String currency,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payment_intents'),
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amountInCents.toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      },
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, Object?>;
      final error = (body['error'] as Map<String, Object?>?)?['message'] as String?;
      throw Exception('Stripe API error: ${error ?? response.body}');
    }

    l.d('response content: ${response.body}');

    return PaymentIntent.fromMap(jsonDecode(response.body) as Map<String, Object?>);
  }
}
