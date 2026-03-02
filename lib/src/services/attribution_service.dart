import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/attribution_api_client.dart';
import '../models/afflicate_config.dart';
import '../models/attribution_result.dart';
import '../platform/afflicate_platform_interface.dart';
import '../platform/afflicate_platform_impl.dart';
import '../utils/attribution_storage.dart';
import '../utils/sdk_logger.dart';
import 'signal_collector.dart';

/// Orchestrates init flow: cache check → collect signals → POST → cache on success.
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

  /// Call from the app with the launch URL (e.g. from [Linking.getInitialURL]).
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
    _log.enabled = false;
    if (platform != null) {
      _platform = platform;
    } else {
      _platform = AfflicatePlatformImpl();
    }
  }

  /// Idempotent init: cache first, then signals + POST if no cache.
  static Future<void> init(final AfflicateConfig config) async {
    _log.enabled = config.debug;

    if (_initialized) {
      _log.log('Already initialized, skipping');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = loadAttribution(prefs);
    if (cached != null) {
      _cachedResult = cached;
      _initialized = true;
      _log.log('Using cached attribution: ${cached.affiliateCode}');
      return;
    }

    final signals = await _collectSignals(config);
    try {
      final client = AttributionApiClient(config);
      final result = await client.attribute(signals);
      _cachedResult = result;
      await saveAttribution(prefs, result);
      _initialized = true;
      _log.log(
        'Attribution: ${result.attributed ? result.affiliateCode : "not attributed"}',
      );
    } on Exception catch (e) {
      _log.log('Attribution failed: $e');
      _cachedResult = AttributionResult.notAttributed();
      _initialized = true;
      // Do not cache failure; next app open will retry.
    }
  }

  /// Returns cached result. Call after [init]. If not initialized, returns notAttributed.
  static AttributionResult getAttribution() {
    if (_cachedResult != null) return _cachedResult!;
    _log.log('Warning: getAttribution() called before init()');
    return AttributionResult.notAttributed();
  }

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
      'click_id_from_url': clickIdFromUrl,
      'click_id_from_clipboard': clickIdFromClipboard,
      'click_id_from_referrer': clickIdFromReferrer,
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

  static String? _parseClickIdFromUrl(final String urlString) {
    try {
      final uri = Uri.parse(urlString);
      return uri.queryParameters['click_id'];
    } catch (_) {
      return null;
    }
  }
}
