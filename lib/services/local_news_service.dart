import 'api_client.dart';

class LocalNewsService {
  final ApiClient _client;
  LocalNewsService(this._client);

  static const String _localNews = "/local-news";
  static const String _sources = "/sources";
  static const String _searchBy = "/search_by";
  static const int _defaultPageSize = 30;

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

  Future<ApiResponse> localNews({
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    int radiusMiles = 30,
    String? language,
    String country = "US",
    int page = 1,
    int pageSize = _defaultPageSize,
  }) {
    _requirePositive("page", page);
    _requirePositive("page_size", pageSize);
    final body = <String, dynamic>{
      "page": page,
      "page_size": pageSize,
      "country": country,
    };
    if (latitude != null && longitude != null) {
      body["lat"] = latitude;
      body["lon"] = longitude;
      body["radius_km"] = _toKm(radiusMiles);
    }
    if (city != null && city.trim().isNotEmpty) {
      body["city"] = city.trim();
    }
    if (state != null && state.trim().isNotEmpty) {
      body["state"] = state.trim();
    }
    if (language != null && language.trim().isNotEmpty) {
      body["lang"] = language.trim();
    }
    return _client
        .post(
          isNews: false,
          path: _localNews,
          endpointName: "local.local_news",
          body: body,
        )
        .then(_requireArticles);
  }

  int _toKm(int miles) {
    return (miles * 1.60934).round();
  }

  Future<ApiResponse> localLatestNearMe({
    String? location,
    int page = 1,
    int pageSize = _defaultPageSize,
  }) {
    throw UnimplementedError(
      "localLatestNearMe is deprecated. Use localNews with city/state.",
    );
  }

  Future<ApiResponse> localSources({
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

    return _client.post(
      isNews: false,
      path: _sources,
      endpointName: "local.sources",
      body: body,
    );
  }

  Future<ApiResponse> localSearchBy({
    // Local "search by" often supports things like "place", "country", "state", etc.
    // We'll pass raw parameters and show JSON in UI so you can learn what's supported.
    required Map<String, dynamic> payload,
    String? location,
    List<String>? countries,
    int radiusKm = 50,
    int page = 1,
    int pageSize = _defaultPageSize,
  }) {
    if (location == null || location.trim().isEmpty) {
      throw ArgumentError("location is required.");
    }
    _requirePositive("page", page);
    _requirePositive("page_size", pageSize);
    final trimmedLocation = location?.trim();
    final body = <String, dynamic>{
      "radius": radiusKm,
      "page_size": pageSize,
      if (trimmedLocation != null && trimmedLocation.isNotEmpty)
        "location": trimmedLocation,
      if (countries != null && countries.isNotEmpty) "countries": countries,
      ...payload,
    };
    return _client.post(
      isNews: false,
      path: _searchBy,
      endpointName: "local.search_by",
      body: body,
    );
  }
}
