import 'dart:async';

import 'package:http/http.dart' as http;

/// Fake [http.Client] for tests. Returns predefined responses.
class FakeHttpClient extends http.BaseClient {
  FakeHttpClient({
    this.getResponse,
    this.getException,
  });

  final http.Response? getResponse;
  final Exception? getException;

  @override
  Future<http.StreamedResponse> send(final http.BaseRequest request) async {
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
