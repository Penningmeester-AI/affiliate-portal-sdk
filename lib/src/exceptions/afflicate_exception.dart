/// Base exception for all Afflicate SDK errors.
///
/// Never throw generic [Exception]. Use [AfflicateException] or its subtypes.
abstract class AfflicateException implements Exception {
  /// Creates an Afflicate exception with [message] and optional [cause].
  const AfflicateException(this.message, [this.cause]);

  /// Human-readable error message.
  final String message;

  /// Optional underlying cause (e.g. [FormatException], [SocketException]).
  final Object? cause;

  @override
  String toString() => cause != null ? '$message ($cause)' : message;
}
