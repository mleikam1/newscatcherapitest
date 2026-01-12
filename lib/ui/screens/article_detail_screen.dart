import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/article.dart';
import '../../services/article_summary_service.dart';
import '../screens/article_webview_screen.dart';
import '../widgets/story_utils.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late Future<List<String>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = ArticleSummaryService.instance.getSummary(widget.article);
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final imageUrl = article.media ?? "";
    final title = article.title ?? "(untitled)";
    final logoUrl = publisherLogoUrl(article);
    final publisher = displayPublisher(article);
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
          FutureBuilder<List<String>>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: LinearProgressIndicator(),
                );
              }
              final bullets = snapshot.data ?? const [];
              if (bullets.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    "Summary unavailable for this story.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final bullet in bullets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          "• $bullet",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              );
            },
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
