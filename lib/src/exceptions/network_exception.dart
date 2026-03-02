import 'afflicate_exception.dart';

/// Thrown when a network error occurs (e.g. no connection, DNS failure).
class NetworkException extends AfflicateException {
  /// Creates a network exception with [message] and optional [cause].
  const NetworkException(super.message, [super.cause]);
}
