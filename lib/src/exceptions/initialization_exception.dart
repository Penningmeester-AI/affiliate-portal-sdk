import 'afflicate_exception.dart';

/// Thrown when the SDK is used before [Afflicate.init] or when cache is missing.
class InitializationException extends AfflicateException {
  /// Creates an initialization exception with [message] and optional [cause].
  const InitializationException(super.message, [super.cause]);
}
