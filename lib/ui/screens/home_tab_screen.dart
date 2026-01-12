import 'package:flutter/material.dart';

import '../../models/article.dart';
import '../../services/api_client.dart';
import '../../services/news_service.dart';
import '../screens/article_detail_screen.dart';
import '../widgets/hero_story_card.dart';
import '../widgets/paging_footer.dart';
import '../widgets/section_header.dart';
import '../widgets/error_utils.dart';
import '../widgets/story_list_row.dart';

class HomeTabScreen extends StatefulWidget {
  final NewsService news;

  const HomeTabScreen({super.key, required this.news});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final _topHeadlines = _SectionState();
  final _breakingNews = _SectionState();
  final _latestNews = _SectionState();

  static const int _pageSize = 20;
  static const String _country = "US";

  @override
  void initState() {
    super.initState();
    _loadTopHeadlines();
    _loadBreakingNews();
    _loadLatestNews();
  }

  Future<void> _loadTopHeadlines({bool loadMore = false}) {
    return _loadSection(
      state: _topHeadlines,
      endpointName: "news.latest_headlines",
      loader: (page) => widget.news.latestHeadlines(
        countries: _country,
        page: page,
        pageSize: _pageSize,
      ),
      loadMore: loadMore,
    );
  }

  Future<void> _loadBreakingNews({bool loadMore = false}) {
    return _loadSection(
      state: _breakingNews,
      endpointName: "news.breaking_news",
      loader: (page) => widget.news.breakingNews(
        countries: _country,
        page: page,
        pageSize: _pageSize,
      ),
      loadMore: loadMore,
    );
  }

  Future<void> _loadLatestNews({bool loadMore = false}) {
    return _loadSection(
      state: _latestNews,
      endpointName: "news.latest_headlines",
      loader: (page) => widget.news.latestHeadlines(
        countries: _country,
        page: page,
        pageSize: _pageSize,
      ),
      loadMore: loadMore,
    );
  }

  Future<void> _loadSection({
    required _SectionState state,
    required String endpointName,
    required Future<ApiResponse> Function(int page) loader,
    required bool loadMore,
  }) async {
    if (state.isLoading) return;
    if (loadMore && !state.hasMore) return;

    final nextPage = loadMore ? state.page + 1 : 1;
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
      final rawArticles =
          (response.json?["articles"] as List<dynamic>?) ?? const [];
      final parsed = rawArticles
          .whereType<Map<String, dynamic>>()
          .map(Article.fromJson)
          .toList();
      final merged = _mergeUnique(state.items, parsed);
      setState(() {
        state.items = merged;
        state.page = nextPage;
        state.hasMore = parsed.length >= _pageSize;
      });
    } catch (e, stack) {
      final message = formatApiError(e, endpointName: endpointName);
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
        if (state.error != null && items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.error!),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        if (items.isEmpty && state.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (items.isEmpty && state.error == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("No stories yet."),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text("Retry"),
                ),
              ],
            ),
          )
        else ...[
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(state.error!),
            ),
          HeroStoryCard(
            article: items.first,
            onTap: () => _openDetail(items.first),
          ),
          for (final article in items.skip(1))
            StoryListRow(
              article: article,
              onTap: () => _openDetail(article),
            ),
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
