# Stripe Payment — Full Explanation

This document covers everything discussed about how Stripe payments work in this app, from keys to webhooks.

---

## 1. Publishable key vs Secret key

Two keys are needed, but they serve completely different purposes:

| Key | Starts with | Who uses it | Why |
|---|---|---|---|
| Publishable key | `pk_test_...` | `flutter_stripe` SDK (client) | Identifies your Stripe account when presenting the payment sheet. Safe to ship in client code. |
| Secret key | `sk_test_...` | Server (or our repo in test mode) | Creates PaymentIntents via the Stripe REST API. Must never be exposed in client code in production. |

---

## 2. With backend vs without backend

### Without backend (current test setup)

Both keys live inside the app. The app calls the Stripe API directly to create a PaymentIntent.

```
App                              Stripe API
 │                                    │
 │── POST /v1/payment_intents ────────▶│  (using sk_test_ directly from app)
 │◀─ { client_secret: "pi_xxx..." } ──│
 │                                    │
 │── initPaymentSheet(client_secret) ─▶│
 │── User enters card number          │
 │── presentPaymentSheet() ───────────▶│
 │◀─ success ─────────────────────────│
```

**Problem:** `sk_test_...` is inside the app. Anyone can decompile your app, extract the secret key, and create unlimited PaymentIntents on your Stripe account.

### With backend (production)

Only the publishable key is in the app. The secret key lives exclusively on your server.

```
App                  Your Server              Stripe API
 │                        │                       │
 │── POST /create-payment ▶│                       │
 │   { order_id: "123" }   │── POST /v1/payment_intents ──▶│
 │                         │   (sk_live_ stays on server)  │
 │                         │◀─ { client_secret } ──────────│
 │◀─ { client_secret } ────│
 │                                                │
 │── initPaymentSheet(client_secret) ─────────────▶│
 │── presentPaymentSheet() ───────────────────────▶│
 │◀─ success ──────────────────────────────────────│
```

**Only one file changes when adding a backend** — `payment_repository.dart`. Everything else (controller, widgets, payment sheet) stays exactly the same.

### What a backend also gives you

| Concern | Without backend | With backend |
|---|---|---|
| Secret key safety | Exposed in app | Stays on server |
| Amount control | Could be tampered | Server decides the amount |
| Auth checks | None | "Is this user logged in? Do they owe this amount?" |
| Logging | No record | Every payment attempt logged |
| Webhooks | Can't receive | Server listens for `payment_intent.succeeded` |

---

## 3. What is `clientSecret`?

The `clientSecret` is a **one-time token** that proves to Stripe that your server already authorized a specific payment.

After calling `POST /v1/payment_intents`, Stripe creates a pending payment record on their servers and returns a `clientSecret` like `pi_3ABC...._secret_XYZ`.

The app passes this token to `flutter_stripe`:
- `initPaymentSheet(clientSecret)` — tells the SDK which payment to confirm and what amount was authorized
- `presentPaymentSheet()` — shows the card form, user enters card, Stripe uses the `clientSecret` to find and complete the pending payment

**Why it exists:** It separates two responsibilities:

| Step | Who does it | Uses |
|---|---|---|
| "I authorize a $9.99 charge" | Server (or app in test mode) | Secret key |
| "I confirm it with a card" | Client (`flutter_stripe`) | `clientSecret` |

The `clientSecret` is safe to send to the client — it can only **confirm** an already-created payment, not create new ones or access your account.

---

## 4. Do you need to save the `clientSecret`?

**No.** Every time the Pay button is tapped, a new PaymentIntent is created and a new `clientSecret` is returned. You do not store it anywhere — it lives only inside the `onClientSecret` callback, gets passed to `initPaymentSheet`, used by `presentPaymentSheet`, and then discarded.

```
Tap Pay → create new PaymentIntent → get new clientSecret → present sheet
Tap Pay → create new PaymentIntent → get new clientSecret → present sheet
Tap Pay → create new PaymentIntent → get new clientSecret → present sheet
```

Incomplete PaymentIntents on Stripe's side (from cancelled/rejected attempts) stay as `requires_payment_method` and expire automatically after **24 hours**. Stripe does not charge for incomplete PaymentIntents.

---

## 5. Full order payment flow (with backend)

This is how a real production payment for an order works, step by step.

### Step 1 — User picks items and taps "Checkout"
```
App shows order summary:
  Coffee        $3.50
  Sandwich      $6.00
  ─────────────────────
  Total         $9.50

  [ Pay $9.50 ]
```

### Step 2 — App tells your server about the order
```
App ──▶ POST https://your-server.com/orders/create-payment
        { "order_id": "order_123", "user_id": "user_456" }
```
Server looks up `order_123` in the database → sees total is `$9.50` → calls Stripe with `amount: 950`.

### Step 3 — Server creates PaymentIntent on Stripe
```
Server ──▶ POST https://api.stripe.com/v1/payment_intents
           { "amount": 950, "currency": "usd", "metadata": { "order_id": "order_123" } }

Server ◀── { "client_secret": "pi_xxx_secret_xxx" }
```
The amount is decided by the server, not the user — preventing tampering.

### Step 4 — Server returns `clientSecret` to app
```
App ◀── { "client_secret": "pi_xxx_secret_xxx" }
```

### Step 5 — App presents Stripe payment sheet
```
flutter_stripe shows card form:
┌─────────────────────────────┐
│  Pay $9.50                  │
│  Card number                │
│  4242 4242 4242 4242        │
│  MM/YY        CVC           │
│  [ Pay $9.50 ]              │
└─────────────────────────────┘
```

### Step 6 — Stripe confirms, server gets notified via webhook
```
Stripe ──▶ POST https://your-server.com/webhooks/stripe
           { "type": "payment_intent.succeeded", "data": { "metadata": { "order_id": "order_123" } } }

Server marks order_123 as PAID in database
Server sends confirmation email to user
Server triggers order fulfillment
```

### Step 7 — App shows success
```
✓ Payment successful!
  Your order is confirmed.
```

---

## 6. What if the payment fails mid-flow?

If the card is declined or the user cancels, **you do not request a new `clientSecret`**. The PaymentIntent stays alive with status `requires_payment_method` and can be retried with the same `clientSecret`.

```
Attempt 1: user enters wrong card → DECLINED
           PaymentIntent status: requires_payment_method ← still alive

Attempt 2: same clientSecret → user enters correct card → SUCCESS
           PaymentIntent status: succeeded
```

A smart server checks if an order already has a PaymentIntent before creating a new one:

```
App ──▶ POST /orders/create-payment { order_id: "order_123" }

Server checks database:
  ├── No existing PaymentIntent?
  │     └── create new one → save to DB → return clientSecret
  │
  └── Already has a PaymentIntent (previous failed attempt)?
        └── return the SAME clientSecret ← no new Stripe call
```

### When you DO need a new PaymentIntent

| Situation | Action |
|---|---|
| Card declined, retry | Reuse same `clientSecret` |
| User cancelled sheet | Reuse same `clientSecret` |
| 3DS authentication failed | Reuse same `clientSecret` |
| Amount changed (user edited order) | New PaymentIntent needed |
| 24 hours passed (expired) | New PaymentIntent needed |
| Payment already succeeded | New PaymentIntent needed (new order) |

One order = one PaymentIntent. The `clientSecret` stays valid until the payment succeeds or expires.

---

## 7. What is a webhook?

A webhook is your server's way of hearing from Stripe that something happened — instead of constantly asking Stripe "did it work yet?".

### Polling (bad approach)
```
App asks server every second:
App ──▶ "did payment succeed?"  Server: "not yet"
App ──▶ "did payment succeed?"  Server: "not yet"
App ──▶ "did payment succeed?"  Server: "YES"

Wasteful, slow, unreliable
```

### Webhook (correct approach)
```
Stripe ──▶ Server: "payment succeeded" (fired instantly by Stripe)
Server reacts immediately
```

A webhook is simply a **POST request that Stripe sends to your server** when something happens:

```
Stripe                        Your Server
  │                               │
  │── POST /webhooks/stripe ──────▶│
  │   {                           │
  │     "type": "payment_intent   │
  │              .succeeded",     │
  │     "data": {                 │
  │       "amount": 950,          │
  │       "metadata": {           │
  │         "order_id": "123"     │
  │       }                       │
  │     }                         │
  │   }                           │
  │                               │  mark order_123 as PAID
  │                               │  send confirmation email
  │                               │  trigger delivery
  │◀── 200 OK ────────────────────│
```

### Why not just trust the app?

```
Without webhook:
App ──▶ Server: "hey payment worked, mark order as paid"
Problem: anyone can send that request without actually paying

With webhook:
Stripe ──▶ Server: "payment worked"
Stripe signs every webhook with a secret signature → 100% trusted
```

### Common Stripe webhook events

| Event | When it fires |
|---|---|
| `payment_intent.succeeded` | Payment completed successfully |
| `payment_intent.payment_failed` | Card declined or failure |
| `payment_intent.canceled` | PaymentIntent expired or cancelled |
| `charge.refunded` | You issued a refund |
| `customer.subscription.created` | New subscription started |

### The key distinction

```
flutter_stripe  →  tells the APP    the payment succeeded (UI feedback only)
webhook         →  tells YOUR SERVER the payment succeeded (business logic)

Both are needed. One without the other is incomplete.
```

The app showing "Payment successful!" and the server actually fulfilling the order are two separate things — the webhook is what connects them reliably.

---

## 8. What is `tstripe://payment-return`?

This is a **deep link URL scheme** used for 3D Secure (3DS) authentication redirects.

Some cards require extra verification — Stripe opens the bank's authentication page in a browser. After the user approves, the bank redirects to `tstripe://payment-return`. iOS recognizes `tstripe://` as belonging to your app (registered in `Info.plist`) and brings the app back to the foreground. Stripe then completes the payment.

```
tstripe://payment-return
   │            │
   │            └── path (just a label)
   └── your app's custom URL scheme (registered in Info.plist)
```

On Android, `FlutterFragmentActivity` handles this automatically — no URL scheme registration needed.

| Test card | 3DS required | `returnURL` used |
|---|---|---|
| `4242 4242 4242 4242` | No | No |
| `4000 0027 6000 3184` | Yes | Yes |

---

## 9. Authentication — email + password with Sanctum

Authentication was upgraded from a name-only approach to real email + password registration and login backed by Laravel Sanctum.

### `User` model (`model/user.dart`)

A `token` field was added:

```dart
const User({required this.id, this.name, this.email, this.token});
final String? token;
```

The token is the Sanctum plain-text API token returned after login/register. It lives **only in memory** for the session — it is never written to disk. Every authenticated API call includes it as `Authorization: Bearer <token>`.

### `IAuthenticationRepository`

```dart
abstract interface class IAuthenticationRepository {
  Future<User> signIn({required String email, required String password});
  Future<User> register({required String name, required String email, required String password});
  Future<void> logout({required String token});
}
```

- `signIn` → `POST /api/auth/login`
- `register` → `POST /api/auth/register` (also sends `password_confirmation`)
- `logout` → `POST /api/auth/logout` with `Authorization: Bearer <token>`

Laravel validation errors (e.g. email already taken) come as `{ errors: { field: [messages] } }`. The repository unwraps the first message and re-throws it as an `Exception` so the controller can surface it.

### `AuthenticationController`

```dart
void signIn({required String email, required String password})
void register({required String name, required String email, required String password})
void logout()
```

Both `signIn` and `register` set `inProgress` state first, call the repository, then set `authenticated` on success or `error` on failure. Uses `DroppableControllerHandler` — if the user taps the button twice, the second call is dropped.

### `SignInScreen`

A single screen handles both login and register with a toggle:

- **Login mode**: email + password fields
- **Register mode**: name + email + password fields (name field appears/disappears via `_isRegister` flag)
- Password field has a show/hide toggle (`_obscurePassword`)
- Error banner appears when state is `Authentication$ErrorState`
- Button shows `CircularProgressIndicator` when `Authentication$InProgressState`
- `PopScope(canPop: !isInProgress)` prevents backing out mid-request

The screen uses `ListenableBuilder` (instead of `AnimatedBuilder`) wrapping the controller directly — no need for `AuthenticationScope.of` inside the builder because the controller is cached in `initState`.

---

## 10. Shop feature — products catalogue

### `ShopScope` (`features/shop/widgets/shop_scope.dart`)

A `StatefulWidget` + `InheritedWidget` pair that scopes `ProductsController` to the subtree. It is placed at the `ProductsScreen` level, so both `ProductsScreen` and any screen pushed on top (like `CartScreen`) can access the same controller instance.

`CartController` is **not** created here — it lives in `Dependencies` (app-lifetime). `ShopScope` exposes a `cartControllerOf` static accessor that simply delegates to `Dependencies.of(context).cartController`.

### `ProductsController` (`features/shop/controller/products_controller.dart`)

Sealed states:
```
Products$IdleState
Products$LoadingState
Products$LoadedState(List<Product> products)
Products$ErrorState(String? message)
```

Single method: `void load({required String token})` — calls `IShopRepository.getProducts`, transitions through loading → loaded or error.

Uses `SequentialControllerHandler` so only one load runs at a time. Pull-to-refresh and the Retry button both call `load` again safely.

### `IShopRepository` (`features/shop/data/shop_repository.dart`)

Contains only `getProducts`. The `checkout` method was deliberately removed from this interface — it belongs to the cart feature, not the shop feature.

```dart
abstract interface class IShopRepository {
  Future<List<Product>> getProducts({required String token});
}
```

### `ProductsScreen`

- Wraps `_ProductsBody` in `ShopScope`
- `GridView.builder` — 2 columns, `childAspectRatio: 0.75`
- Cart icon in `AppBar` shows a red badge with item count when the cart is non-empty
- Pull-to-refresh reloads products
- Error state shows a Retry button
- "Add to Cart" / "Added" button on each product card — visual feedback when product is already in cart

---

## 11. Cart feature — separate from shop

The cart lives in its own feature folder `lib/src/features/cart/`, completely independent from the shop feature.

```
features/cart/
  models/cart_item.dart
  controller/cart_controller.dart
  data/cart_repository.dart
  widgets/cart_screen.dart
```

### Why separate from shop?

The shop feature is about browsing — loading and displaying products. The cart feature is about the purchase lifecycle — state, quantities, checkout, payment. Keeping them in separate folders means they can evolve independently and their responsibilities are clear.

### `CartItem` (`features/cart/models/cart_item.dart`)

```dart
@immutable
class CartItem {
  final Product product;
  final int quantity;
  double get subtotal => product.price * quantity;
}
```

Equality is based on `product` only (not quantity) — this is intentional so that `indexWhere` lookups in the controller find the item regardless of its current quantity.

### `CartController` (`features/cart/controller/cart_controller.dart`)

Lives in `Dependencies` at **app-lifetime** — created during initialization and never disposed until the app exits. This means the cart survives navigation: adding items on `ProductsScreen`, opening `CartScreen`, going back, navigating around — the cart is never reset by widget lifecycle.

`CartState`:
```dart
class CartState {
  final List<CartItem> items;
  final bool isCheckingOut;
  int get totalInCents     // sum of price * quantity * 100
  int get itemCount        // total number of individual items
  bool get isEmpty
  String get formattedTotal  // e.g. "$12.50"
}
```

Methods:
- `add(product)` — adds one, or increments quantity if already in cart
- `increment(product)` — alias for `add`
- `decrement(product)` — decrements, removes item when quantity reaches 0
- `remove(product)` — removes regardless of quantity
- `clear()` — resets to empty state (called after successful payment)
- `checkout(token, repository)` — sets `isCheckingOut=true`, calls `ICartRepository.checkout`, returns `PaymentIntent`

Uses `SequentialControllerHandler` — only one operation runs at a time (prevents double-tapping checkout).

### `ICartRepository` (`features/cart/data/cart_repository.dart`)

```dart
abstract interface class ICartRepository {
  Future<PaymentIntent> checkout({
    required List<CartItem> items,
    required String token,
  });
}
```

`CartRepositoryImpl` sends `POST /api/orders/checkout` with:
```json
{ "items": [{ "product_id": 1, "quantity": 2 }, ...] }
```

The server calculates the total — the client **never sends an amount**. The response is the same JSON shape as Stripe's own PaymentIntent API, so `PaymentIntent.fromMap` works unchanged.

### `CartScreen` (`features/cart/widgets/cart_screen.dart`)

- Gets `CartController` from `Dependencies.of(context).cartController`
- Gets `ICartRepository` from `Dependencies.of(context).cartRepository`
- Uses `ListenableBuilder` on the controller — rebuilds automatically when cart state changes
- `PopScope(canPop: !isCheckingOut)` — prevents back navigation during checkout
- On successful payment: calls `cartController.clear()` then shows a success dialog, then pops back to products

---

## 12. Dependencies and initialization

`Dependencies` is the app-level DI container. New fields added:

```dart
late final IShopRepository shopRepository;
late final ICartRepository cartRepository;
late final CartController cartController;
```

Initialization order in `initialize_dependencies.dart`:
```
'Prepare shop repository'  → ShopRepositoryImpl(baseUrl)
'Prepare cart repository'  → CartRepositoryImpl(baseUrl)
'Prepare cart controller'  → CartController()
```

`CartController` is initialized after its repository so it is ready to use immediately.

### Why `CartController` in `Dependencies` and not in `ShopScope`?

`ShopScope` is a widget-scoped object — it is created when `ProductsScreen` mounts and disposed when it unmounts. If the user navigates away and back, a new `ShopScope` would create a new `CartController`, losing the cart contents.

Placing `CartController` in `Dependencies` (initialized once at app startup) ensures the cart state persists for the entire app session regardless of navigation.

---

## 13. `payment_repository.dart` vs `cart_repository.dart`

These two repositories handle Stripe payments but serve completely different purposes:

| | `payment_repository.dart` | `cart_repository.dart` |
|---|---|---|
| Purpose | Standalone "Quick Pay" screen | Cart checkout with server-side order |
| Endpoint | `POST /api/create-payment` or Stripe directly | `POST /api/orders/checkout` |
| Amount | Client sends the amount | Server calculates from product prices |
| Order created | No | Yes (idempotent — reuses pending order) |
| Who calls it | `PaymentController` / `PaymentScreen` | `CartController` / `CartScreen` |

`payment_repository.dart` exists for the original one-off payment demo and has two implementations (`PaymentRepositoryImpl` for direct-to-Stripe in dev, `BackendPaymentRepositoryImpl` for the backend). For any real e-commerce flow, use `cart_repository.dart`.

