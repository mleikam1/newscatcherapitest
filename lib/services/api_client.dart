import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';

class ApiResponse {
  final int status;
  final Map<String, dynamic>? json;
  final String? rawBody;

  ApiResponse({required this.status, required this.json, required this.rawBody});
}

class ApiException implements Exception {
  final int status;
  final String body;

  ApiException({required this.status, required this.body});

  @override
  String toString() => "ApiException(status: $status, body: $body)";
}

class ApiClient {
  final http.Client _http;

  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  static const int _maxLogBody = 2000;

  String _normalizeBaseUrl(String base) {
    if (base.startsWith("http://") || base.startsWith("https://")) {
      return base;
    }
    return "https://$base";
  }

  Uri _buildUri({
    required bool isNews,
    required String path,
    Map<String, String>? query,
  }) {
    if (AppConfig.useProxy) {
      final base = _normalizeBaseUrl(AppConfig.proxyBaseUrl);
      final prefix = isNews ? AppConfig.proxyNewsPrefix : AppConfig.proxyLocalPrefix;
      return Uri.parse("$base$prefix$path").replace(queryParameters: query);
    } else {
      final base = isNews ? AppConfig.newsBaseUrl : AppConfig.localBaseUrl;
      return Uri.parse("$base$path").replace(queryParameters: query);
    }
  }

  String _truncate(String body) {
    if (body.length <= _maxLogBody) {
      return body;
    }
    return body.substring(0, _maxLogBody);
  }

  void _logRequest(String method, Uri uri, {String? body}) {
    print("→ $method $uri");
    if (body != null && body.isNotEmpty) {
      print("→ BODY ${_truncate(body)}");
    }
  }

  void _logResponse(http.Response resp) {
    print("← ${resp.statusCode} ${_truncate(resp.body)}");
  }

  Map<String, String> _headers({required bool isNews}) {
    final h = <String, String>{
      "content-type": "application/json",
      "accept": "application/json",
    };

    if (!AppConfig.useProxy) {
      final token = isNews ? AppConfig.newsApiToken : AppConfig.localApiToken;
      h["x-api-token"] = token;
    }

    return h;
  }

  Future<ApiResponse> get({
    required bool isNews,
    required String path,
    Map<String, String>? query,
  }) async {
    final uri = _buildUri(isNews: isNews, path: path, query: query);
    _logRequest("GET", uri);
    final resp = await _http.get(uri, headers: _headers(isNews: isNews));
    return _parse(resp);
  }

  Future<ApiResponse> post({
    required bool isNews,
    required String path,
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(isNews: isNews, path: path, query: query);
    final encodedBody = jsonEncode(body ?? <String, dynamic>{});
    _logRequest("POST", uri, body: encodedBody);
    final resp = await _http.post(
      uri,
      headers: _headers(isNews: isNews),
      body: encodedBody,
    );
    return _parse(resp);
  }

  ApiResponse _parse(http.Response resp) {
    _logResponse(resp);
    if (resp.body.trim().isEmpty) {
      throw ApiException(status: resp.statusCode, body: "Empty response body.");
    }
    if (resp.statusCode != 200) {
      print("API error: ${resp.statusCode} ${resp.body}");
      throw ApiException(status: resp.statusCode, body: resp.body);
    }
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) {
        print("← JSON keys: ${decoded.keys.join(", ")}");
        return ApiResponse(status: resp.statusCode, json: decoded, rawBody: resp.body);
      }
      throw FormatException("Expected JSON object but got ${decoded.runtimeType}.");
    } catch (error) {
      print("API JSON parse error: $error");
      throw ApiException(status: resp.statusCode, body: resp.body);
    }
  }
}
