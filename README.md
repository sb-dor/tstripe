# tstripe

A Flutter application demonstrating Stripe one-time payment integration for testing purposes. Supports Android and iOS

---

## Rename the project (optional)

```bash
dart run tool/dart/rename_project.dart --name="project" --organization="dev.flutter" --description="My project description"
```

---

## Stripe Payment Feature

### Packages added

| Package | Purpose |
|---|---|
| `flutter_stripe: ^11.2.0` | Stripe SDK — presents the payment sheet on iOS, Android, and Web |
| `http: ^1.3.0` | Makes HTTP requests to the Stripe API to create PaymentIntents |

---

## Configuration

### 1. Stripe keys

You need two keys from your [Stripe Dashboard](https://dashboard.stripe.com) → Developers → API keys:

| Key | Starts with | Where it goes |
|---|---|---|
| Publishable key | `pk_test_...` | `STRIPE_PUBLISHABLE_KEY` in config |
| Secret key | `sk_test_...` | `STRIPE_SECRET_KEY` in config |

Open `config/production.json` and fill in both values:

```json
{
  "STRIPE_PUBLISHABLE_KEY": "pk_test_YOUR_PUBLISHABLE_KEY_HERE",
  "STRIPE_SECRET_KEY": "sk_test_YOUR_SECRET_KEY_HERE"
}
```

> ⚠️ `config/production.json` is gitignored — never commit your secret key to version control.

> ⚠️ The secret key is only in the app because there is no backend server. In production, the secret key must live only on your server. See `EXPLANATION.md` for full details.

---

### 2. Android setup

#### a) `MainActivity.kt`

`flutter_stripe` requires `MainActivity` to extend `FlutterFragmentActivity` instead of `FlutterActivity`:

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
package your.package.name

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

#### b) Theme — `res/values/styles.xml`

`flutter_stripe` requires the activity theme to use `Theme.MaterialComponents` or `Theme.AppCompat`. Update all four styles files:

**`res/values/styles.xml`** and **`res/values-v31/styles.xml`** (light):
```xml
<style name="LaunchTheme" parent="Theme.MaterialComponents.Light.NoActionBar">
```

**`res/values-night/styles.xml`** and **`res/values-night-v31/styles.xml`** (dark):
```xml
<style name="LaunchTheme" parent="Theme.MaterialComponents.NoActionBar">
```

---

### 3. iOS setup

Add a custom URL scheme to `ios/Runner/Info.plist` for 3D Secure redirect support:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>tstripe</string>
    </array>
  </dict>
</array>
```

This allows Stripe to redirect back to the app after 3DS bank authentication via `tstripe://payment-return`.

---

## Running the app

All launch configurations in `.vscode/launch.json` already pass the config file automatically via `--dart-define-from-file=config/production.json`.

To run manually from the terminal:

```bash
# Android / iOS
flutter run --dart-define-from-file=config/production.json

# Web (Chrome)
flutter run -d chrome --dart-define-from-file=config/production.json
```

---

## Test cards

Use these card numbers in the Stripe payment sheet (never use real cards in test mode):

| Card number | Result |
|---|---|
| `4242 4242 4242 4242` | Payment succeeds |
| `4000 0025 6000 0002` | Payment declined |
| `4000 0027 6000 3184` | Requires 3D Secure authentication |

For all test cards use any future expiry (e.g. `12/34`), any 3-digit CVC, and any 5-digit ZIP.

---

## Architecture

The payment feature follows the project's clean architecture pattern:

```
lib/src/features/payment/
├── controller/payment_controller.dart          # Business logic, sealed states
├── data/payment_repository.dart                # Stripe API call (no-backend mode)
├── models/payment_intent.dart                  # Immutable PaymentIntent model
└── widgets/
    ├── controllers/payment_form_controller.dart # UI state (amount field)
    ├── mobile/payment_mobile_widget.dart        # iOS + Android UI
    ├── web/payment_web_widget.dart              # Web UI
    ├── payment_config_widget.dart               # InheritedWidget scope
    └── payment_screen.dart                      # Route entry point
```

Layer rule: `widgets → controller → data`. Widgets never access repositories directly.

---

## Moving to production (adding a backend)

Only `payment_repository.dart` needs to change. Replace the direct Stripe API call with a call to your own server endpoint:

```dart
// Replace this (direct Stripe call with secret key):
final response = await http.post(
  Uri.parse('https://api.stripe.com/v1/payment_intents'),
  headers: {'Authorization': 'Bearer $secretKey', ...},
  ...
);

// With this (your server call):
final response = await http.post(
  Uri.parse('https://your-server.com/create-payment'),
  headers: {'Authorization': 'Bearer $userToken'},
  body: jsonEncode({'order_id': orderId}),
);
```

Everything else — controller, config widget, payment sheet — stays exactly the same.
