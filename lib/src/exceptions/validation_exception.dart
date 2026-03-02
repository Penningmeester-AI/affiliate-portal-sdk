import 'afflicate_exception.dart';

/// Thrown when the API returns 400 Bad Request (e.g. validation error).
class ValidationException extends AfflicateException {
  /// Creates a validation exception with [message] and optional [cause].
  const ValidationException(super.message, [super.cause]);
}
