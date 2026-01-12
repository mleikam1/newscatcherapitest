import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/article.dart';
import 'story_utils.dart';

class HeroStoryCard extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;

  const HeroStoryCard({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = article.media ?? "";
    final title = article.title ?? "(untitled)";
    final logoUrl = publisherLogoUrl(article);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _imagePlaceholder(context),
                      errorWidget: (_, __, ___) => _imagePlaceholder(context),
                    )
                  else
                    _imagePlaceholder(context),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66000000),
                          Color(0xAA000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _PublisherBadge(logoUrl: logoUrl),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: const Center(
        child: Icon(Icons.photo, size: 48, color: Colors.black45),
      ),
    );
  }
}

class _PublisherBadge extends StatelessWidget {
  final String? logoUrl;

  const _PublisherBadge({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: logoUrl == null
          ? const Icon(Icons.public, size: 18)
          : CachedNetworkImage(
              imageUrl: logoUrl!,
              errorWidget: (_, __, ___) => const Icon(Icons.public, size: 18),
            ),
    );
  }
}
