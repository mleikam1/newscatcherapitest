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
  final _topStories = _SectionState();

  @override
  void initState() {
    super.initState();
    _loadTopStories();
  }

  Future<void> _loadTopStories() {
    return _loadSection(
      state: _topStories,
      loader: () => widget.aggregation.fetchHomeFeedPage(),
    );
  }

  Future<void> _loadSection({
    required _SectionState state,
    required Future<AggregatedFeedResult> Function() loader,
  }) async {
    if (state.isLoading) return;

    setState(() {
      state.isLoading = true;
      state.error = null;
      state.items = [];
    });

    try {
      final response = await loader();
      final errorMessage = response.errorMessage;
      if (errorMessage != null) {
        setState(() => state.error = errorMessage);
        return;
      }
      final merged = _mergeUnique(state.items, response.articles);
      setState(() {
        state.items = merged;
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
          title: "Top Stories",
          state: _topStories,
          onRetry: _loadTopStories,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required _SectionState state,
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
              title: "No stories available",
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
        ],
      ],
    );
  }
}

class _SectionState {
  List<Article> items = [];
  bool isLoading = false;
  String? error;
}
