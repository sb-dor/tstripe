import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:tstripe/src/features/payment/widgets/mobile/payment_mobile_widget.dart';
import 'package:tstripe/src/features/payment/widgets/payment_config_widget.dart';
import 'package:tstripe/src/features/payment/widgets/web/payment_web_widget.dart';

/// {@template payment_screen}
/// Entry-point screen for the payment flow.
///
/// Wraps the platform-appropriate widget with [PaymentConfigWidget] to scope
/// the payment and form controllers to the subtree.
/// {@endtemplate}
class PaymentScreen extends StatelessWidget {
  /// {@macro payment_screen}
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PaymentConfigWidget(child: kIsWeb ? PaymentWebWidget() : PaymentMobileWidget());
}
