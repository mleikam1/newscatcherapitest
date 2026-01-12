import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/article.dart';
import '../../services/api_client.dart';
import '../../services/local_news_service.dart';
import 'article_detail_screen.dart';
import '../widgets/hero_story_card.dart';
import '../widgets/paging_footer.dart';
import '../widgets/section_header.dart';
import '../widgets/story_list_row.dart';

class LocalTabScreen extends StatefulWidget {
  final LocalNewsService local;

  const LocalTabScreen({super.key, required this.local});

  @override
  State<LocalTabScreen> createState() => _LocalTabScreenState();
}

class _LocalTabScreenState extends State<LocalTabScreen> {
  final _section = _SectionState();
  static const int _pageSize = 20;

  double? _lastLat;
  double? _lastLon;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    final lat = appState.latitude;
    final lon = appState.longitude;
    if (appState.locationPermissionGranted && lat != null && lon != null) {
      if (lat != _lastLat || lon != _lastLon) {
        _lastLat = lat;
        _lastLon = lon;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadLocalNews(loadMore: false);
        });
      }
    }
  }

  Future<void> _loadLocalNews({required bool loadMore}) async {
    if (_section.isLoading) return;
    if (loadMore && !_section.hasMore) return;
    if (_lastLat == null || _lastLon == null) return;

    final nextPage = loadMore ? _section.page + 1 : 1;
    setState(() {
      _section.isLoading = true;
      _section.error = null;
      if (!loadMore) {
        _section.items = [];
        _section.hasMore = true;
        _section.page = 0;
      }
    });

    try {
      final response = await widget.local.localLatestNearMe(
        lat: _lastLat!,
        lon: _lastLon!,
        page: nextPage,
        pageSize: _pageSize,
        includeNlp: true,
      );
      final rawArticles =
          (response.json?["articles"] as List<dynamic>?) ?? const [];
      final parsed = rawArticles
          .whereType<Map<String, dynamic>>()
          .map(Article.fromJson)
          .toList();
      final merged = _mergeUnique(_section.items, parsed);
      setState(() {
        _section.items = merged;
        _section.page = nextPage;
        _section.hasMore = parsed.length >= _pageSize;
      });
    } catch (e) {
      setState(() {
        _section.error = "Unable to load local stories.";
      });
    } finally {
      setState(() => _section.isLoading = false);
    }
  }

  List<Article> _mergeUnique(List<Article> existing, List<Article> incoming) {
    final seen = existing.map(_articleKey).toSet();
    final merged = [...existing];
    for (final article in incoming) {
      final key = _articleKey(article);
      if (seen.add(key)) {
        merged.add(article);
      }
    }
    return merged;
  }

  String _articleKey(Article article) {
    final link = article.link;
    if (link != null && link.isNotEmpty) return link;
    return "${article.title ?? ""}-${article.publishedDate ?? ""}";
  }

  void _openDetail(Article article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (!appState.locationPermissionGranted ||
        appState.latitude == null ||
        appState.longitude == null) {
      return _buildLocationEmptyState(appState);
    }

    return ListView(
      children: [
        SectionHeader(
          title: "Local News • Near You",
        ),
        if (_section.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(_section.error!),
          ),
        if (_section.items.isEmpty && _section.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_section.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text("No local stories yet."),
          )
        else ...[
          HeroStoryCard(
            article: _section.items.first,
            onTap: () => _openDetail(_section.items.first),
          ),
          for (final article in _section.items.skip(1))
            StoryListRow(
              article: article,
              onTap: () => _openDetail(article),
            ),
          PagingFooter(
            isLoading: _section.isLoading,
            hasMore: _section.hasMore,
            onMore: () => _loadLocalNews(loadMore: true),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationEmptyState(AppState appState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              "Enable location to see nearby headlines.",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              appState.locationStatus,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => appState.initLocation(),
              child: const Text("Enable location"),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionState {
  List<Article> items = [];
  int page = 0;
  bool isLoading = false;
  bool hasMore = true;
  String? error;
}
