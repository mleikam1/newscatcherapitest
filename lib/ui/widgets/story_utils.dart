import 'package:flutter/material.dart';

import '../../models/article.dart';

String? storyDomain(Article article) {
  final raw = (article.sourceUrl?.isNotEmpty == true)
      ? article.sourceUrl
      : (article.link?.isNotEmpty == true ? article.link : null);
  if (raw == null) return null;
  final parsed = Uri.tryParse(raw);
  if (parsed == null) return null;
  return parsed.host.isNotEmpty ? parsed.host : null;
}

String? publisherLogoUrl(Article article) {
  final domain = storyDomain(article);
  if (domain == null) return null;
  return "https://www.google.com/s2/favicons?sz=128&domain_url=$domain";
}

String displayPublisher(Article article) {
  return article.sourceName ??
      storyDomain(article) ??
      "Unknown publisher";
}

String formatPublishedDate(BuildContext context, String? raw) {
  if (raw == null || raw.isEmpty) return "";
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final local = parsed.toLocal();
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatMediumDate(local);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: false,
  );
  return "$date • $time";
}

String fallbackSummary(Article article) {
  final summary = article.summary;
  if (summary != null && summary.trim().isNotEmpty) return summary.trim();
  final excerpt = article.excerpt;
  if (excerpt != null && excerpt.trim().isNotEmpty) {
    return excerpt.trim();
  }
  final title = article.title;
  if (title != null && title.trim().isNotEmpty) {
    return "This article covers $title.";
  }
  return "Summary unavailable for this story.";
}
