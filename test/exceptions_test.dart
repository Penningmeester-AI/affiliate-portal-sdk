import 'package:affiliate_portal_sdk/afflicate_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AfflicateException', () {
    test('toString without cause', () {
      const e = NetworkException('msg');
      expect(e.toString(), 'msg');
    });

    test('toString with cause', () {
      const e = NetworkException('msg', 'cause');
      expect(e.toString(), contains('msg'));
      expect(e.toString(), contains('cause'));
    });
  });

  group('subtypes', () {
    test('NetworkException is AfflicateException', () {
      const e = NetworkException('n');
      expect(e, isA<AfflicateException>());
    });

    test('AuthenticationException is AfflicateException', () {
      const e = AuthenticationException('a');
      expect(e, isA<AfflicateException>());
    });

    test('TimeoutException is AfflicateException', () {
      const e = TimeoutException('t');
      expect(e, isA<AfflicateException>());
    });

    test('InitializationException is AfflicateException', () {
      const e = InitializationException('i');
      expect(e, isA<AfflicateException>());
    });

    test('ValidationException is AfflicateException', () {
      const e = ValidationException('v');
      expect(e, isA<AfflicateException>());
    });
  });
}
