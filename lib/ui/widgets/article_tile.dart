import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/article.dart';
import '../screens/article_webview_screen.dart';

class ArticleTile extends StatelessWidget {
  final Article article;
  const ArticleTile({super.key, required this.article});

  String _publisherLogoUrl() {
    // Prefer sourceUrl domain if present; fallback to sourceName as domain.
    final raw = (article.sourceUrl?.isNotEmpty == true)
        ? article.sourceUrl!
        : (article.sourceName ?? "");
    if (raw.isEmpty) return "";

    // Use Google S2 favicon service for a reliable publisher logo-ish icon.
    // This avoids relying on inconsistent API "logo" fields across endpoints.
    return "https://www.google.com/s2/favicons?sz=128&domain_url=$raw";
  }

  @override
  Widget build(BuildContext context) {
    final title = article.title ?? "(no title)";
    final subtitle = (article.summary?.isNotEmpty == true)
        ? article.summary!
        : (article.excerpt ?? "");
    final link = article.link ?? "";
    final img = article.media ?? "";
    final publisher = article.sourceName ?? "unknown source";
    final pubLogo = _publisherLogoUrl();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: link.isEmpty
            ? null
            : () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ArticleWebViewScreen(
                url: link,
                title: title,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (img.isNotEmpty)
              CachedNetworkImage(
                imageUrl: img,
                height: 180,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox(
                  height: 180,
                  child: Center(child: Text("Image failed")),
                ),
                placeholder: (_, __) => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else
              const SizedBox(
                height: 180,
                child: Center(child: Text("No image")),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pubLogo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: CachedNetworkImage(
                        imageUrl: pubLogo,
                        width: 28,
                        height: 28,
                        errorWidget: (_, __, ___) =>
                        const Icon(Icons.public, size: 28),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.public, size: 28),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          publisher,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article.publishedDate ?? "",
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
