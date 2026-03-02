import 'package:shared_preferences/shared_preferences.dart';

import '../models/attribution_result.dart';

const String _keyAttributed = 'afflicate_attributed';
const String _keyAffiliateCode = 'afflicate_affiliate_code';
const String _keyAffiliateCodeId = 'afflicate_affiliate_code_id';
const String _keyMatchMethod = 'afflicate_match_method';
const String _keyMatchConfidence = 'afflicate_match_confidence';

/// Key for permanently caching 401 invalid key (per spec: avoid infinite retries).
const String key401Cached = 'afflicate_401_cached';

/// Persists [AttributionResult] using SharedPreferences. No JSON; key-value only.
Future<void> saveAttribution(
  final SharedPreferences prefs,
  final AttributionResult result,
) async {
  await prefs.setBool(_keyAttributed, result.attributed);
  await prefs.setString(_keyAffiliateCode, result.affiliateCode ?? '');
  await prefs.setInt(_keyAffiliateCodeId, result.affiliateCodeId ?? -1);
  await prefs.setString(_keyMatchMethod, result.matchMethod ?? '');
  await prefs.setInt(_keyMatchConfidence, result.matchConfidence ?? -1);
}

/// Returns true if a 401 was previously cached (invalid key); do not retry API.
bool load401Cached(final SharedPreferences prefs) {
  return prefs.getBool(key401Cached) == true;
}

/// Saves that 401 was received; cache permanently per spec.
Future<void> save401Cached(final SharedPreferences prefs) async {
  await prefs.setBool(key401Cached, true);
}

/// Clears 401 cached flag (e.g. for tests).
Future<void> clear401Cached(final SharedPreferences prefs) async {
  await prefs.remove(key401Cached);
}

/// Loads attribution from preferences. Returns null if never saved.
AttributionResult? loadAttribution(final SharedPreferences prefs) {
  final attributed = prefs.getBool(_keyAttributed);
  if (attributed == null) return null;
  final code = prefs.getString(_keyAffiliateCode);
  final codeId = prefs.getInt(_keyAffiliateCodeId);
  final method = prefs.getString(_keyMatchMethod);
  final confidence = prefs.getInt(_keyMatchConfidence);
  return AttributionResult(
    attributed: attributed,
    affiliateCode: (code != null && code.isNotEmpty) ? code : null,
    affiliateCodeId: (codeId != null && codeId >= 0) ? codeId : null,
    matchMethod: (method != null && method.isNotEmpty) ? method : null,
    matchConfidence: (confidence != null && confidence >= 0) ? confidence : null,
  );
}
