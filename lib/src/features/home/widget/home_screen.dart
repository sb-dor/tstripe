import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:tstripe/src/common/router/routes.dart';

/// {@template home_screen}
/// HomeScreen widget — entry point for the meeting lobby.
/// {@endtemplate}
class HomeScreen extends StatelessWidget {
  /// {@macro home_screen}
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton.icon(
        icon: const Icon(Icons.payment),
        label: const Text('Pay with Stripe'),
        onPressed: () => Octopus.of(context).push(Routes.payment),
      ),
    ),
  );
}
