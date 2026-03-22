import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:l/l.dart';
import 'package:tstripe/src/features/cart/models/cart_item.dart';
import 'package:tstripe/src/features/payment/models/payment_intent.dart';

abstract interface class ICartRepository {
  Future<PaymentIntent> checkout({
    required List<CartItem> items,
    required String token,
  });
}

final class CartRepositoryImpl implements ICartRepository {
  CartRepositoryImpl({required this.baseUrl});

  final String baseUrl;

  @override
  Future<PaymentIntent> checkout({
    required List<CartItem> items,
    required String token,
  }) async {
    final body = {
      'items': items
          .map((item) => {'product_id': item.product.id, 'quantity': item.quantity})
          .toList(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/orders/checkout'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final responseBody = jsonDecode(response.body) as Map<String, Object?>;
      throw Exception(responseBody['message'] ?? 'Checkout failed');
    }

    l.d('checkout response: ${response.body}');

    return PaymentIntent.fromMap(jsonDecode(response.body) as Map<String, Object?>);
  }
}
