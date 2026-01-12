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
import '../widgets/state_message.dart';

class LocalTabScreen extends StatefulWidget {
  final LocalNewsService local;

  const LocalTabScreen({super.key, required this.local});

  @override
  State<LocalTabScreen> createState() => _LocalTabScreenState();
}

class _LocalTabScreenState extends State<LocalTabScreen> {
  final _section = _SectionState();
  static const int _pageSize = 20;

  String? _city;
  String? _state;
  bool _stateFallbackActive = false;
  String? _fallbackMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    final nextCity = appState.city;
    final nextState = appState.state;
    if (nextCity != _city || nextState != _state) {
      _city = nextCity;
      _state = nextState;
      _stateFallbackActive = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLocalNews(loadMore: false);
      });
    }
  }

  Future<void> _loadLocalNews({required bool loadMore}) async {
    if (_section.isLoading) return;
    if (loadMore && !_section.hasMore) return;

    final nextPage = loadMore ? _section.page + 1 : 1;
    setState(() {
      _section.isLoading = true;
      _section.error = null;
      _fallbackMessage = null;
      if (!loadMore) {
        _section.items = [];
        _section.hasMore = true;
        _section.page = 0;
      }
    });

    try {
      final response = await _fetchLocalNews(nextPage);
      if (response.status != 200) {
        debugPrint(
          "Local news non-200 response: ${response.status} ${response.rawBody}",
        );
      }
      final rawArticles =
          (response.json?["articles"] as List<dynamic>?) ?? const [];
      final parsed = rawArticles
          .whereType<Map<String, dynamic>>()
          .map(Article.fromJson)
          .toList();
      if (parsed.isEmpty && !_stateFallbackActive && _state != null) {
        debugPrint(
          "Local news empty for city/state. Retrying with state-only query.",
        );
        _stateFallbackActive = true;
        setState(() {
          _fallbackMessage =
              "We couldn't find city stories. Showing statewide coverage.";
        });
        await _retryWithStateOnly(nextPage);
        return;
      }
      final merged = _mergeUnique(_section.items, parsed);
      setState(() {
        _section.items = merged;
        _section.page = nextPage;
        _section.hasMore = parsed.length >= _pageSize;
      });
    } catch (e, stack) {
      final message = formatApiError(e, endpointName: "local.local_news");
      if (!_stateFallbackActive && _state != null) {
        _stateFallbackActive = true;
        setState(() {
          _fallbackMessage =
              "We couldn't load city news. Showing statewide coverage instead.";
        });
        debugPrint("Local news error: $message\n$stack");
        await _retryWithStateOnly(nextPage);
        return;
      }
      setState(() => _section.error = message);
      debugPrint("Local news error: $message\n$stack");
    } finally {
      setState(() => _section.isLoading = false);
    }
  }

  Future<ApiResponse> _fetchLocalNews(int page) {
    if (_stateFallbackActive) {
      return widget.local.localNews(
        state: _state,
        page: page,
        pageSize: _pageSize,
      );
    }
    return widget.local.localNews(
      city: _city,
      state: _state,
      page: page,
      pageSize: _pageSize,
    );
  }

  Future<void> _retryWithStateOnly(int page) async {
    final response = await widget.local.localNews(
      state: _state,
      page: page,
      pageSize: _pageSize,
    );
    final rawArticles = (response.json?["articles"] as List<dynamic>?) ?? const [];
    final parsed = rawArticles
        .whereType<Map<String, dynamic>>()
        .map(Article.fromJson)
        .toList();
    final merged = _mergeUnique(_section.items, parsed);
    setState(() {
      _section.items = merged;
      _section.page = page;
      _section.hasMore = parsed.length >= _pageSize;
    });
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
    final locationLabel = _stateFallbackActive
        ? (_state ?? "United States")
        : (_city ?? _state ?? "United States");

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

}

class _SectionState {
  List<Article> items = [];
  int page = 0;
  bool isLoading = false;
  bool hasMore = true;
  String? error;
}
