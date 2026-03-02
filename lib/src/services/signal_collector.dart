import 'dart:io' show Platform;

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:package_info_plus/package_info_plus.dart';

/// Collects device fingerprint signals. No PII; used for attribution matching.
class SignalCollector {
  SignalCollector._();

  static const String sdkVersion = '1.0.0';

  /// Collects fingerprint signals. Call only when [consentGiven] is true.
  static Future<Map<String, Object?>> collect() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final size = WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
        ? WidgetsBinding.instance.platformDispatcher.views.first.physicalSize
        : null;
    final ratio = WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
        ? WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio
        : 1.0;
    final width = size != null ? (size.width / ratio).round() : 0;
    final height = size != null ? (size.height / ratio).round() : 0;
    final screenResolution = '${width}x$height';

    return <String, Object?>{
      'platform': Platform.isIOS ? 'ios' : 'android',
      'os_version': Platform.operatingSystemVersion,
      'app_version': packageInfo.version,
      'sdk_version': sdkVersion,
      'screen_resolution': screenResolution,
      'language': Platform.localeName,
      'timezone': DateTime.now().timeZoneName,
    };
  }
}
