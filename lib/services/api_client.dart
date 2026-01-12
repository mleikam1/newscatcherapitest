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

  Uri _buildUri({
    required bool isNews,
    required String path,
    Map<String, String>? query,
  }) {
    if (AppConfig.useProxy) {
      final base = AppConfig.proxyBaseUrl;
      final prefix = isNews ? AppConfig.proxyNewsPrefix : AppConfig.proxyLocalPrefix;
      return Uri.parse("$base$prefix$path").replace(queryParameters: query);
    } else {
      final base = isNews ? AppConfig.newsBaseUrl : AppConfig.localBaseUrl;
      return Uri.parse("$base$path").replace(queryParameters: query);
    }
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
    final resp = await _http.post(
      uri,
      headers: _headers(isNews: isNews),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _parse(resp);
  }

  ApiResponse _parse(http.Response resp) {
    if (resp.statusCode != 200) {
      print("API error: ${resp.statusCode} ${resp.body}");
    }
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) {
        final response =
            ApiResponse(status: resp.statusCode, json: decoded, rawBody: resp.body);
        if (resp.statusCode != 200) {
          throw ApiException(status: resp.statusCode, body: resp.body);
        }
        return response;
      }
      final response = ApiResponse(
        status: resp.statusCode,
        json: {"data": decoded},
        rawBody: resp.body,
      );
      if (resp.statusCode != 200) {
        throw ApiException(status: resp.statusCode, body: resp.body);
      }
      return response;
    } catch (_) {
      if (resp.statusCode != 200) {
        throw ApiException(status: resp.statusCode, body: resp.body);
      }
      return ApiResponse(status: resp.statusCode, json: null, rawBody: resp.body);
    }
  }
}
