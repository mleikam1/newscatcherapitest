import 'package:flutter/material.dart';
import '../../models/article.dart';
import '../../services/content_aggregation_manager.dart';
import '../screens/article_detail_screen.dart';
import '../widgets/hero_story_card.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTopStories();
  }

  Future<void> _loadTopStories() {
    return _loadFeed(() => widget.aggregation.fetchHomeFeedPage());
  }

  Future<void> _loadFeed(
    Future<AggregatedFeedResult> Function() loader,
  ) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _articles = [];
      _totalCount = null;
    });

    try {
      final response = await loader();
      final errorMessage = response.errorMessage;
      if (errorMessage != null) {
        setState(() => _error = errorMessage);
        return;
      }
      setState(() {
        _articles = response.articles;
        _totalCount = response.totalCount;
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
          ],
        ],
      ],
    );
  }
}
