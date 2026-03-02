# Afflicate Attribution SDK for Flutter

Production-ready Flutter SDK for affiliate attribution. Determines which affiliate referred the user by collecting click_id (URL, clipboard, Android referrer) and optional fingerprint signals, then calling the Afflicate backend.

## Features

- **Static API**: `Afflicate.init(config)` and `Afflicate.getAttribution()`
- **Idempotent init**: Safe to call multiple times; first call fetches and caches, later calls return immediately
- **Attribution result**: `attributed`, `affiliateCode`, `affiliateCodeId`, `matchMethod`, `matchConfidence`
- **Config**: `publicKey`, `appId`, `consentGiven` (GDPR), `debug`
- **Launch URL**: Call `Afflicate.setLaunchUrl(url)` before init with e.g. `Linking.getInitialURL()` for Universal/App Links
- **Resilient**: On API failure (network, 401, timeout), init completes and `getAttribution()` returns not attributed; no throw

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  affiliate_portal_sdk:
    path: ../path/to/affiliate-portal-sdk-flutter  # or git / pub.dev
```

Then:

```bash
flutter pub get
```

## Initialization

Call `Afflicate.init` once at app startup, before `runApp`:

```dart
import 'package:affiliate_portal_sdk/afflicate_sdk.dart';
// Optional: import 'package:flutter/services.dart' show Linking;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Optional: pass launch URL so SDK can extract click_id
  // Afflicate.setLaunchUrl(await Linking.getInitialURL());
  await Afflicate.init(AfflicateConfig(
    publicKey: 'pk_live_xxx',
    appId: 'com.yourcompany.app',  // bundle ID (iOS) or package name (Android)
    consentGiven: true,            // false = skip fingerprinting (GDPR)
    debug: kDebugMode,
  ));
  runApp(MyApp());
}
```

## Usage

After initialization, get the cached attribution (sync):

```dart
final result = Afflicate.getAttribution();
if (result.attributed && result.affiliateCode != null) {
  // Send affiliateCode to your backend at signup
  await yourBackend.registerUser(userId, affiliateCode: result.affiliateCode);
}
// result.matchMethod: "deterministic_url", "clipboard", "fingerprint", etc.
// result.matchConfidence: 0-100
```

## Error handling

`init()` does not throw on API failure: it logs and sets the result to not attributed. Use `getAttribution().attributed` to check. For debugging, enable `debug: true` to see logs.

## Project layout

- `lib/afflicate_sdk.dart` — public exports; import this in your app
- `lib/src/api/` — POST /sdk/attribution client
- `lib/src/services/` — init flow, signal collection, storage
- `lib/src/models/` — `AttributionResult`, `AfflicateConfig`
- `lib/src/platform/` — method channel (launch URL, referrer); clipboard in Dart
- `android/` — plugin: Install Referrer, launch intent
- `ios/` — plugin: launch URL (app can pass via setLaunchUrl)

## Development

- **Tests**: `flutter test`
- **Example**: `cd example && flutter run`
- **Lint**: `flutter analyze`

## Versioning

This package follows [Semantic Versioning](https://semver.org/).
