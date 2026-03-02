import 'package:affiliate_portal_sdk/afflicate_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_http_client.dart';
import 'mock_platform.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Afflicate.resetForTesting(platform: MockAfflicatePlatform());
  });

  group('Afflicate.init', () {
    test('succeeds with 200 and caches attribution', () async {
      await Afflicate.init(AfflicateConfig(
        publicKey: 'pk_test',
        appId: 'com.test.app',
        consentGiven: false,
        baseUrl: 'https://api.test.com',
        httpClient: FakeHttpClient(
          getResponse: http.Response(
            '{"attributed":true,"affiliate_code":"AFF-X","affiliate_code_id":1,'
            '"match_method":"clipboard","match_confidence":95}',
            200,
          ),
        ),
      ));

      final result = Afflicate.getAttribution();
      expect(result.attributed, isTrue);
      expect(result.affiliateCode, 'AFF-X');
      expect(result.matchMethod, 'clipboard');
      expect(result.matchConfidence, 95);
    });

    test('on 401 completes and getAttribution returns notAttributed', () async {
      await Afflicate.init(AfflicateConfig(
        publicKey: 'pk_test',
        appId: 'com.test.app',
        consentGiven: false,
        baseUrl: 'https://api.test.com',
        httpClient: FakeHttpClient(getResponse: http.Response('', 401)),
      ));
      final result = Afflicate.getAttribution();
      expect(result.attributed, isFalse);
      expect(result.affiliateCode, isNull);
    });

    test('on 500 completes and getAttribution returns notAttributed', () async {
      await Afflicate.init(AfflicateConfig(
        publicKey: 'pk_test',
        appId: 'com.test.app',
        consentGiven: false,
        baseUrl: 'https://api.test.com',
        httpClient: FakeHttpClient(getResponse: http.Response('', 500)),
      ));
      final result = Afflicate.getAttribution();
      expect(result.attributed, isFalse);
    });

    test('on client throw completes and getAttribution returns notAttributed',
        () async {
      await Afflicate.init(AfflicateConfig(
        publicKey: 'pk_test',
        appId: 'com.test.app',
        consentGiven: false,
        baseUrl: 'https://api.test.com',
        httpClient: FakeHttpClient(
          getException: Exception('connection failed'),
        ),
      ));
      final result = Afflicate.getAttribution();
      expect(result.attributed, isFalse);
    });

    test('is idempotent - second call does not throw', () async {
      await Afflicate.init(AfflicateConfig(
        publicKey: 'pk_test',
        appId: 'com.test.app',
        consentGiven: false,
        baseUrl: 'https://api.test.com',
        httpClient: FakeHttpClient(
          getResponse: http.Response(
            '{"attributed":true,"affiliate_code":"first","affiliate_code_id":1,'
            '"match_method":"url","match_confidence":100}',
            200,
          ),
        ),
      ));

      await Afflicate.init(AfflicateConfig(
        publicKey: 'pk_other',
        appId: 'com.other.app',
        consentGiven: false,
        baseUrl: 'https://other.com',
        httpClient: FakeHttpClient(getResponse: http.Response('', 500)),
      ));

      final result = Afflicate.getAttribution();
      expect(result.affiliateCode, 'first');
    });
  });

  group('Afflicate.getAttribution', () {
    test('returns notAttributed when init was not called', () {
      final result = Afflicate.getAttribution();
      expect(result.attributed, isFalse);
      expect(result.affiliateCode, isNull);
    });

    test('returns cached attribution after init', () async {
      await Afflicate.init(AfflicateConfig(
        publicKey: 'pk_test',
        appId: 'com.test.app',
        consentGiven: false,
        baseUrl: 'https://api.test.com',
        httpClient: FakeHttpClient(
          getResponse: http.Response(
            '{"attributed":true,"affiliate_code":"x","affiliate_code_id":2,'
            '"match_method":"fingerprint","match_confidence":80}',
            200,
          ),
        ),
      ));

      final a1 = Afflicate.getAttribution();
      final a2 = Afflicate.getAttribution();
      expect(a1.affiliateCode, a2.affiliateCode);
      expect(a1.affiliateCode, 'x');
    });
  });
}
