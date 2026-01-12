import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/article.dart';
import 'story_utils.dart';

class StoryListRow extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;

  const StoryListRow({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = article.title ?? "(untitled)";
    final logoUrl = publisherLogoUrl(article);
    final time = formatPublishedDate(context, article.publishedDate);
    final thumbnailUrl = article.media ?? "";
    final isBreaking = article.isBreakingNews;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PublisherLogo(logoUrl: logoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayPublisher(article),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  if (isBreaking) ...[
                    const SizedBox(height: 4),
                    _BreakingPill(),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (thumbnailUrl.isNotEmpty) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _imagePlaceholder(context),
                  errorWidget: (_, __, ___) => _imagePlaceholder(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      width: 72,
      height: 72,
      child: const Icon(Icons.image, color: Colors.black45, size: 24),
    );
  }
}

class _BreakingPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        "BREAKING",
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
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
      return const Icon(Icons.public, size: 28);
    }
    return CachedNetworkImage(
      imageUrl: logoUrl!,
      width: 28,
      height: 28,
      errorWidget: (_, __, ___) => const Icon(Icons.public, size: 28),
    );
  }
}
