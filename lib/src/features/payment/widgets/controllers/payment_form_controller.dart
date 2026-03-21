import 'package:flutter/widgets.dart';

/// {@template payment_form_controller}
/// UI state for the payment amount input form.
///
/// Uses [ChangeNotifier] so consumers can rebuild via [ListenableBuilder].
/// Owned and disposed by [PaymentConfigWidget].
/// {@endtemplate}
class PaymentFormController extends ChangeNotifier {
  /// {@macro payment_form_controller}
  PaymentFormController() {
    _amountController = TextEditingController()..addListener(_onAmountChanged);
  }

  late final TextEditingController _amountController;

  /// The underlying [TextEditingController] for the amount text field.
  TextEditingController get amountTextController => _amountController;

  String? _amountError;

  /// Validation error message to display below the amount field, or null.
  String? get amountError => _amountError;

  /// Returns the entered amount in cents, or null if the input is invalid.
  int? get amountInCents {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) return null;
    return (parsed * 100).round();
  }

  /// Whether the current input is a valid payment amount.
  bool get isValid => amountInCents != null;

  void _onAmountChanged() {
    if (_amountError != null) {
      _amountError = null;
      notifyListeners();
    }
  }

  /// Marks the amount field with the given [message] as an error.
  void markError(String message) {
    _amountError = message;
    notifyListeners();
  }

  /// Clears the field and any error state.
  void reset() {
    _amountController.clear();
    _amountError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_onAmountChanged)
      ..dispose();
    super.dispose();
  }
}
