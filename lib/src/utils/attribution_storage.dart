import 'package:shared_preferences/shared_preferences.dart';

import '../models/attribution_result.dart';

const String _keyAttributed = 'afflicate_attributed';
const String _keyAffiliateCode = 'afflicate_affiliate_code';
const String _keyAffiliateCodeId = 'afflicate_affiliate_code_id';
const String _keyMatchMethod = 'afflicate_match_method';
const String _keyMatchConfidence = 'afflicate_match_confidence';

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
