import 'api_client.dart';

class NewsService {
  final ApiClient _client;
  NewsService(this._client);

  // News API v3 paths (common patterns)
  // If your swagger differs slightly, adjust the path constants here only.
  static const String _search = "/search";
  static const String _latest = "/latest_headlines";
  static const String _breaking = "/breaking";
  static const String _authors = "/authors";
  static const String _similar = "/search_similar";
  static const String _sources = "/sources";
  static const String _agg = "/aggregation_count";
  static const String _subscription = "/subscription";
  static const int _defaultPageSize = 20;
  static const String _defaultCountry = "US";
  static const String _defaultLanguage = "en";

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
    String? countries,
    String lang = _defaultLanguage,
    int page = 1,
    int pageSize = _defaultPageSize,
    String? topic,
    String? sortBy,
    String? order,
  }) {
    _requireNonEmpty("q", q);
    _requirePositive("page", page);
    _requirePositive("page_size", pageSize);
    final query = <String, String>{
      "q": q,
      "countries": countries?.isNotEmpty == true ? countries! : _defaultCountry,
      "lang": lang,
      "page_size": "$pageSize",
      "page": "$page",
    };
    if (topic != null && topic.isNotEmpty) query["topic"] = topic;
    if (sortBy != null && sortBy.isNotEmpty) query["sort_by"] = sortBy;
    if (order != null && order.isNotEmpty) query["order"] = order;
    return _client
        .get(
          isNews: true,
          path: _search,
          endpointName: "news.search",
          query: query,
        )
        .then(_requireArticles);
  }

  Future<ApiResponse> latestHeadlines({
    int page = 1,
    int pageSize = _defaultPageSize,
    String? countries,
    String lang = _defaultLanguage,
    String? sortBy,
    String? order,
  }) {
    _requirePositive("page", page);
    _requirePositive("page_size", pageSize);
    final query = <String, String>{
      "countries": countries?.isNotEmpty == true ? countries! : _defaultCountry,
      "lang": lang,
      "page_size": "$pageSize",
      "page": "$page",
    };
    if (sortBy != null && sortBy.isNotEmpty) query["sort_by"] = sortBy;
    if (order != null && order.isNotEmpty) query["order"] = order;
    return _client
        .get(
          isNews: true,
          path: _latest,
          endpointName: "news.latest_headlines",
          query: query,
        )
        .then(_requireArticles);
  }

  Future<ApiResponse> breakingNews({
    String? countries,
    String lang = _defaultLanguage,
    String? sortBy,
    String? order,
  }) {
    final query = <String, String>{
      "countries": countries?.isNotEmpty == true ? countries! : _defaultCountry,
      "lang": lang,
    };
    if (sortBy != null && sortBy.isNotEmpty) query["sort_by"] = sortBy;
    if (order != null && order.isNotEmpty) query["order"] = order;
    return _client
        .get(
          isNews: true,
          path: _breaking,
          endpointName: "news.breaking_news",
          query: query,
        )
        .then(_requireArticles);
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

    return _client.get(
      isNews: true,
      path: _authors,
      endpointName: "news.authors",
      query: query,
    );
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

    return _client.post(
      isNews: true,
      path: _similar,
      endpointName: "news.search_similar",
      body: body,
    );
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

    return _client.get(
      isNews: true,
      path: _sources,
      endpointName: "news.sources",
      query: query,
    );
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

    return _client.post(
      isNews: true,
      path: _agg,
      endpointName: "news.aggregation_count",
      body: body,
    );
  }

  Future<ApiResponse> subscription() {
    return _client.get(
      isNews: true,
      path: _subscription,
      endpointName: "news.subscription",
    );
  }

  Future<ApiResponse> healthCheck() {
    return _client.get(
      isNews: true,
      path: "/__health",
      endpointName: "news.__health",
    );
  }
}
