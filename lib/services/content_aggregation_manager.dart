import 'package:flutter/foundation.dart';

import '../models/article.dart';
import 'api_client.dart';
import 'news_service.dart';

class AggregatedFeedResult {
  final List<Article> articles;
  final String? errorMessage;
  final bool hasMore;

  AggregatedFeedResult({
    required this.articles,
    required this.errorMessage,
    required this.hasMore,
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
        );
      }
      final articles = _parseArticles(response);
      return AggregatedFeedResult(
        articles: articles,
        errorMessage: null,
        hasMore: false,
      );
    } catch (e, stack) {
      debugPrint("Home aggregation error: $e\n$stack");
      return AggregatedFeedResult(
        articles: [],
        errorMessage: e.toString(),
        hasMore: false,
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

  String? _extractErrorMessage(ApiResponse response) {
    if (response.status == 200) return null;
    if (response.status == 410) return null;
    final message = response.json?["message"]?.toString();
    return message ?? "API error ${response.status}";
  }
}
