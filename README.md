# Afflicate Attribution SDK for Flutter

Production-ready Flutter SDK for affiliate attribution. Determines which affiliate referred the user and caches the result for use at signup.

---

## Quick Start (5 minutes)

### Step 1 – Install

Add to your app's `pubspec.yaml`:

```yaml
dependencies:
  affiliate_portal_sdk: ^1.0.0   # or path: ../affiliate-portal-sdk-flutter
```

Then run:

```bash
flutter pub get
```

### Step 2 – Initialize

In `main.dart`, before `runApp()`:

```dart
import 'package:affiliate_portal_sdk/afflicate_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Afflicate.init(
    AfflicateConfig(
      publicKey: 'pk_live_xxx',
      appId: 'com.company.app',
      consentGiven: true,
      debug: true,
    ),
  );

  runApp(MyApp());
}
```

Replace `pk_live_xxx` with your key from the Afflicate dashboard. Use your app's bundle ID (iOS) or package name (Android) for `appId`.

### Step 3 – Use at signup

When the user signs up, read the cached attribution and send the affiliate code to your backend:

```dart
final attribution = Afflicate.getAttribution();

if (attribution.attributed) {
  await yourBackend.registerUser(
    userId,
    affiliateCode: attribution.affiliateCode,
  );
}
```

That’s it. The SDK runs attribution once on first launch and caches the result.

---

## Configuration Reference

| Field | Required | Description |
|-------|----------|-------------|
| **publicKey** | Yes | From the Afflicate dashboard (e.g. `pk_live_xxx`). Identifies your company. |
| **appId** | Yes | Your app’s bundle ID (iOS) or package name (Android), e.g. `com.company.app`. |
| **consentGiven** | Yes | Required for GDPR. When `true`, fingerprint signals are sent. When `false`, only deterministic signals (click_id from URL, clipboard, referrer) are sent. |
| **debug** | No | When `true`, enables console logging and sets `is_test: true` in API requests. Default: `false`. |
| **baseUrl** | No | Attribution API base URL. Defaults to `https://track.afflicate.com`. |
| **timeout** | No | Request timeout. Default: 10 seconds. |

### What happens when `consentGiven = false`?

- Deterministic signals are still sent: `click_id` from URL, clipboard, and Android install referrer.
- Fingerprint signals are **not** sent: no `platform`, `os_version`, `screen_resolution`, `language`, `timezone`, `app_version`, `sdk_version`.
- Use this when the user has not given consent for non-essential data (GDPR).

---

## Platform Setup Requirements

### iOS

1. **Universal Links (for click_id from URL)**  
   - Add the **Associated Domains** capability in Xcode.  
   - Add your domain, e.g. `applinks:yourapp.com`.  
   - Implement `application(_:continue:restorationHandler:)` and pass the URL to the SDK (see below).

2. **Passing the launch URL to the SDK**  
   If the app opens via a Universal Link, pass the URL before `init()` so the SDK can read `click_id`. Use your deep-link package (e.g. [app_links](https://pub.dev/packages/app_links)):

   ```dart
   import 'package:app_links/app_links.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     final uri = await AppLinks().getInitialLink();
     Afflicate.setLaunchUrl(uri?.toString());
     await Afflicate.init(AfflicateConfig(...));
     runApp(MyApp());
   }
   ```

3. **iOS 16+ clipboard**  
   Reading the clipboard may show the system banner “App pasted from Safari”. This is expected. The SDK reads once, validates UUID format, and clears the clipboard after reading.

### Android

1. **Install Referrer**  
   The SDK uses `com.android.installreferrer:installreferrer`. It is declared in the plugin’s `android/build.gradle.kts`; no extra step in your app.

2. **Play Store**  
   Install referrer is provided by the Google Play Store when the app is installed from a store link that includes referrer parameters. It is not available for sideloaded or local installs.

3. **App Links (for click_id from URL)**  
   - Configure your domain for App Links (asset links / intent filters).  
   - In your launcher Activity, the SDK reads `intent.data` for the launch URI; ensure the Activity is started with that intent when opened via a link.

4. **Manifest**  
   No additional manifest entries are required beyond what the Flutter plugin adds.

---

## Attribution Behavior Explained

- **When attribution runs**  
  On the first call to `Afflicate.init()`. It collects signals (URL, clipboard, referrer, and optionally fingerprint), sends them to the backend, and stores the result.

- **Runs once**  
  Subsequent calls to `init()` are idempotent: they return immediately and do not call the API again.

- **Caching when attributed**  
  If the backend returns `attributed: true`, the result is cached locally. Future app launches use this cache and do not re-call the API.

- **Caching when not attributed**  
  If the backend returns `attributed: false`, the result is **not** cached. The next app launch will run attribution again (retry).

- **401 (invalid key) cached**  
  If the API returns 401, the SDK caches this failure and does not retry on later launches. Fix the `publicKey` and reinstall or clear app data to try again.

- **Other failures (network, timeout, 5xx)**  
  Not cached. The next app launch will retry attribution.

---

## Error Handling & Debugging

### Debug mode

Set `debug: true` in `AfflicateConfig`. The SDK will:

- Log initialization and cache hits.
- Log API response status and body.
- Send `is_test: true` in the request (so the backend can treat it as test traffic).

### Testing deterministic URL attribution

1. Configure Universal Links (iOS) or App Links (Android) with a URL that includes `click_id`, e.g.  
   `https://yourapp.com/open?click_id=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`  
   (use a valid UUID).
2. Open the app via that link.
3. For Flutter, pass the URL before init (e.g. `Afflicate.setLaunchUrl((await AppLinks().getInitialLink())?.toString())`).
4. Run the app and check `Afflicate.getAttribution()` (or the example app UI).

### Testing clipboard attribution

1. Copy a valid UUID to the clipboard (e.g. `550e8400-e29b-41d4-a716-446655440000`).
2. Open the app (cold start).
3. The SDK reads the clipboard once, validates UUID format, and clears it. Check attribution result in the app.

### Simulating network failure

Turn off the device network (or use a proxy) and launch the app. Attribution will fail; `getAttribution().attributed` will be `false`. On the next launch with network restored, attribution runs again (no cache on failure).

---

## Privacy & GDPR

### What signals are collected?

- **Always sent (deterministic):**  
  `app_id`, `click_id_from_url`, `click_id_from_clipboard`, `click_id_from_referrer`, `consent_given`, `is_test`.

- **Only when `consentGiven: true` (fingerprint):**  
  `platform`, `os_version`, `app_version`, `sdk_version`, `screen_resolution`, `language`, `timezone`.

- **IP address:**  
  Not explicitly collected by the SDK. The server may observe the client IP from the HTTP request.

### When does fingerprinting happen?

Only when you pass `consentGiven: true` in `AfflicateConfig`. If the user has not consented, set `consentGiven: false`; only deterministic signals are sent.

### What happens when `consentGiven = false`?

Only deterministic signals are sent. No `platform`, `os_version`, `screen_resolution`, `language`, `timezone`, `app_version`, or `sdk_version` are included in the request.

---

## Example App

A minimal working app is in the `example/` folder. It:

- Initializes the SDK in `main()`.
- Displays the attribution result on screen.
- Provides a **Simulate Signup** button that prints the affiliate code.

Run it:

```bash
cd example && flutter run
```

See [example/README.md](example/README.md) for test scenarios (URL, clipboard, consent off) and Android install referrer testing.

---

## Project Layout

| Path | Purpose |
|------|---------|
| `lib/afflicate_sdk.dart` | Public API; import this in your app. |
| `lib/src/api/` | HTTP client for `/sdk/attribution`. |
| `lib/src/services/` | Init flow, signal collection, storage. |
| `lib/src/models/` | `AttributionResult`, `AfflicateConfig`. |
| `lib/src/platform/` | Method channel (URL, referrer); clipboard in Dart. |
| `android/` | Plugin: Install Referrer, launch intent. |
| `ios/` | Plugin: launch URL handling. |
| `example/` | Minimal integration example. |

---

## Development

- **Tests:** `flutter test`
- **Lint:** `flutter analyze`
- **Example:** `cd example && flutter run`

---

## Versioning

This package follows [Semantic Versioning](https://semver.org/).
