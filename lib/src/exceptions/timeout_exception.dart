import 'afflicate_exception.dart';

/// Thrown when a request times out.
class TimeoutException extends AfflicateException {
  /// Creates a timeout exception with [message] and optional [cause].
  const TimeoutException(super.message, [super.cause]);
}
