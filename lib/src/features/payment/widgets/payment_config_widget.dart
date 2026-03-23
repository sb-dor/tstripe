import 'package:flutter/widgets.dart';
import 'package:tstripe/src/common/util/disposable.dart';
import 'package:tstripe/src/features/initialization/models/dependencies.dart';
import 'package:tstripe/src/features/payment/controller/payment_controller.dart';
import 'package:tstripe/src/features/payment/widgets/controllers/payment_form_controller.dart';

/// {@template payment_config_widget}
/// Scopes [PaymentController] and [PaymentFormController] to the subtree.
///
/// Owns both controller lifecycles: creates them in [State.initState] and
/// disposes them in [State.dispose].
///
/// Access controllers from any descendant widget via the static accessors:
/// ```dart
/// final controller = PaymentConfigWidget.controllerOf(context);
/// final formController = PaymentConfigWidget.formControllerOf(context);
/// final state = PaymentConfigWidget.stateOf(context); // rebuilds on change
/// ```
/// {@endtemplate}
class PaymentConfigWidget extends StatefulWidget {
  /// {@macro payment_config_widget}
  const PaymentConfigWidget({required this.child, super.key});

  final Widget child;

  /// Returns the [PaymentController] from the nearest [PaymentConfigWidget].
  static PaymentController controllerOf(BuildContext context) =>
      _InheritedPaymentScope._of(context, listen: false).controller;

  /// Returns the [PaymentFormController] from the nearest [PaymentConfigWidget].
  static PaymentFormController formControllerOf(BuildContext context) =>
      _InheritedPaymentScope._of(context, listen: false).formController;

  /// Returns the current [PaymentState], subscribing to future updates.
  static PaymentState stateOf(BuildContext context) =>
      _InheritedPaymentScope._of(context, listen: true).state;

  @override
  State<PaymentConfigWidget> createState() => _PaymentConfigWidgetState();
}

class _PaymentConfigWidgetState extends State<PaymentConfigWidget> with Disposable {
  late final PaymentController _controller;
  late final PaymentFormController _formController;

  @override
  void initState() {
    super.initState();
    final dependencies = Dependencies.of(context);
    _controller = PaymentController(repository: dependencies.paymentRepository)
      ..addListener(_onStateChanged);

    /// The `defer` function is used for educational purposes only. You can easily remove controllers released with `dispose`.

    defer(() async {
      _controller
        ..removeListener(_onStateChanged)
        ..dispose();
    });

    _formController = PaymentFormController();
    defer(() async => _formController.dispose());
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    disposeResources();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _InheritedPaymentScope(
    controller: _controller,
    formController: _formController,
    state: _controller.state,
    child: widget.child,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Inherited widget
// ─────────────────────────────────────────────────────────────────────────────

class _InheritedPaymentScope extends InheritedWidget {
  const _InheritedPaymentScope({
    required this.controller,
    required this.formController,
    required this.state,
    required super.child,
  });

  final PaymentController controller;
  final PaymentFormController formController;
  final PaymentState state;

  static _InheritedPaymentScope? _maybeOf(BuildContext context, {bool listen = true}) => listen
      ? context.dependOnInheritedWidgetOfExactType<_InheritedPaymentScope>()
      : context.getInheritedWidgetOfExactType<_InheritedPaymentScope>();

  static _InheritedPaymentScope _of(BuildContext context, {bool listen = true}) =>
      _maybeOf(context, listen: listen) ??
      (throw ArgumentError(
        'Out of scope: no PaymentConfigWidget found in the widget tree.',
        'out_of_scope',
      ));

  @override
  bool updateShouldNotify(covariant _InheritedPaymentScope oldWidget) =>
      !identical(oldWidget.state, state);
}
