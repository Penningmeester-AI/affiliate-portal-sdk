import 'package:flutter/services.dart';

import 'afflicate_platform_interface.dart';

const MethodChannel _channel = MethodChannel('com.afflicate.sdk/attribution');

/// Default platform implementation. Launch URL and referrer via method channel;
/// clipboard read in Dart.
class AfflicatePlatformImpl implements AfflicatePlatformInterface {
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  Future<String?> getClickIdFromLaunchUrl() async {
    try {
      final result = await _channel.invokeMethod<String>('getClickIdFromLaunchUrl');
      return result;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<String?> getClickIdFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && text.isNotEmpty && _uuidRegex.hasMatch(text)) {
        await Clipboard.setData(const ClipboardData(text: ''));
        return text;
      }
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<String?> getClickIdFromReferrer() async {
    try {
      final result =
          await _channel.invokeMethod<String>('getClickIdFromReferrer');
      return result;
    } on PlatformException {
      return null;
    }
  }
}
