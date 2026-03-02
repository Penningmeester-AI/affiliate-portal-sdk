import 'package:equatable/equatable.dart';

/// Result of attribution from the backend.
///
/// [attributed] is true when an affiliate was matched.
/// [matchMethod] is e.g. "deterministic_url", "clipboard", "fingerprint".
/// [matchConfidence] is 0-100.
class AttributionResult extends Equatable {
  const AttributionResult({
    required this.attributed,
    this.affiliateCode,
    this.affiliateCodeId,
    this.matchMethod,
    this.matchConfidence,
  });

  /// Whether attribution succeeded.
  final bool attributed;

  /// The affiliate code (e.g. "AFF-XK92M7"), or null if not attributed.
  final String? affiliateCode;

  /// Backend affiliate code id, or null.
  final int? affiliateCodeId;

  /// How the match was made: "deterministic_url", "deterministic_referrer", "clipboard", "fingerprint".
  final String? matchMethod;

  /// Confidence 0-100, or null.
  final int? matchConfidence;

  /// Creates a result for "not attributed".
  static AttributionResult notAttributed() =>
      const AttributionResult(attributed: false);

  @override
  List<Object?> get props =>
      [attributed, affiliateCode, affiliateCodeId, matchMethod, matchConfidence];
}
