/// Internal logger. No [print]. Logging only when [enabled] is true.
class SdkLogger {
  SdkLogger({this.enabled = false});

  bool enabled;

  void log(final String message) {
    if (enabled) {
      // ignore: avoid_print
      print('[Afflicate] $message');
    }
  }
}
