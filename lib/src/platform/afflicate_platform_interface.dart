/// Platform-specific attribution signals (click_id from URL, clipboard, referrer).
/// Implementations use method channels for native APIs.
abstract class AfflicatePlatformInterface {
  /// click_id from app launch URL (Universal Link / App Link). May be null.
  Future<String?> getClickIdFromLaunchUrl();

  /// click_id from clipboard if it looks like a UUID. Clears clipboard after read.
  Future<String?> getClickIdFromClipboard();

  /// click_id from Android Install Referrer. iOS returns null.
  Future<String?> getClickIdFromReferrer();
}
