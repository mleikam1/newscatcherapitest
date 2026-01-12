import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class ApiResponse {
  final int status;
  final Map<String, dynamic>? json;
  final String? rawBody;

  ApiResponse({required this.status, required this.json, required this.rawBody});
}

class ApiRequestException implements Exception {
  final String method;
  final Uri url;
  final String endpointName;
  final int? status;
  final String body;

  ApiRequestException({
    required this.method,
    required this.url,
    required this.endpointName,
    required this.status,
    required this.body,
  });

  String get displayMessage {
    final code = status != null ? "HTTP $status" : "HTTP error";
    return "$code • $endpointName • ${url.toString()} • $body";
  }

  @override
  String toString() => displayMessage;
}

class ApiDiagnostics extends ChangeNotifier {
  ApiDiagnostics._();

  static final ApiDiagnostics instance = ApiDiagnostics._();

  String get workerBaseUrl => _normalizeBaseUrl(AppConfig.proxyBaseUrl);

  String? lastRequestUrl;
  String? lastMethod;
  String? lastQueryParams;
  String? lastRequestBody;
  int? lastStatus;
  String? lastResponseSnippet;
  String? lastErrorMessage;

  void recordRequest({
    required String method,
    required Uri url,
    Map<String, String>? query,
    String? body,
  }) {
    lastMethod = method;
    lastRequestUrl = url.toString();
    lastQueryParams = query == null ? null : jsonEncode(query);
    lastRequestBody = body;
    lastErrorMessage = null;
  }

  void recordResponse({
    required int status,
    required String responseSnippet,
  }) {
    lastStatus = status;
    lastResponseSnippet = responseSnippet;
    notifyListeners();
  }

  void recordError(String message, {int? status}) {
    lastErrorMessage = message;
    if (status != null) {
      lastStatus = status;
    }
    notifyListeners();
  }
}

String _normalizeBaseUrl(String base) {
  if (base.startsWith("http://") || base.startsWith("https://")) {
    return base;
  }
  return "https://$base";
}

class ApiClient {
  final http.Client _http;
  final ApiDiagnostics _diagnostics;

  ApiClient({http.Client? httpClient, ApiDiagnostics? diagnostics})
      : _http = httpClient ?? http.Client(),
        _diagnostics = diagnostics ?? ApiDiagnostics.instance;

  static const int _maxLogBody = 2000;

  Uri _buildUri({
    required bool isNews,
    required String path,
    Map<String, String>? query,
  }) {
    final base = _normalizeBaseUrl(AppConfig.proxyBaseUrl);
    final prefix = isNews ? AppConfig.proxyNewsPrefix : AppConfig.proxyLocalPrefix;
    return Uri.parse("$base$prefix$path").replace(queryParameters: query);
  }

  String _truncate(String body) {
    if (body.length <= _maxLogBody) {
      return body;
    }
    return body.substring(0, _maxLogBody);
  }

  void _logRequest(
    String method,
    Uri uri, {
    Map<String, String>? query,
    String? body,
  }) {
    debugPrint("→ $method $uri");
    if (query != null && query.isNotEmpty) {
      debugPrint("→ QUERY ${jsonEncode(query)}");
    }
    if (body != null && body.isNotEmpty) {
      debugPrint("→ BODY ${_truncate(body)}");
    }
  }

  void _logResponse(http.Response resp) {
    debugPrint("← ${resp.statusCode} ${_truncate(resp.body)}");
  }

  Map<String, String> _headers() => const <String, String>{
        "content-type": "application/json",
        "accept": "application/json",
      };

  Future<ApiResponse> get({
    required bool isNews,
    required String path,
    required String endpointName,
    Map<String, String>? query,
  }) async {
    final uri = _buildUri(isNews: isNews, path: path, query: query);
    _logRequest("GET", uri, query: query);
    _diagnostics.recordRequest(method: "GET", url: uri, query: query);
    final resp = await _http.get(uri, headers: _headers());
    return _parse(resp, method: "GET", url: uri, endpointName: endpointName);
  }

  Future<ApiResponse> post({
    required bool isNews,
    required String path,
    required String endpointName,
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(isNews: isNews, path: path, query: query);
    final encodedBody = jsonEncode(body ?? <String, dynamic>{});
    _logRequest("POST", uri, query: query, body: encodedBody);
    _diagnostics.recordRequest(
      method: "POST",
      url: uri,
      query: query,
      body: encodedBody,
    );
    final resp = await _http.post(
      uri,
      headers: _headers(),
      body: encodedBody,
    );
    return _parse(resp, method: "POST", url: uri, endpointName: endpointName);
  }

  ApiResponse _parse(
    http.Response resp, {
    required String method,
    required Uri url,
    required String endpointName,
  }) {
    _logResponse(resp);
    _diagnostics.recordResponse(
      status: resp.statusCode,
      responseSnippet: _truncate(resp.body),
    );
    if (resp.body.trim().isEmpty) {
      final message = "Empty response body.";
      _diagnostics.recordError(message, status: resp.statusCode);
      return ApiResponse(
        status: resp.statusCode,
        json: const {"articles": <dynamic>[]},
        rawBody: resp.body,
      );
    }
    if (resp.statusCode == 403 || resp.statusCode >= 500) {
      final message = _truncate(resp.body);
      _diagnostics.recordError(message, status: resp.statusCode);
      return ApiResponse(
        status: resp.statusCode,
        json: const {"articles": <dynamic>[]},
        rawBody: resp.body,
      );
    }
    if (resp.statusCode != 200) {
      final message = _truncate(resp.body);
      debugPrint("API error: ${resp.statusCode} $message");
      _diagnostics.recordError(message, status: resp.statusCode);
      throw ApiRequestException(
        method: method,
        url: url,
        endpointName: endpointName,
        status: resp.statusCode,
        body: message,
      );
    }
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) {
        debugPrint("← JSON keys: ${decoded.keys.join(", ")}");
        return ApiResponse(status: resp.statusCode, json: decoded, rawBody: resp.body);
      }
      throw FormatException("Expected JSON object but got ${decoded.runtimeType}.");
    } catch (error) {
      final message = "JSON parse error: $error";
      debugPrint("API JSON parse error: $message");
      _diagnostics.recordError(message, status: resp.statusCode);
      throw ApiRequestException(
        method: method,
        url: url,
        endpointName: endpointName,
        status: resp.statusCode,
        body: message,
      );
    }
  }
}
