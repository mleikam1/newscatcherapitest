import 'api_client.dart';

class NewsService {
  final ApiClient _client;
  NewsService(this._client);

  // Worker API paths.
  // If your worker path differs, adjust the path constants here only.
  static const String _home = "/home";
  static const String _search = "/search";

  void _requireNonEmpty(String field, String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError("$field is required.");
    }
  }

  ApiResponse _requireArticles(ApiResponse response) {
    final json = response.json;
    if (json == null || !json.containsKey("articles")) {
      print("API response missing articles: ${response.rawBody}");
      return ApiResponse(
        status: response.status,
        json: const {"articles": <dynamic>[]},
        rawBody: response.rawBody,
      );
    }
    return response;
  }

  Future<ApiResponse> search({
    required String q,
  }) {
    _requireNonEmpty("q", q);
    final query = <String, String>{
      "q": q,
    };
    return _client
        .get(
          isNews: true,
          path: _search,
          endpointName: "news.search",
          query: query,
        )
        .then(_requireArticles);
  }

  Future<ApiResponse> latestHeadlines() {
    return _client
        .get(
          isNews: true,
          path: _home,
          endpointName: "news.home",
        )
        .then(_requireArticles);
  }
}
