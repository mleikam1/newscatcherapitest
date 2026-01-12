import 'api_client.dart';

class LocalNewsService {
  final ApiClient _client;
  LocalNewsService(this._client);

  static const String _search = "/search";
  static const String _sources = "/sources";
  static const String _searchBy = "/search_by";
  static const int _defaultPageSize = 20;

  void _requireLatLon(double? lat, double? lon) {
    if (lat == null || lon == null) {
      throw ArgumentError("lat and lon are required.");
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
      throw StateError("Response missing required 'articles' field.");
    }
    return response;
  }

  Future<ApiResponse> localSearch({
    required double? lat,
    required double? lon,
    int radiusKm = 50,
    int pageSize = _defaultPageSize,
  }) {
    _requireLatLon(lat, lon);
    _requirePositive("page_size", pageSize);
    return _client
        .post(
          isNews: false,
          path: _search,
          endpointName: "local.search",
          body: {
            "lat": lat,
            "lon": lon,
            "radius": radiusKm,
            "page_size": pageSize,
          },
        )
        .then(_requireArticles);
  }

  Future<ApiResponse> localLatestNearMe({
    required double? lat,
    required double? lon,
    int radiusKm = 50,
    int pageSize = _defaultPageSize,
  }) {
    _requireLatLon(lat, lon);
    _requirePositive("page_size", pageSize);
    return _client
        .post(
          isNews: false,
          path: _search,
          endpointName: "local.search",
          body: {
            "lat": lat,
            "lon": lon,
            "radius": radiusKm,
            "page_size": pageSize,
          },
        )
        .then(_requireArticles);
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
    required double? lat,
    required double? lon,
    int radiusKm = 50,
    int page = 1,
    int pageSize = _defaultPageSize,
  }) {
    _requireLatLon(lat, lon);
    _requirePositive("page", page);
    _requirePositive("page_size", pageSize);
    final body = <String, dynamic>{
      "lat": lat,
      "lon": lon,
      "radius": radiusKm,
      "page_size": pageSize,
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
