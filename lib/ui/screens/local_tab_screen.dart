import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/article.dart';
import '../../services/api_client.dart';
import '../../services/article_filter.dart';
import '../../services/local_news_service.dart';
import 'article_detail_screen.dart';
import '../widgets/hero_story_card.dart';
import '../widgets/paging_footer.dart';
import '../widgets/section_header.dart';
import '../widgets/error_utils.dart';
import '../widgets/story_list_row.dart';
import '../widgets/state_message.dart';

class LocalTabScreen extends StatefulWidget {
  final LocalNewsService local;

  const LocalTabScreen({super.key, required this.local});

  @override
  State<LocalTabScreen> createState() => _LocalTabScreenState();
}

class _LocalTabScreenState extends State<LocalTabScreen> {
  final _section = _SectionState();
  static const int _pageSize = 30;
  static const int _maxPages = 3;

  String? _city;
  String? _state;
  double? _latitude;
  double? _longitude;
  String _language = ArticleFilter.requiredLanguage;
  bool _initialized = false;
  LocalFallbackMode _fallbackMode = LocalFallbackMode.cityRadius;
  String? _fallbackMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    final nextCity = appState.city;
    final nextState = appState.state;
    final nextLatitude = appState.latitude;
    final nextLongitude = appState.longitude;
    final nextLanguage = ArticleFilter.requiredLanguage;
    if (!_initialized ||
        nextCity != _city ||
        nextState != _state ||
        nextLatitude != _latitude ||
        nextLongitude != _longitude ||
        nextLanguage != _language ||
        appState.selectedLanguage != _language) {
      _city = nextCity;
      _state = nextState;
      _latitude = nextLatitude;
      _longitude = nextLongitude;
      _language = nextLanguage;
      _initialized = true;
      _fallbackMode = LocalFallbackMode.cityRadius;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLocalNews(loadMore: false);
      });
    }
  }

  Future<void> _loadLocalNews({required bool loadMore}) async {
    if (_section.isLoading) return;
    if (loadMore && !_section.hasMore) return;

    if (_latitude == null && _longitude == null && _city == null && _state == null) {
      setState(() {
        _section.error = "Location required to load local news.";
        _section.items = [];
        _section.hasMore = false;
      });
      return;
    }

    final nextPage = loadMore ? _section.page + 1 : 1;
    if (nextPage > _maxPages) {
      setState(() => _section.hasMore = false);
      return;
    }
    setState(() {
      _section.isLoading = true;
      _section.error = null;
      _fallbackMessage = null;
      if (!loadMore) {
        _section.items = [];
        _section.hasMore = true;
        _section.page = 0;
        _fallbackMode = LocalFallbackMode.cityRadius;
      }
    });

    try {
      final result = await _loadWithFallback(nextPage);
      if (result.errorMessage != null) {
        setState(() => _section.error = result.errorMessage);
        return;
      }
      if (result.fallbackMessage != null) {
        setState(() => _fallbackMessage = result.fallbackMessage);
      }
      final merged = _mergeUnique(_section.items, result.articles);
      setState(() {
        _section.items = merged;
        _section.page = nextPage;
        _section.hasMore = result.articles.length >= _pageSize && nextPage < _maxPages;
      });
    } catch (e, stack) {
      final message = "Local news error: $e";
      setState(() => _section.error = message);
      debugPrint("Local news error: $message\n$stack");
    } finally {
      setState(() => _section.isLoading = false);
    }
  }

  Future<_LocalFetchResult> _loadWithFallback(int page) async {
    LocalFallbackMode currentMode = _fallbackMode;
    String? fallbackMessage;
    for (var attempt = 0; attempt < 3; attempt++) {
      final response = await _fetchLocalNews(page, currentMode);
      final errorMessage = extractApiMessage(response);
      if (errorMessage != null) {
        return _LocalFetchResult(
          articles: [],
          errorMessage: errorMessage,
          fallbackMessage: fallbackMessage,
        );
      }
      final rawArticles =
          (response.json?["articles"] as List<dynamic>?) ?? const [];
      final parsed = rawArticles
          .whereType<Map<String, dynamic>>()
          .map(Article.fromJson)
          .toList();
      final filtered = ArticleFilter.filterAndSort(
        parsed,
        maxAge: ArticleFilter.localMaxAge,
        context: "local_news",
      );
      if (page == 1 && filtered.length < 10) {
        final nextMode = _nextFallbackMode(currentMode);
        if (nextMode != null) {
          currentMode = nextMode;
          fallbackMessage = _fallbackMessageForMode(currentMode);
          _fallbackMode = currentMode;
          continue;
        }
      }
      _fallbackMode = currentMode;
      return _LocalFetchResult(
        articles: filtered,
        errorMessage: null,
        fallbackMessage: fallbackMessage,
      );
    }
    return _LocalFetchResult(
      articles: [],
      errorMessage: "Local news returned too few stories.",
      fallbackMessage: fallbackMessage,
    );
  }

  Future<ApiResponse> _fetchLocalNews(int page, LocalFallbackMode mode) {
    final radiusMiles = mode == LocalFallbackMode.cityRadius ? 30 : 50;
    final metroCity = _metroFallbackCity();
    final city = mode == LocalFallbackMode.metroFallback ? metroCity : _city;
    return widget.local.localNews(
      city: mode == LocalFallbackMode.stateOnly ? null : city,
      state: _state,
      latitude: _latitude,
      longitude: _longitude,
      language: _language,
      country: ArticleFilter.requiredCountry,
      radiusMiles: radiusMiles,
      page: page,
      pageSize: _pageSize,
    );
  }

  LocalFallbackMode? _nextFallbackMode(LocalFallbackMode currentMode) {
    if (currentMode == LocalFallbackMode.cityRadius) {
      return LocalFallbackMode.expandedRadius;
    }
    if (currentMode == LocalFallbackMode.expandedRadius && _state != null) {
      return LocalFallbackMode.stateOnly;
    }
    if (currentMode == LocalFallbackMode.stateOnly && _metroFallbackCity() != null) {
      return LocalFallbackMode.metroFallback;
    }
    return null;
  }

  String? _fallbackMessageForMode(LocalFallbackMode mode) {
    switch (mode) {
      case LocalFallbackMode.expandedRadius:
        return "Expanding radius for more local coverage.";
      case LocalFallbackMode.stateOnly:
        return "We couldn't find enough city stories. Showing statewide coverage.";
      case LocalFallbackMode.metroFallback:
        return "Showing metro-area coverage nearby.";
      case LocalFallbackMode.cityRadius:
        return null;
    }
  }

  String? _metroFallbackCity() {
    if (_state == null) return null;
    const metroByState = {
      "CA": "Los Angeles",
      "CALIFORNIA": "Los Angeles",
      "NY": "New York",
      "NEW YORK": "New York",
      "TX": "Dallas",
      "TEXAS": "Dallas",
      "FL": "Miami",
      "FLORIDA": "Miami",
      "IL": "Chicago",
      "ILLINOIS": "Chicago",
      "PA": "Philadelphia",
      "PENNSYLVANIA": "Philadelphia",
      "GA": "Atlanta",
      "GEORGIA": "Atlanta",
      "WA": "Seattle",
      "WASHINGTON": "Seattle",
      "MA": "Boston",
      "MASSACHUSETTS": "Boston",
      "DC": "Washington",
      "DISTRICT OF COLUMBIA": "Washington",
    };
    return metroByState[_state?.toUpperCase()];
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
    if (article.id != null && article.id!.isNotEmpty) {
      return article.id!;
    }
    final link = article.link;
    if (link != null && link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri != null) {
        return "${uri.host.toLowerCase()}${uri.path.toLowerCase()}";
      }
      return link;
    }
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
    final fallbackCity =
        _fallbackMode == LocalFallbackMode.metroFallback ? _metroFallbackCity() : _city;
    final locationLabel = _fallbackMode == LocalFallbackMode.stateOnly
        ? (_state ?? "United States")
        : (fallbackCity ?? _state ?? "United States");

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
          ErrorState(
            message: _section.error!,
            onAction: () => _loadLocalNews(loadMore: false),
          ),
        if (_fallbackMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _fallbackMessage!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (_section.items.isEmpty)
          if (_section.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_section.error == null)
            EmptyState(
              title: "No local stories available.",
              onAction: () => _loadLocalNews(loadMore: false),
            )
          else
            const SizedBox.shrink()
        else ...[
          if (_section.items.isNotEmpty) ...[
            HeroStoryCard(
              article: _section.items.first,
              onTap: () => _openDetail(_section.items.first),
            ),
            for (final article in _section.items.skip(1))
              StoryListRow(
                article: article,
                onTap: () => _openDetail(article),
              ),
          ],
          PagingFooter(
            isLoading: _section.isLoading,
            hasMore: _section.hasMore,
            onMore: () => _loadLocalNews(loadMore: true),
          ),
        ],
      ],
    );
  }

}

enum LocalFallbackMode { cityRadius, expandedRadius, stateOnly, metroFallback }

class _LocalFetchResult {
  final List<Article> articles;
  final String? errorMessage;
  final String? fallbackMessage;

  _LocalFetchResult({
    required this.articles,
    required this.errorMessage,
    required this.fallbackMessage,
  });
}

class _SectionState {
  List<Article> items = [];
  int page = 0;
  bool isLoading = false;
  bool hasMore = true;
  String? error;
}
