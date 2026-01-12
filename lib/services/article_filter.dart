import 'package:flutter/foundation.dart';

import '../models/article.dart';

class ArticleFilter {
  static const String requiredCountry = "US";
  static const String requiredLanguage = "en";
  static const Duration globalMaxAge = Duration(hours: 24);
  static const Duration localMaxAge = Duration(hours: 36);
  static const Duration absoluteMaxAge = Duration(hours: 48);

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  static bool matchesGeoLanguage(Article article, {required String context}) {
    final country = article.country?.toUpperCase();
    final language = article.language?.toLowerCase();
    if (country != requiredCountry || language != requiredLanguage) {
      debugPrint(
        "Filtered geo mismatch ($context): "
        "id=${article.id ?? "n/a"} link=${article.link ?? "n/a"} "
        "country=$country lang=$language",
      );
      return false;
    }
    return true;
  }

  static bool isWithinAge(
    Article article,
    Duration maxAge, {
    required DateTime nowUtc,
    required String context,
  }) {
    final published = _parseDate(article.publishedDate);
    if (published == null) {
      debugPrint(
        "Filtered missing date ($context): "
        "id=${article.id ?? "n/a"} link=${article.link ?? "n/a"}",
      );
      return false;
    }
    final age = nowUtc.difference(published);
    if (age > absoluteMaxAge) {
      debugPrint(
        "Filtered stale (>48h) ($context): "
        "id=${article.id ?? "n/a"} published=${article.publishedDate}",
      );
      return false;
    }
    if (age > maxAge) {
      debugPrint(
        "Filtered stale ($context): "
        "id=${article.id ?? "n/a"} published=${article.publishedDate}",
      );
      return false;
    }
    return true;
  }

  static List<Article> filterAndSort(
    List<Article> articles, {
    required Duration maxAge,
    required String context,
  }) {
    final nowUtc = DateTime.now().toUtc();
    final filtered = <Article>[];
    for (final article in articles) {
      if (!matchesGeoLanguage(article, context: context)) {
        continue;
      }
      if (!isWithinAge(article, maxAge, nowUtc: nowUtc, context: context)) {
        continue;
      }
      filtered.add(article);
    }
    filtered.sort(
      (a, b) => _parseDate(b.publishedDate)
              ?.compareTo(_parseDate(a.publishedDate) ?? DateTime(1970))
              ?? 0,
    );
    return filtered;
  }

  static DateTime? parsePublishedDate(Article article) {
    return _parseDate(article.publishedDate);
  }
}
