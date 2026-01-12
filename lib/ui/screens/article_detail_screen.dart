import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/article.dart';
import '../screens/article_webview_screen.dart';
import '../widgets/story_utils.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final imageUrl = article.media ?? "";
    final title = article.title ?? "(untitled)";
    final logoUrl = publisherLogoUrl(article);
    final publisher = displayPublisher(article);
    final summary = fallbackSummary(article);
    final link = article.link ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          publisher,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        children: [
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: 240,
              fit: BoxFit.cover,
              placeholder: (_, __) => _imagePlaceholder(context, 240),
              errorWidget: (_, __, ___) => _imagePlaceholder(context, 240),
            )
          else
            _imagePlaceholder(context, 240),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                _PublisherLogo(logoUrl: logoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    publisher,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              "AI summary",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: ElevatedButton(
              onPressed: link.isEmpty
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
              child: const Text("Read article"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context, double height) {
    return Container(
      height: height,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: const Center(
        child: Icon(Icons.photo, size: 48, color: Colors.black45),
      ),
    );
  }
}

class _PublisherLogo extends StatelessWidget {
  final String? logoUrl;

  const _PublisherLogo({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null) {
      return const Icon(Icons.public, size: 32);
    }
    return CachedNetworkImage(
      imageUrl: logoUrl!,
      width: 32,
      height: 32,
      errorWidget: (_, __, ___) => const Icon(Icons.public, size: 32),
    );
  }
}
