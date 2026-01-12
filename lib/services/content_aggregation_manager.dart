import 'package:flutter/foundation.dart';

import '../models/article.dart';
import 'api_client.dart';
import 'article_filter.dart';
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

  static const List<String> _topics = [
    "politics",
    "business",
    "sports",
    "tech",
    "entertainment",
  ];

  Future<AggregatedFeedResult> fetchLatestHeadlinesPage({
    required int page,
    required int pageSize,
    required String language,
  }) async {
    if (language.toLowerCase() != ArticleFilter.requiredLanguage) {
      debugPrint("Overriding language to ${ArticleFilter.requiredLanguage}.");
    }
    try {
      final response = await _news.latestHeadlines(
        countries: ArticleFilter.requiredCountry,
        lang: ArticleFilter.requiredLanguage,
        page: page,
        pageSize: pageSize,
        sortBy: "published_date",
        order: "desc",
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
      final filtered = ArticleFilter.filterAndSort(
        articles,
        maxAge: ArticleFilter.globalMaxAge,
        context: "latest_headlines",
      );
      final tagged = filtered
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
    required String language,
  }) async {
    if (language.toLowerCase() != ArticleFilter.requiredLanguage) {
      debugPrint("Overriding language to ${ArticleFilter.requiredLanguage}.");
    }
    try {
      final futures = <Future<ApiResponse>>[
        _news.latestHeadlines(
          countries: ArticleFilter.requiredCountry,
          lang: ArticleFilter.requiredLanguage,
          page: page,
          pageSize: pageSize,
          sortBy: "published_date",
          order: "desc",
        ),
        for (final topic in _topics)
          _news.search(
            q: "*",
            topic: topic,
            countries: ArticleFilter.requiredCountry,
            lang: ArticleFilter.requiredLanguage,
            page: page,
            pageSize: pageSize,
            sortBy: "published_date",
            order: "desc",
          ),
      ];
      final responses = await Future.wait(futures);
      final articles = <Article>[];
      final errors = <String>[];
      for (final response in responses) {
        final error = _extractErrorMessage(response);
        if (error != null) {
          errors.add(error);
          debugPrint("Aggregation feed error: $error");
          continue;
        }
        articles.addAll(_parseArticles(response));
      }
      if (articles.isEmpty && errors.isNotEmpty) {
        return AggregatedFeedResult(
          articles: [],
          errorMessage: errors.first,
          hasMore: false,
        );
      }
      final deduped = _dedupeArticles(articles);
      final filtered = ArticleFilter.filterAndSort(
        deduped,
        maxAge: ArticleFilter.globalMaxAge,
        context: "home_aggregate",
      );
      final tagged = filtered
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

  Future<BreakingFeedResult> fetchBreakingNews({
    required String language,
  }) async {
    if (language.toLowerCase() != ArticleFilter.requiredLanguage) {
      debugPrint("Overriding language to ${ArticleFilter.requiredLanguage}.");
    }
    try {
      final response = await _news.breakingNews(
        countries: ArticleFilter.requiredCountry,
        lang: ArticleFilter.requiredLanguage,
        sortBy: "published_date",
        order: "desc",
      );
      final errorMessage = _extractErrorMessage(response);
      if (errorMessage != null) {
        return BreakingFeedResult(articles: [], errorMessage: errorMessage);
      }
      final articles = _parseArticles(response);
      final filtered = ArticleFilter.filterAndSort(
        articles,
        maxAge: const Duration(hours: 2),
        context: "breaking",
      );
      final breaking = filtered
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
    if (!article.isBreakingNews) return false;
    final published = ArticleFilter.parsePublishedDate(article);
    if (published == null) return false;
    final age = DateTime.now().toUtc().difference(published);
    return age <= const Duration(hours: 2);
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
