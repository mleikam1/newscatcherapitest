import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:newscatcher_poc/services/api_client.dart';
import 'package:newscatcher_poc/services/news_service.dart';

class RecordingClient extends http.BaseClient {
  Uri? lastUri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    final body = jsonEncode({"articles": []});
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable([utf8.encode(body)]),
      200,
      headers: {"content-type": "application/json"},
    );
  }
}

void main() {
  test('search uses countries and lang parameters', () async {
    final client = RecordingClient();
    final apiClient = ApiClient(httpClient: client);
    final news = NewsService(apiClient);

    await news.search(
      q: 'breaking news',
      countries: 'US',
      lang: 'en',
      page: 1,
      pageSize: 20,
    );

    final uri = client.lastUri;
    expect(uri, isNotNull);
    expect(uri!.queryParameters['countries'], 'US');
    expect(uri.queryParameters.containsKey('country'), isFalse);
    expect(uri.queryParameters['lang'], 'en');
  });
}
