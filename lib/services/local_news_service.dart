import 'api_client.dart';

class LocalNewsService {
  final ApiClient _client;
  LocalNewsService(this._client);

  static const String _search = "/api/search";
  static const String _latest = "/api/latest_headlines";
  static const String _sources = "/api/sources";
  static const String _searchBy = "/api/search_by";

  Future<ApiResponse> localSearch({
    required String q,
    required double lat,
    required double lon,
    int radiusKm = 50,
    int page = 1,
    int pageSize = 25,
    String lang = "en",
  }) {
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
        "page_size": pageSize,
      },
    );
  }

  Future<ApiResponse> localLatestNearMe({
    required double lat,
    required double lon,
    int radiusKm = 50,
    int page = 1,
    int pageSize = 25,
    String lang = "en",
  }) {
    return _client.post(
      isNews: false,
      path: _latest,
      body: {
        "lat": lat,
        "lon": lon,
        "radius": radiusKm,
        "lang": lang,
        "page": page,
        "page_size": pageSize,
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
  }) {
    return _client.post(isNews: false, path: _searchBy, body: payload);
  }
}
