import 'api_client.dart';

class NewsService {
  final ApiClient _client;
  NewsService(this._client);

  // News API v3 paths (common patterns)
  // If your swagger differs slightly, adjust the path constants here only.
  static const String _search = "/api/search";
  static const String _latest = "/api/latest_headlines";
  static const String _breaking = "/api/breaking_news";
  static const String _authors = "/api/authors";
  static const String _similar = "/api/search_similar";
  static const String _sources = "/api/sources";
  static const String _agg = "/api/aggregation_count";
  static const String _subscription = "/api/subscription";

  Future<ApiResponse> search({
    required String q,
    String lang = "en",
    int page = 1,
    int pageSize = 25,
    bool clustering = true,
    bool includeNlp = true,
    String sortBy = "relevancy",
  }) {
    return _client.post(
      isNews: true,
      path: _search,
      body: {
        "q": q,
        "lang": lang,
        "page": page,
        "page_size": pageSize,
        "clustering": clustering,
        "include_nlp_data": includeNlp,
        "sort_by": sortBy,
      },
    );
  }

  Future<ApiResponse> latestHeadlines({
    String lang = "en",
    int page = 1,
    int pageSize = 25,
    String? topic,
    String? countries,
  }) {
    final body = <String, dynamic>{
      "lang": lang,
      "page": page,
      "page_size": pageSize,
    };
    if (topic != null && topic.isNotEmpty) body["topic"] = topic;
    if (countries != null && countries.isNotEmpty) body["countries"] = countries;

    return _client.post(isNews: true, path: _latest, body: body);
  }

  Future<ApiResponse> breakingNews({
    String lang = "en",
    int page = 1,
    int pageSize = 25,
  }) {
    return _client.post(
      isNews: true,
      path: _breaking,
      body: {
        "lang": lang,
        "page": page,
        "page_size": pageSize,
      },
    );
  }

  Future<ApiResponse> authors({
    String? q,
    String lang = "en",
    int page = 1,
    int pageSize = 25,
  }) {
    final body = <String, dynamic>{
      "lang": lang,
      "page": page,
      "page_size": pageSize,
    };
    if (q != null && q.isNotEmpty) body["q"] = q;

    return _client.post(isNews: true, path: _authors, body: body);
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
    final body = <String, dynamic>{
      "page": page,
      "page_size": pageSize,
    };
    if (countries != null && countries.isNotEmpty) body["countries"] = countries;
    if (languages != null && languages.isNotEmpty) body["languages"] = languages;

    return _client.post(isNews: true, path: _sources, body: body);
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
