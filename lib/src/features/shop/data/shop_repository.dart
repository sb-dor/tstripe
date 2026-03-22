import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:l/l.dart';
import 'package:tstripe/src/features/shop/models/product.dart';

abstract interface class IShopRepository {
  Future<List<Product>> getProducts({required String token});
}

final class ShopRepositoryImpl implements IShopRepository {
  ShopRepositoryImpl({required this.baseUrl});

  final String baseUrl;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  @override
  Future<List<Product>> getProducts({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/products'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, Object?>;
      throw Exception(body['message'] ?? 'Failed to load products');
    }

    l.d('products response: ${response.body}');

    final list = jsonDecode(response.body) as List<Object?>;
    return list.map((e) => Product.fromMap(e as Map<String, Object?>)).toList();
  }
}
