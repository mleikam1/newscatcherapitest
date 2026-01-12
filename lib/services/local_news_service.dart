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

  Future<ApiResponse> localSearch({
    required String q,
    required double? lat,
    required double? lon,
    int radiusKm = 50,
    int page = 1,
    int pageSize = _defaultPageSize,
    String lang = "en",
    bool includeNlp = true,
  }) {
    _requireNonEmpty("q", q);
    _requireLatLon(lat, lon);
    _requirePositive("page", page);
    _requirePositive("page_size", pageSize);
    return _client.post(
      isNews: false,
      path: _search,
      body: {
        "q": q,
        "lat": lat,
        "lon": lon,
        "radius": radiusKm,
        "lang": lang,
        "page": page,
        "page_size": _defaultPageSize,
        "include_nlp_data": includeNlp,
      },
    );
  }

  Future<ApiResponse> localLatestNearMe({
    required double? lat,
    required double? lon,
    int radiusKm = 50,
    int page = 1,
    int pageSize = _defaultPageSize,
    String lang = "en",
    bool includeNlp = true,
  }) {
    _requireLatLon(lat, lon);
    _requirePositive("page", page);
    _requirePositive("page_size", pageSize);
    return _client.post(
      isNews: false,
      path: _search,
      body: {
        "lat": lat,
        "lon": lon,
        "radius": radiusKm,
        "lang": lang,
        "page": page,
        "page_size": _defaultPageSize,
        "include_nlp_data": includeNlp,
      },
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

    return _client.post(isNews: false, path: _sources, body: body);
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
      "page": page,
      "page_size": _defaultPageSize,
      ...payload,
    };
    return _client.post(isNews: false, path: _searchBy, body: body);
  }
}
