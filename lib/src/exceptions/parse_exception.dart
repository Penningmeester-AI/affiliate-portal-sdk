import 'afflicate_exception.dart';

/// Thrown when the API response or stored data cannot be parsed.
class AfflicateParseException extends AfflicateException {
  /// Creates a parse exception with [message] and optional [cause].
  const AfflicateParseException(super.message, [super.cause]);
}
