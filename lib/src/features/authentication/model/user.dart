import 'package:flutter/foundation.dart';

@immutable
class User {
  const User({required this.id, this.name, this.email, this.token});

  factory User.fromMap(Map<String, Object?> map, {String? token}) => User(
    id: map['id'] as int,
    name: map['name'] as String?,
    email: map['email'] as String?,
    token: token,
  );

  factory User.defaultUser() =>
      const User(id: -2142, name: 'Riley Vaughan', email: 'riley.vaughan@testc12.com');

  final int id;
  final String? name;
  final String? email;

  /// Sanctum API token — held in memory for the session, never persisted.
  final String? token;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          token == other.token);

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode ^ token.hashCode;

  @override
  String toString() => 'User{id: $id, name: $name, email: $email}';

  User copyWith({int? id, String? name, String? email, String? token}) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    token: token ?? this.token,
  );

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'email': email};
}
