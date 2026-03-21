import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:tstripe/src/features/payment/controller/payment_controller.dart';
import 'package:tstripe/src/features/payment/widgets/payment_config_widget.dart';

/// {@template payment_mobile_widget}
/// Payment UI for iOS and Android.
///
/// Presents the Stripe payment sheet when the user taps Pay.
/// {@endtemplate}
class PaymentMobileWidget extends StatelessWidget {
  /// {@macro payment_mobile_widget}
  const PaymentMobileWidget({super.key});

  Future<void> _onPay(BuildContext context) async {
    final formController = PaymentConfigWidget.formControllerOf(context);
    final amountInCents = formController.amountInCents;

    if (amountInCents == null) {
      formController.markError('Please enter a valid amount.');
      return;
    }

    PaymentConfigWidget.controllerOf(context).pay(
      amountInCents: amountInCents,
      currency: 'usd',
      onClientSecret: (clientSecret) async {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'TStripe Test',
            returnURL: 'tstripe://payment-return',
          ),
        );
        await Stripe.instance.presentPaymentSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = PaymentConfigWidget.stateOf(context);
    final isInProgress = state is Payment$InProgressState;

    return PopScope(
      canPop: state is! Payment$InProgressState,
      child: Scaffold(
        appBar: AppBar(title: const Text('Make a Payment')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListenableBuilder(
                  listenable: PaymentConfigWidget.formControllerOf(context),
                  builder: (context, _) {
                    final fc = PaymentConfigWidget.formControllerOf(context);
                    return TextField(
                      controller: fc.amountTextController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount (USD)',
                        hintText: 'e.g. 9.99',
                        prefixText: r'$ ',
                        errorText: fc.amountError,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (state is Payment$ErrorState)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      state.message ?? 'An error occurred.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                if (state is Payment$CompletedState)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('Payment successful!', style: TextStyle(color: Colors.green)),
                  ),
                FilledButton(
                  onPressed: isInProgress ? null : () => _onPay(context),
                  child: isInProgress
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Pay'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
