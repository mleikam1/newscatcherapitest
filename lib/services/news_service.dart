import 'api_client.dart';

class NewsService {
  final ApiClient _client;
  NewsService(this._client);

  // News API v3 paths (common patterns)
  // If your swagger differs slightly, adjust the path constants here only.
  static const String _search = "/search";
  static const String _latest = "/latest_headlines";
  static const String _breaking = "/breaking_news";
  static const String _authors = "/authors";
  static const String _similar = "/search_similar";
  static const String _sources = "/sources";
  static const String _agg = "/aggregation_count";
  static const String _subscription = "/subscription";
  static const int _defaultPageSize = 20;

  void _requireNonEmpty(String field, String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError("$field is required.");
    }
  }

  void _requirePositive(String field, int value) {
    if (value <= 0) {
      throw ArgumentError("$field must be greater than zero.");
    }
  }

  Future<ApiResponse> search({
    required String q,
    String lang = "en",
    int page = 1,
    int pageSize = _defaultPageSize,
    bool clustering = true,
    bool includeNlp = true,
    String sortBy = "relevancy",
  }) {
    _requireNonEmpty("q", q);
    _requirePositive("page", page);
    _requirePositive("page_size", pageSize);
    return _client.post(
      isNews: true,
      path: _search,
      body: {
        "q": q,
        "lang": lang,
        "page": page,
        "page_size": _defaultPageSize,
        "clustering": clustering,
        "include_nlp_data": true,
        "sort_by": sortBy,
      },
    );
  }

  Future<ApiResponse> latestHeadlines({
    String lang = "en",
    int page = 1,
    int pageSize = _defaultPageSize,
    String? topic,
    String? countries,
    bool includeNlp = true,
    String sortBy = "published_at",
  }) {
    _requirePositive("page", page);
    _requirePositive("page_size", pageSize);
    final body = <String, dynamic>{
      "lang": lang,
      "page": page,
      "page_size": _defaultPageSize,
      "include_nlp_data": includeNlp,
      "countries": "US",
      "sort_by": sortBy,
    };
    if (topic != null && topic.isNotEmpty) body["topic"] = topic;

    return _client.post(isNews: true, path: _latest, body: body);
  }

  Future<ApiResponse> breakingNews({
    String lang = "en",
    int page = 1,
    int pageSize = _defaultPageSize,
    bool includeNlp = true,
    String? countries,
  }) {
    _requirePositive("page", page);
    _requirePositive("page_size", pageSize);
    final body = <String, dynamic>{
      "lang": lang,
      "page": page,
      "page_size": _defaultPageSize,
      "include_nlp_data": includeNlp,
      "countries": "US",
    };
    return _client.post(
      isNews: true,
      path: _breaking,
      body: body,
    );
  }

  Future<ApiResponse> authors({
    String? q,
    String lang = "en",
    int page = 1,
    int pageSize = 25,
  }) {
    final query = <String, String>{
      "lang": lang,
      "page": "$page",
      "page_size": "$pageSize",
    };
    if (q != null && q.isNotEmpty) query["q"] = q;

    return _client.get(isNews: true, path: _authors, query: query);
  }

  Future<ApiResponse> searchSimilar({
    String? q,
    String? url, // If supported by your plan/swagger; otherwise ignore
    int page = 1,
    int pageSize = 25,
    String lang = "en",
  }) {
    final body = <String, dynamic>{
      "page": page,
      "page_size": pageSize,
      "lang": lang,
      "include_nlp_data": true,
    };
    if (q != null && q.isNotEmpty) body["q"] = q;
    if (url != null && url.isNotEmpty) body["url"] = url;

    return _client.post(isNews: true, path: _similar, body: body);
  }

  Future<ApiResponse> sources({
    String? countries,
    String? languages,
    int page = 1,
    int pageSize = 50,
  }) {
    final query = <String, String>{
      "page": "$page",
      "page_size": "$pageSize",
    };
    if (countries != null && countries.isNotEmpty) query["countries"] = countries;
    if (languages != null && languages.isNotEmpty) query["languages"] = languages;

    return _client.get(isNews: true, path: _sources, query: query);
  }

  Future<ApiResponse> aggregationCount({
    required String q,
    String lang = "en",
    String? countries,
    String? topic,
    String aggBy = "country",
  }) {
    final body = <String, dynamic>{
      "q": q,
      "lang": lang,
      "agg_by": aggBy,
    };
    if (countries != null && countries.isNotEmpty) body["countries"] = countries;
    if (topic != null && topic.isNotEmpty) body["topic"] = topic;

    return _client.post(isNews: true, path: _agg, body: body);
  }

  Future<ApiResponse> subscription() {
    // Some deployments require GET; others POST. Try GET first.
    return _client.get(isNews: true, path: _subscription);
  }
}
