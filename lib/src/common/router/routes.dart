import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:tstripe/src/features/account/widget/profile_screen.dart';
import 'package:tstripe/src/features/authentication/widget/signin_screen.dart';
import 'package:tstripe/src/features/cart/widgets/cart_screen.dart';
import 'package:tstripe/src/features/developer/widget/developer_screen.dart';
import 'package:tstripe/src/features/home/widget/home_screen.dart';
import 'package:tstripe/src/features/payment/widgets/payment_screen.dart';
import 'package:tstripe/src/features/settings/widget/settings_screen.dart';
import 'package:tstripe/src/features/shop/widgets/products_screen.dart';

enum Routes with OctopusRoute {
  signin('signin', title: 'Sign-In'),
  home('home', title: 'Agora Call'),
  profile('profile', title: 'Profile'),
  developer('developer', title: 'Developer'),
  //settingsDialog('settings-dialog', title: 'Settings'),
  settings('settings', title: 'Settings'),
  payment('payment', title: 'Payment'),
  shop('shop', title: 'Shop'),
  cart('cart', title: 'Cart');

  const Routes(this.name, {this.title});

  @override
  final String name;

  /// title is not necessary
  @override
  final String? title;

  @override
  Widget builder(BuildContext context, OctopusState state, OctopusNode node) => switch (this) {
    Routes.signin => const SignInScreen(),
    Routes.home => const HomeScreen(),
    Routes.profile => const ProfileScreen(),
    Routes.developer => const DeveloperScreen(),
    Routes.settings => const SettingsScreen(),
    Routes.payment => const PaymentScreen(),
    Routes.shop => const ProductsScreen(),
    Routes.cart => const CartScreen(),
  };
}
