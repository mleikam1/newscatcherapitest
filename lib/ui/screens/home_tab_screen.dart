import 'package:flutter/material.dart';
import '../../models/article.dart';
import '../../services/content_aggregation_manager.dart';
import '../../services/article_prioritizer.dart';
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
  List<Article> _articles = [];
  bool _isLoading = false;
  String? _error;
  int? _totalCount;
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadTopStories();
  }

  Future<void> _loadTopStories() {
    return _loadFeed(reset: true);
  }

  Future<void> _loadFeed({bool reset = false}) async {
    if (_isLoading) return;
    if (!_hasMore && !reset) return;

    final nextPage = reset ? 1 : _currentPage + 1;
    setState(() {
      _isLoading = true;
      _error = null;
      if (reset) {
        _articles = [];
        _totalCount = null;
        _hasMore = true;
        _currentPage = 1;
      }
    });

    try {
      final response = await widget.aggregation.fetchHomeFeedPage(
        page: nextPage,
        pageSize: _pageSize,
      );
      final errorMessage = response.errorMessage;
      if (errorMessage != null) {
        setState(() => _error = errorMessage);
        return;
      }
      final incoming = prioritizePreferredPublishers(response.articles);
      final merged = prioritizePreferredPublishers(
        _mergeUnique(_articles, incoming),
      );
      setState(() {
        _articles = merged;
        _totalCount = response.totalCount ?? _totalCount;
        _currentPage = nextPage;
        if (response.articles.isEmpty) {
          _hasMore = false;
        }
      });
    } catch (e, stack) {
      final message = "Home tab error: $e";
      setState(() {
        _error = message;
      });
      debugPrint("Home tab error: $message\n$stack");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Article> _mergeUnique(List<Article> existing, List<Article> incoming) {
    if (existing.isEmpty) return incoming;
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
          title: "Top Stories",
          articles: _articles,
          isLoading: _isLoading,
          errorMessage: _error,
          totalCount: _totalCount,
          onRetry: _loadTopStories,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Article> articles,
    required bool isLoading,
    required String? errorMessage,
    required int? totalCount,
    required VoidCallback onRetry,
  }) {
    final items = articles;
    final hasCount = totalCount != null;
    final isEmpty = hasCount ? totalCount == 0 : items.isEmpty;
    final canLoadMore = _hasMore && items.length >= _pageSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        if (isEmpty) ...[
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!hasCount && errorMessage != null)
            ErrorState(
              message: errorMessage,
              onAction: onRetry,
            )
          else
            EmptyState(
              title: "No stories to show right now",
              onAction: onRetry,
            ),
        ] else ...[
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(errorMessage),
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
            PagingFooter(
              isLoading: isLoading,
              hasMore: canLoadMore,
              onMore: _loadFeed,
            ),
          ],
        ],
      ],
    );
  }
}
