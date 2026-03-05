import 'package:http/http.dart' as http;

/// Configuration for [Afflicate.init].
///
/// [publicKey] identifies the company (e.g. "pk_live_xxx").
/// [appId] is the bundle ID (iOS) or package name (Android).
/// [consentGiven] when false skips fingerprinting (GDPR).
/// [debug] enables internal logging. Off by default.
///
/// Optional [baseUrl] defaults to the Afflicate tracking endpoint.
/// [httpClient] is for testing only.
class AfflicateConfig {
  /// Creates config for the attribution SDK.
  AfflicateConfig({
    required this.publicKey,
    required this.appId,
    this.consentGiven = true,
    this.debug = false,
    this.baseUrl = _defaultBaseUrl,
    this.timeout = const Duration(seconds: 10),
    final http.Client? httpClient,
  }) : _httpClient = httpClient;

  static const String _defaultBaseUrl = 'https://track.affiliate-portal.app';

  /// Public key identifying the company (e.g. "pk_live_xxx").
  final String publicKey;

  /// Bundle ID (iOS) or package name (Android).
  final String appId;

  /// When false, fingerprint signals are not sent (GDPR).
  final bool consentGiven;

  /// When true, enables internal debug logging.
  final bool debug;

  /// Attribution API base URL. Defaults to [_defaultBaseUrl].
  final String baseUrl;

  /// Request timeout. Default 10 seconds per spec.
  final Duration timeout;

  final http.Client? _httpClient;

  /// HTTP client to use. Internal; for tests inject via constructor.
  http.Client get httpClient => _httpClient ?? http.Client();
}
