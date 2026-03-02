import 'dart:async' as async;
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../exceptions/authentication_exception.dart';
import '../exceptions/network_exception.dart';
import '../exceptions/parse_exception.dart';
import '../exceptions/timeout_exception.dart';
import '../models/afflicate_config.dart';
import '../models/attribution_result.dart';

/// API client for attribution. POST /sdk/attribution with signals.
/// JSON decoding confined to this layer.
class AttributionApiClient {
  AttributionApiClient(this._config);

  final AfflicateConfig _config;

  /// POSTs signals to the attribution endpoint. Returns [AttributionResult].
  /// Throws [NetworkException], [AuthenticationException], [TimeoutException].
  Future<AttributionResult> attribute(
    final Map<String, Object?> signals,
  ) async {
    final uri = Uri.parse(_config.baseUrl).replace(
      path: '/sdk/attribution',
      queryParameters: <String, String>{'k': _config.publicKey},
    );
    http.Response response;
    try {
      response = await _config.httpClient
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(signals),
          )
          .timeout(_config.timeout);
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}', e);
    } on async.TimeoutException catch (e) {
      throw TimeoutException('Request timed out', e);
    } on Exception catch (e) {
      throw NetworkException('Request failed: $e', e);
    }

    if (response.statusCode == 401) {
      throw AuthenticationException(
        'Unauthorized (401). Check public key.',
        null,
      );
    }
    if (response.statusCode != 200) {
      throw NetworkException(
        'Attribution API returned ${response.statusCode}',
        null,
      );
    }

    return _parseResponse(response.body);
  }

  AttributionResult _parseResponse(final String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) {
      throw const AfflicateParseException(
        'Invalid attribution response: not an object',
      );
    }
    final map = decoded;
    final attributed = map['attributed'] == true;
    final code = map['affiliate_code'];
    final codeId = map['affiliate_code_id'];
    final method = map['match_method'];
    final confidence = map['match_confidence'];

    return AttributionResult(
      attributed: attributed,
      affiliateCode: code is String ? code : null,
      affiliateCodeId: codeId is int ? codeId : null,
      matchMethod: method is String ? method : null,
      matchConfidence: confidence is int ? confidence : null,
    );
  }
}
