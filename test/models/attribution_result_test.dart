import 'package:affiliate_portal_sdk/afflicate_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttributionResult', () {
    test('equality by props', () {
      const r1 = AttributionResult(
        attributed: true,
        affiliateCode: 'AFF-1',
        affiliateCodeId: 1,
      );
      const r2 = AttributionResult(
        attributed: true,
        affiliateCode: 'AFF-1',
        affiliateCodeId: 1,
      );
      const r3 = AttributionResult(
        attributed: true,
        affiliateCode: 'AFF-2',
        affiliateCodeId: 1,
      );
      expect(r1, equals(r2));
      expect(r1, isNot(equals(r3)));
    });

    test('notAttributed() has attributed false', () {
      final r = AttributionResult.notAttributed();
      expect(r.attributed, isFalse);
      expect(r.affiliateCode, isNull);
      expect(r.matchMethod, isNull);
    });
  });
}
