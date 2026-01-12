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
import '../widgets/error_utils.dart';
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

  String? _locationQuery;
  String? _countryCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final location = _resolveLocationQuery(locale);
    if (location != _locationQuery || locale.countryCode != _countryCode) {
      _locationQuery = location;
      _countryCode = locale.countryCode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLocalNews(loadMore: false);
      });
    }
  }

  Future<void> _loadLocalNews({required bool loadMore}) async {
    if (_section.isLoading) return;
    if (loadMore && !_section.hasMore) return;
    if (_locationQuery == null || _locationQuery!.isEmpty) return;

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
        location: _locationQuery,
        countries: _countryCode == null ? null : [_countryCode!],
        pageSize: _pageSize,
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
    } catch (e, stack) {
      final message = formatApiError(e, endpointName: "local.search");
      setState(() {
        _section.error = message;
      });
      debugPrint("Local news error: $message\n$stack");
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
    final locationLabel = _locationQuery ?? "Local News";

    return ListView(
      children: [
        SectionHeader(
          title: "Local News • $locationLabel",
        ),
        if (!appState.locationPermissionGranted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(appState.locationStatus),
          ),
        if (_section.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_section.error!),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _loadLocalNews(loadMore: false),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        if (_section.items.isEmpty && _section.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_section.items.isEmpty && _section.error == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("No local stories yet."),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _loadLocalNews(loadMore: false),
                  child: const Text("Retry"),
                ),
              ],
            ),
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

  String _resolveLocationQuery(Locale locale) {
    const fallback = "United States";
    final code = locale.countryCode?.toUpperCase();
    if (code == null) return fallback;
    const countryNames = {
      "US": "United States",
      "CA": "Canada",
      "GB": "United Kingdom",
      "AU": "Australia",
      "NZ": "New Zealand",
      "IE": "Ireland",
      "IN": "India",
    };
    return countryNames[code] ?? code;
  }
}

class _SectionState {
  List<Article> items = [];
  int page = 0;
  bool isLoading = false;
  bool hasMore = true;
  String? error;
}
