import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:l/l.dart';
import 'package:tstripe/src/features/authentication/model/user.dart';

abstract interface class IAuthenticationRepository {
  /// Login with email and password.
  Future<User> signIn({required String email, required String password});

  /// Register a new account with name, email, and password.
  Future<User> register({required String name, required String email, required String password});

  /// Revoke the current Sanctum token.
  Future<void> logout({required String token});
}

final class AuthenticationRepositoryImpl implements IAuthenticationRepository {
  AuthenticationRepositoryImpl({required this.baseUrl});

  final String baseUrl;

  @override
  Future<User> signIn({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, Object?>;
    l.d('login response: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'Invalid email or password.');
    }

    return User.fromMap(body['user'] as Map<String, Object?>, token: body['token'] as String?);
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, Object?>;
    l.d('register response: ${response.body}');

    if (response.statusCode != 201) {
      // Laravel validation errors come as { errors: { field: [messages] } }
      final errors = body['errors'] as Map<String, Object?>?;
      final firstError = errors?.values.firstOrNull;
      final message = firstError is List ? firstError.firstOrNull?.toString() : null;
      throw Exception(message ?? body['message'] ?? 'Registration failed.');
    }

    return User.fromMap(body['user'] as Map<String, Object?>, token: body['token'] as String?);
  }

  @override
  Future<void> logout({required String token}) async {
    await http.post(
      Uri.parse('$baseUrl/api/auth/logout'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
  }
}

class AuthenticationRepositoryFake implements IAuthenticationRepository {
  @override
  Future<User> signIn({required String email, required String password}) async =>
      User.defaultUser();

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async => User.defaultUser();

  @override
  Future<void> logout({required String token}) async {}
}
