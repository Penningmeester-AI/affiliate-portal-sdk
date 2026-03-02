import 'package:flutter/foundation.dart' show visibleForTesting;

import 'models/afflicate_config.dart';
import 'models/attribution_result.dart';
import 'platform/afflicate_platform_interface.dart';
import 'services/attribution_service.dart';

/// Public static API for the Afflicate attribution SDK.
///
/// Call [init] once at app startup (before runApp), then use [getAttribution]
/// to read the cached result. [init] is idempotent and thread-safe.
abstract final class Afflicate {
  Afflicate._();

  /// Initializes the SDK and attempts attribution.
  ///
  /// Idempotent: safe to call multiple times. First call loads from cache or
  /// collects signals and calls the backend; subsequent calls return immediately.
  ///
  /// On network/API failure, does not cache; next app open will retry.
  static Future<void> init(final AfflicateConfig config) async {
    await AttributionService.init(config);
  }

  /// Returns the cached attribution result.
  ///
  /// Call after [init]. Returns the result from the first successful init,
  /// or [AttributionResult.notAttributed] if not initialized or attribution failed.
  static AttributionResult getAttribution() {
    return AttributionService.getAttribution();
  }

  /// Pass the app launch URL (e.g. from app_links [AppLinks.getInitialLink])
  /// so the SDK can extract [click_id] for attribution. Call before [init].
  static void setLaunchUrl(final String? url) {
    AttributionService.setLaunchUrl(url);
  }

  /// Resets SDK state. For testing only. Pass [platform] to inject a mock.
  @visibleForTesting
  static void resetForTesting({final AfflicatePlatformInterface? platform}) {
    AttributionService.reset(platform: platform);
  }
}
