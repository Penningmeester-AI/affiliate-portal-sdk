import 'afflicate_exception.dart';

/// Thrown when the API returns 401 Unauthorized.
class AuthenticationException extends AfflicateException {
  /// Creates an authentication exception with [message] and optional [cause].
  const AuthenticationException(super.message, [super.cause]);
}
