import 'package:affiliate_portal_sdk/afflicate_sdk.dart';

/// Mock platform for tests. Returns null for all click_id sources.
class MockAfflicatePlatform implements AfflicatePlatformInterface {
  @override
  Future<String?> getClickIdFromLaunchUrl() async => null;

  @override
  Future<String?> getClickIdFromClipboard() async => null;

  @override
  Future<String?> getClickIdFromReferrer() async => null;
}
