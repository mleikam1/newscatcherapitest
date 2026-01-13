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

class BreakingFeedResult {
  final List<Article> articles;
  final String? errorMessage;

  BreakingFeedResult({required this.articles, required this.errorMessage});
}

class ContentAggregationManager {
  ContentAggregationManager(this._news);

  final NewsService _news;

  Future<AggregatedFeedResult> fetchLatestHeadlinesPage({
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _news.latestHeadlines(
        page: page,
        pageSize: pageSize,
      );
      final errorMessage = _extractErrorMessage(response);
      if (errorMessage != null) {
        return AggregatedFeedResult(
          articles: [],
          errorMessage: errorMessage,
          hasMore: false,
        );
      }
      final articles = _parseArticles(response);
      final tagged = articles
          .map((article) => article.copyWith(
                isBreakingNews: _isBreaking(article),
              ))
          .toList();
      return AggregatedFeedResult(
        articles: tagged,
        errorMessage: null,
        hasMore: tagged.length >= pageSize,
      );
    } catch (e, stack) {
      debugPrint("Latest headlines aggregation error: $e\n$stack");
      return AggregatedFeedResult(
        articles: [],
        errorMessage: e.toString(),
        hasMore: false,
      );
    }
  }

  Future<AggregatedFeedResult> fetchHomeFeedPage({
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _news.latestHeadlines(
        page: page,
        pageSize: pageSize,
      );
      final errorMessage = _extractErrorMessage(response);
      if (errorMessage != null) {
        return AggregatedFeedResult(
          articles: [],
          errorMessage: errorMessage,
          hasMore: false,
        );
      }
      final articles = _parseArticles(response);
      final tagged = _dedupeArticles(articles)
          .map((article) => article.copyWith(
                isBreakingNews: _isBreaking(article),
              ))
          .toList();
      return AggregatedFeedResult(
        articles: tagged,
        errorMessage: null,
        hasMore: tagged.length >= pageSize,
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

  Future<BreakingFeedResult> fetchBreakingNews() async {
    try {
      final response = await _news.breakingNews();
      final errorMessage = _extractErrorMessage(response);
      if (errorMessage != null) {
        return BreakingFeedResult(articles: [], errorMessage: errorMessage);
      }
      final articles = _parseArticles(response);
      final breaking = articles
          .map((article) => article.copyWith(
                isBreakingNews: _isBreaking(article),
              ))
          .where((article) => article.isBreakingNews)
          .toList();
      return BreakingFeedResult(articles: breaking, errorMessage: null);
    } catch (e, stack) {
      debugPrint("Breaking aggregation error: $e\n$stack");
      return BreakingFeedResult(articles: [], errorMessage: e.toString());
    }
  }

  bool _isBreaking(Article article) {
    return article.isBreakingNews;
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
    final message = response.json?["message"]?.toString();
    return message ?? "API error ${response.status}";
  }

  List<Article> _dedupeArticles(List<Article> articles) {
    final seen = <String>{};
    final deduped = <Article>[];
    for (final article in articles) {
      final key = _articleKey(article);
      if (seen.add(key)) {
        deduped.add(article);
      }
    }
    return deduped;
  }

  String _articleKey(Article article) {
    if (article.id != null && article.id!.isNotEmpty) {
      return article.id!;
    }
    final link = article.link;
    if (link != null && link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri != null) {
        final host = uri.host.toLowerCase();
        final path = uri.path.toLowerCase();
        return "$host$path";
      }
      return link;
    }
    return "${article.title ?? ""}-${article.publishedDate ?? ""}";
  }
}
