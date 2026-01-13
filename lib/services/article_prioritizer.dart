import '../models/article.dart';

const List<String> _preferredPublisherMatches = [
  "espn",
  "yahoo",
  "cnn",
  "foxnews",
  "fox news",
  "foxsports",
  "fox sports",
  "fox.com",
  "nbc",
  "cbs",
  "cbs sports",
  "abc",
  "associated press",
  "apnews",
  "ap news",
  "reuters",
  "npr",
];

List<Article> prioritizePreferredPublishers(List<Article> articles) {
  if (articles.isEmpty) {
    return articles;
  }
  final preferred = <Article>[];
  final remaining = <Article>[];
  for (final article in articles) {
    if (_isPreferredPublisher(article)) {
      preferred.add(article);
    } else {
      remaining.add(article);
    }
  }
  return [...preferred, ...remaining];
}

bool _isPreferredPublisher(Article article) {
  final sourceName = article.sourceName?.toLowerCase().trim();
  if (sourceName != null &&
      (sourceName == "fox" || sourceName == "fox news")) {
    return true;
  }
  final candidates = <String?>[
    article.domainUrl,
    article.sourceUrl,
    article.sourceName,
    _hostFromUrl(article.sourceUrl),
    _hostFromUrl(article.link),
  ];
  final normalizedCandidates = candidates
      .whereType<String>()
      .map((value) => value.toLowerCase())
      .toList();
  for (final candidate in normalizedCandidates) {
    for (final matcher in _preferredPublisherMatches) {
      if (candidate.contains(matcher)) {
        return true;
      }
    }
  }
  return false;
}

String? _hostFromUrl(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(value);
  if (uri == null) {
    return null;
  }
  return uri.host.toLowerCase();
}
