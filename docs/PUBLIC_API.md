# Afflicate SDK — Public API Surface

## Overview
Single static class `Afflicate` with idempotent init and async getAttribution. All types are strongly typed; no dynamic or untyped Map in the public API.

## Public types (exported from `lib/afflicate_sdk.dart` only)

### Afflicate (static class)
- `static Future<void> init(AfflicateConfig config)` — Idempotent. Safe to call multiple times; subsequent calls return cached result without re-running attribution. Thread-safe.
- `static Future<Attribution?> getAttribution()` — Returns persisted attribution or fetches and caches. Returns null only if never initialized or no attribution available (use typed exceptions for errors).

### AfflicateConfig
- `String baseUrl` (required) — Attribution API base URL
- `String? apiKey` — Optional API key for auth
- `bool debug` — Enable internal logging (default: false)
- `Duration timeout` — Request timeout (default: 30s)

### Attribution (model, Equatable)
- Fields: e.g. `campaign`, `source`, `medium`, `term`, `content` (all String); plus `rawPayload` Map<String, String> if needed — or keep fully typed with explicit fields only
- `fromJson` / `toJson` in api layer only; model is plain fields + Equatable

### Exceptions (all extend AfflicateException)
- `AfflicateException` — base, message + optional cause
- `NetworkException` — e.g. no connection, DNS failure
- `AuthenticationException` — 401 from API
- `TimeoutException` — request timeout
- `InitializationException` — getAttribution before init or missing cache

## Usage example (for README)
```dart
await Afflicate.init(AfflicateConfig(
  baseUrl: 'https://api.example.com',
  debug: kDebugMode,
));
try {
  final attribution = await Afflicate.getAttribution();
} on AuthenticationException catch (e) { ... }
```

## Implementation notes
- JSON parsing only in `src/api/`. Models have explicit fields and `fromJson`/`toJson` called from api layer.
- Init: first call runs attribution (API + persist); later calls return immediately (cached).
- getAttribution: reads from cache first; if init ran, returns cached; otherwise may trigger fetch or return null depending on design (spec says "return cached result" for init; getAttribution returns the result).
