import 'dart:async';

import 'package:control/control.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:l/l.dart';
import 'package:platform_info/platform_info.dart';
import 'package:tstripe/src/common/constant/config.dart';
import 'package:tstripe/src/common/constant/pubspec.yaml.g.dart';
import 'package:tstripe/src/common/controller/controller_observer.dart';
import 'package:tstripe/src/common/model/app_metadata.dart';
import 'package:tstripe/src/common/util/screen_util.dart';
import 'package:tstripe/src/features/authentication/controller/authentication_controller.dart';
import 'package:tstripe/src/features/authentication/data/authentication_repository.dart';
import 'package:tstripe/src/features/cart/controller/cart_controller.dart';
import 'package:tstripe/src/features/cart/data/cart_repository.dart';
import 'package:tstripe/src/features/cart/widgets/cart_data_controller.dart';
import 'package:tstripe/src/features/initialization/data/platform/platform_initialization.dart';
import 'package:tstripe/src/features/initialization/models/dependencies.dart';
import 'package:tstripe/src/features/payment/data/payment_repository.dart';
import 'package:tstripe/src/features/shop/data/shop_repository.dart';

/// Initializes the app and returns a [Dependencies] object
Future<Dependencies> $initializeDependencies({
  void Function(int progress, String message)? onProgress,
}) async {
  final dependencies = Dependencies();
  final totalSteps = _initializationSteps.length;
  var currentStep = 0;
  for (final step in _initializationSteps.entries) {
    try {
      currentStep++;
      final percent = (currentStep * 100 ~/ totalSteps).clamp(0, 100);
      onProgress?.call(percent, step.key);
      l.v6('Initialization | $currentStep/$totalSteps ($percent%) | "${step.key}"');
      await step.value(dependencies);
    } on Object catch (error, stackTrace) {
      l.e('Initialization failed at step "${step.key}": $error', stackTrace);
      Error.throwWithStackTrace('Initialization failed at step "${step.key}": $error', stackTrace);
    }
  }
  return dependencies;
}

typedef _InitializationStep = FutureOr<void> Function(Dependencies dependencies);

final Map<String, _InitializationStep> _initializationSteps = <String, _InitializationStep>{
  'Platform pre-initialization': (_) => $platformInitialization(),
  'Creating app metadata': (dependencies) => dependencies.metadata = AppMetadata(
    isWeb: platform.js,
    isRelease: platform.buildMode.release,
    appName: Pubspec.name,
    appVersion: Pubspec.version.representation,
    appVersionMajor: Pubspec.version.major,
    appVersionMinor: Pubspec.version.minor,
    appVersionPatch: Pubspec.version.patch,
    appBuildTimestamp: Pubspec.version.build.isNotEmpty
        ? (int.tryParse(Pubspec.version.build.firstOrNull ?? '-1') ?? -1)
        : -1,
    operatingSystem: platform.operatingSystem.name,
    processorsCount: platform.numberOfProcessors,
    appLaunchedTimestamp: DateTime.now(),
    locale: platform.locale,
    deviceVersion: platform.version,
    deviceScreenSize: ScreenUtil.screenSize().representation,
  ),
  'Observer state management': (_) => Controller.observer = const ControllerObserver(),
  'Initializing analytics': (_) {},
  'Log app open': (_) {},
  'Get remote config': (_) {},
  'Restore settings': (_) {},
  'Prepare authentication controller': (dependencies) =>
      dependencies.authenticationController = AuthenticationController(
        repository: AuthenticationRepositoryImpl(baseUrl: Config.backendBaseUrl),
      ),
  'Initialize Stripe SDK': (_) {
    Stripe.publishableKey = Config.stripePublishableKey;
  },
  'Prepare payment repository': (dependencies) =>
      dependencies.paymentRepository = Config.backendBaseUrl.isNotEmpty
      ? BackendPaymentRepositoryImpl(baseUrl: Config.backendBaseUrl)
      : PaymentRepositoryImpl(secretKey: Config.stripeSecretKey),
  'Prepare shop repository': (dependencies) =>
      dependencies.shopRepository = ShopRepositoryImpl(baseUrl: Config.backendBaseUrl),
  'Prepare cart repository': (dependencies) =>
      dependencies.cartRepository = CartRepositoryImpl(baseUrl: Config.backendBaseUrl),
  'Prepare cart controller': (dependencies) =>
      dependencies.cartDataController = CartDataController(),
  // The 'Shrink database' step will only be included in non-release build
};
