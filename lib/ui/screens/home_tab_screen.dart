import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/article.dart';
import '../../services/article_filter.dart';
import '../../services/content_aggregation_manager.dart';
import '../screens/article_detail_screen.dart';
import '../widgets/hero_story_card.dart';
import '../widgets/paging_footer.dart';
import '../widgets/section_header.dart';
import '../widgets/story_list_row.dart';
import '../widgets/state_message.dart';

class HomeTabScreen extends StatefulWidget {
  final ContentAggregationManager aggregation;

  const HomeTabScreen({super.key, required this.aggregation});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final _topHeadlines = _SectionState();
  final _breakingNews = _SectionState();
  final _latestNews = _SectionState();

  static const int _pageSize = 50;
  static const int _maxPages = 3;
  String _language = ArticleFilter.requiredLanguage;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    final nextLanguage = ArticleFilter.requiredLanguage;
    if (!_initialized || nextLanguage != _language || appState.selectedLanguage != _language) {
      _language = nextLanguage;
      _initialized = true;
      _loadTopHeadlines();
      _loadBreakingNews();
      _loadLatestNews();
    }
  }

  Future<void> _loadTopHeadlines({bool loadMore = false}) {
    return _loadSection(
      state: _topHeadlines,
      loader: (page) => widget.aggregation.fetchLatestHeadlinesPage(
        page: page,
        pageSize: _pageSize,
      ),
      loadMore: loadMore,
    );
  }

  Future<void> _loadBreakingNews({bool loadMore = false}) {
    return _loadBreakingSection(loadMore: loadMore);
  }

  Future<void> _loadLatestNews({bool loadMore = false}) {
    return _loadSection(
      state: _latestNews,
      loader: (page) => widget.aggregation.fetchHomeFeedPage(
        page: page,
        pageSize: _pageSize,
      ),
      loadMore: loadMore,
    );
  }

  Future<void> _loadBreakingSection({required bool loadMore}) async {
    final state = _breakingNews;
    if (state.isLoading) return;
    if (loadMore && !state.hasMore) return;

    final nextPage = loadMore ? state.page + 1 : 1;
    if (nextPage > _maxPages) {
      setState(() => state.hasMore = false);
      return;
    }
    setState(() {
      state.isLoading = true;
      state.error = null;
      if (!loadMore) {
        state.items = [];
        state.hasMore = true;
        state.page = 0;
      }
    });

    try {
      final response = await widget.aggregation.fetchBreakingNews(
      );
      final errorMessage = response.errorMessage;
      if (errorMessage != null) {
        setState(() => state.error = errorMessage);
        return;
      }
      final merged = _mergeUnique(state.items, response.articles);
      setState(() {
        state.items = merged;
        state.page = nextPage;
        state.hasMore = false;
      });
    } catch (e, stack) {
      final message = "Breaking news error: $e";
      setState(() {
        state.error = message;
      });
      debugPrint("Breaking news error: $message\n$stack");
    } finally {
      setState(() => state.isLoading = false);
    }
  }

  Future<void> _loadSection({
    required _SectionState state,
    required Future<AggregatedFeedResult> Function(int page) loader,
    required bool loadMore,
  }) async {
    if (state.isLoading) return;
    if (loadMore && !state.hasMore) return;

    final nextPage = loadMore ? state.page + 1 : 1;
    if (nextPage > _maxPages) {
      setState(() => state.hasMore = false);
      return;
    }
    setState(() {
      state.isLoading = true;
      state.error = null;
      if (!loadMore) {
        state.items = [];
        state.hasMore = true;
        state.page = 0;
      }
    });

    try {
      final response = await loader(nextPage);
      final errorMessage = response.errorMessage;
      if (errorMessage != null) {
        setState(() => state.error = errorMessage);
        return;
      }
      final merged = _mergeUnique(state.items, response.articles);
      setState(() {
        state.items = merged;
        state.page = nextPage;
        state.hasMore = response.hasMore && nextPage < _maxPages;
      });
    } catch (e, stack) {
      final message = "Home tab error: $e";
      setState(() {
        state.error = message;
      });
      debugPrint("Home tab error: $message\n$stack");
    } finally {
      setState(() => state.isLoading = false);
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
    return ListView(
      children: [
        _buildSection(
          title: "Top Headlines",
          state: _topHeadlines,
          onMore: () => _loadTopHeadlines(loadMore: true),
          onRetry: () => _loadTopHeadlines(),
        ),
        _buildSection(
          title: "Breaking News",
          state: _breakingNews,
          onMore: () => _loadBreakingNews(loadMore: true),
          onRetry: () => _loadBreakingNews(),
        ),
        _buildSection(
          title: "Latest News",
          state: _latestNews,
          onMore: () => _loadLatestNews(loadMore: true),
          onRetry: () => _loadLatestNews(),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required _SectionState state,
    required VoidCallback onMore,
    required VoidCallback onRetry,
  }) {
    final items = state.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        if (items.isEmpty) ...[
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null)
            ErrorState(
              message: state.error!,
              onAction: onRetry,
            )
          else
            EmptyState(
              title: "No stories available.",
              onAction: onRetry,
            ),
        ] else ...[
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(state.error!),
            ),
          if (items.isNotEmpty) ...[
            HeroStoryCard(
              article: items.first,
              onTap: () => _openDetail(items.first),
            ),
            for (final article in items.skip(1))
              StoryListRow(
                article: article,
                onTap: () => _openDetail(article),
              ),
          ],
          PagingFooter(
            isLoading: state.isLoading,
            hasMore: state.hasMore,
            onMore: onMore,
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
