import 'package:flutter/foundation.dart';

import '../models/article.dart';
import 'api_client.dart';
import 'news_service.dart';

class AggregatedFeedResult {
  final List<Article> articles;
  final String? errorMessage;
  final bool hasMore;
  final int? totalCount;

  AggregatedFeedResult({
    required this.articles,
    required this.errorMessage,
    required this.hasMore,
    required this.totalCount,
  });
}

class ContentAggregationManager {
  ContentAggregationManager(this._news);

  final NewsService _news;

  Future<AggregatedFeedResult> fetchHomeFeedPage() async {
    try {
      final response = await _news.latestHeadlines();
      final errorMessage = _extractErrorMessage(response);
      if (errorMessage != null) {
        return AggregatedFeedResult(
          articles: [],
          errorMessage: errorMessage,
          hasMore: false,
          totalCount: null,
        );
      }
      final articles = _parseArticles(response);
      final totalCount = _extractCount(response) ?? articles.length;
      return AggregatedFeedResult(
        articles: articles,
        errorMessage: null,
        hasMore: false,
        totalCount: totalCount,
      );
    } catch (e, stack) {
      debugPrint("Home aggregation error: $e\n$stack");
      return AggregatedFeedResult(
        articles: [],
        errorMessage: e.toString(),
        hasMore: false,
        totalCount: null,
      );
    }
  }

  List<Article> _parseArticles(ApiResponse response) {
    final rawArticles = (response.json?["articles"] as List<dynamic>?) ?? const [];
    return rawArticles
        .whereType<Map<String, dynamic>>()
        .map(Article.fromJson)
        .toList();
  }

  int? _extractCount(ApiResponse response) {
    final json = response.json;
    if (json == null) return null;
    final value = json["count"] ??
        json["total_hits"] ??
        json["totalResults"] ??
        json["total"] ??
        json["total_articles"];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _extractErrorMessage(ApiResponse response) {
    if (response.status == 200) return null;
    if (response.status == 410) return null;
    final message = response.json?["message"]?.toString();
    return message ?? "API error ${response.status}";
  }
}
