import '../models/article.dart';

class SummaryCacheEntry {
  final List<String> bullets;
  final String? updatedKey;

  SummaryCacheEntry({required this.bullets, required this.updatedKey});
}

class ArticleSummaryService {
  ArticleSummaryService._();

  static final ArticleSummaryService instance = ArticleSummaryService._();

  final Map<String, SummaryCacheEntry> _cache = {};

  Future<List<String>> getSummary(Article article) async {
    final cacheKey = article.cacheKey();
    final updatedKey = article.updatedDate ?? article.publishedDate;
    final cached = _cache[cacheKey];
    if (cached != null && cached.updatedKey == updatedKey) {
      return cached.bullets;
    }
    final bullets = _generateBullets(article);
    _cache[cacheKey] = SummaryCacheEntry(
      bullets: bullets,
      updatedKey: updatedKey,
    );
    return bullets;
  }

  List<String> _generateBullets(Article article) {
    final content = [
      article.title,
      article.description,
      article.excerpt,
      article.summary,
      article.fullText,
    ].whereType<String>().map((text) => text.trim()).where((text) => text.isNotEmpty);

    final rawText = content.join(". ");
    final sentences = _splitSentences(rawText);
    final bullets = <String>[];
    final seen = <String>{};

    for (final sentence in sentences) {
      final cleaned = _cleanSentence(sentence);
      if (cleaned.isEmpty) continue;
      if (seen.add(cleaned.toLowerCase())) {
        bullets.add(_limitWords(cleaned, 20));
      }
      if (bullets.length == 3) break;
    }

    if (bullets.length < 3) {
      final title = article.title?.trim();
      if (title != null && title.isNotEmpty) {
        bullets.add(_limitWords("Article covers $title", 20));
      }
    }
    if (bullets.length < 3) {
      final description = article.description?.trim();
      if (description != null && description.isNotEmpty) {
        bullets.add(_limitWords(description, 20));
      }
    }
    while (bullets.length < 3) {
      bullets.add("Story details are not available in the feed.");
    }

    return bullets.take(3).toList();
  }

  List<String> _splitSentences(String text) {
    if (text.isEmpty) return [];
    final normalized = text.replaceAll(RegExp(r"\s+"), " ").trim();
    return normalized.split(RegExp(r"(?<=[.!?])\s+"));
  }

  String _cleanSentence(String sentence) {
    final trimmed = sentence.trim();
    if (trimmed.isEmpty) return "";
    return trimmed.replaceAll(RegExp(r"\s+"), " ");
  }

  String _limitWords(String sentence, int maxWords) {
    final words = sentence.split(RegExp(r"\s+")).where((word) => word.isNotEmpty).toList();
    if (words.length <= maxWords) return sentence;
    final truncated = words.take(maxWords).join(" ");
    return "$truncated…";
  }
}
