import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/attribution_api_client.dart';
import '../exceptions/authentication_exception.dart';
import '../models/afflicate_config.dart';
import '../models/attribution_result.dart';
import '../platform/afflicate_platform_interface.dart';
import '../platform/afflicate_platform_impl.dart';
import '../utils/attribution_storage.dart';
import '../utils/sdk_logger.dart';
import 'signal_collector.dart';

/// UUID regex for validating click_id before sending to API (safety net).
final RegExp _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Orchestrates init flow: cache check → collect signals → POST → cache only when attributed.
class AttributionService {
  AttributionService._();

  static AttributionService? _instance;
  static AttributionService get instance =>
      _instance ??= AttributionService._();

  static bool _initialized = false;
  static AttributionResult? _cachedResult;
  static String? _launchUrlOverride;
  static AfflicatePlatformInterface _platform = AfflicatePlatformImpl();
  static final SdkLogger _log = SdkLogger();
  static Completer<void>? _initCompleter;

  /// Call from the app with the launch URL (e.g. from app_links getInitialLink).
  /// Used to extract click_id when native did not provide it (e.g. iOS).
  static void setLaunchUrl(final String? url) {
    _launchUrlOverride = url;
  }

  /// For tests: inject platform and reset state.
  static void reset({final AfflicatePlatformInterface? platform}) {
    _instance = null;
    _initialized = false;
    _cachedResult = null;
    _launchUrlOverride = null;
    _initCompleter = null;
    _log.enabled = false;
    if (platform != null) {
      _platform = platform;
    } else {
      _platform = AfflicatePlatformImpl();
    }
  }

  /// Idempotent init. Single-flight: concurrent calls await the same run.
  /// Cache: only when attributed=true; 401 cached permanently per spec.
  static Future<void> init(final AfflicateConfig config) async {
    _log.enabled = config.debug;

    if (_initialized) {
      _log.log('Already initialized, skipping');
      return;
    }
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }
    _initCompleter = Completer<void>();
    try {
      await _initOnce(config);
    } finally {
      _initCompleter!.complete();
      _initCompleter = null;
    }
  }

  static Future<void> _initOnce(final AfflicateConfig config) async {
    final prefs = await SharedPreferences.getInstance();

    if (load401Cached(prefs)) {
      _cachedResult = AttributionResult.notAttributed();
      _initialized = true;
      _log.log('401 previously cached, skipping API (invalid key)');
      return;
    }

    final cached = loadAttribution(prefs);
    if (cached != null) {
      _cachedResult = cached;
      _initialized = true;
      _log.log('Using cached attribution: ${cached.affiliateCode}');
      return;
    }

    final signals = await _collectSignals(config);
    final url = signals['click_id_from_url'];
    final clipboard = signals['click_id_from_clipboard'];
    final referrer = signals['click_id_from_referrer'];
    _log.log(
      'Collected click_id_from_url: ${url ?? "null"}, '
      'click_id_from_clipboard: ${clipboard ?? "null"}, '
      'click_id_from_referrer: ${referrer ?? "null"}',
    );
    try {
      _log.log('Sending attribution request...');
      final client = AttributionApiClient(config);
      final result = await client.attribute(signals);
      _cachedResult = result;
      if (result.attributed) {
        await saveAttribution(prefs, result);
      }
      _initialized = true;
      _log.log(
        'Attribution result: attributed=${result.attributed}'
        '${result.affiliateCode != null ? ", affiliateCode=${result.affiliateCode}" : ""}',
      );
    } on AuthenticationException catch (_) {
      _log.log('401 Unauthorized, caching to avoid retries');
      await save401Cached(prefs);
      _cachedResult = AttributionResult.notAttributed();
      _initialized = true;
    } on Exception catch (e) {
      _log.log('Attribution failed: $e');
      _cachedResult = AttributionResult.notAttributed();
      _initialized = true;
    }
  }

  /// Returns cached result. Call after [init]. If not initialized, returns notAttributed.
  static AttributionResult getAttribution() {
    if (_cachedResult != null) return _cachedResult!;
    _log.log('Warning: getAttribution() called before init()');
    return AttributionResult.notAttributed();
  }

  /// Collects signals. GDPR: fingerprint only when [config.consentGiven].
  /// Deterministic signals (click_id, app_id) always sent.
  static Future<Map<String, Object?>> _collectSignals(
    final AfflicateConfig config,
  ) async {
    String? clickIdFromUrl = await _platform.getClickIdFromLaunchUrl();
    if (clickIdFromUrl == null && _launchUrlOverride != null) {
      clickIdFromUrl = _parseClickIdFromUrl(_launchUrlOverride!);
    }
    final clickIdFromClipboard = await _platform.getClickIdFromClipboard();
    final clickIdFromReferrer = await _platform.getClickIdFromReferrer();

    final signals = <String, Object?>{
      'app_id': config.appId,
      'click_id_from_url': _validClickIdOrNull(clickIdFromUrl),
      'click_id_from_clipboard': _validClickIdOrNull(clickIdFromClipboard),
      'click_id_from_referrer': _validClickIdOrNull(clickIdFromReferrer),
      'consent_given': config.consentGiven,
      'is_test': kDebugMode,
    };

    if (config.consentGiven) {
      final fingerprint = await SignalCollector.collect();
      for (final e in fingerprint.entries) {
        signals[e.key] = e.value;
      }
    }

    return signals;
  }

  static String? _validClickIdOrNull(final String? value) {
    if (value == null || value.isEmpty) return null;
    return _uuidRegex.hasMatch(value) ? value : null;
  }

  static String? _parseClickIdFromUrl(final String urlString) {
    try {
      final uri = Uri.parse(urlString);
      final id = uri.queryParameters['click_id'];
      return _validClickIdOrNull(id);
    } catch (_) {
      return null;
    }
  }
}
