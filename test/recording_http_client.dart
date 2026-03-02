import 'dart:async';

import 'package:http/http.dart' as http;

/// Fake [http.Client] that records call count and last request body for tests.
class RecordingFakeHttpClient extends http.BaseClient {
  RecordingFakeHttpClient({
    this.getResponse,
    this.getException,
  });

  final http.Response? getResponse;
  final Exception? getException;

  int callCount = 0;
  String? lastRequestBody;

  @override
  Future<http.StreamedResponse> send(final http.BaseRequest request) async {
    callCount++;
    if (request is http.Request && request.body.isNotEmpty) {
      lastRequestBody = request.body;
    }
    if (getException != null) throw getException!;
    if (getResponse != null) {
      return http.StreamedResponse(
        Stream.value(getResponse!.bodyBytes),
        getResponse!.statusCode,
        headers: getResponse!.headers,
      );
    }
    return http.StreamedResponse(
      const Stream.empty(),
      404,
    );
  }
}
