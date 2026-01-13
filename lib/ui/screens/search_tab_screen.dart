import 'package:flutter/material.dart';
import '../../models/article.dart';
import '../../services/api_client.dart';
import '../../services/news_service.dart';
import 'article_detail_screen.dart';
import '../widgets/hero_story_card.dart';
import '../widgets/paging_footer.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/error_utils.dart';
import '../widgets/story_list_row.dart';
import '../widgets/state_message.dart';

class SearchTabScreen extends StatefulWidget {
  final NewsService news;

  const SearchTabScreen({super.key, required this.news});

  @override
  State<SearchTabScreen> createState() => _SearchTabScreenState();
}

class _SearchTabScreenState extends State<SearchTabScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Article> _results = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  String? _query;
  bool get _hasSearched => _query != null && _query!.isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitSearch(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _error = "Please enter a search term.";
        _results = [];
        _hasMore = false;
        _query = null;
      });
      return;
    }
    setState(() {
      _query = query;
      _results = [];
      _hasMore = true;
      _error = null;
    });
    await _loadMore(reset: true);
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_isLoading) return;
    if (!_hasMore && !reset) return;
    final query = _query;
    if (query == null || query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ApiResponse response = await widget.news.search(
        q: query,
      );
      final errorMessage = extractApiMessage(response);
      if (errorMessage != null) {
        setState(() {
          _error = errorMessage;
          _hasMore = false;
        });
        return;
      }
      final rawArticles =
          (response.json?["articles"] as List<dynamic>?) ?? const [];
      final parsed = rawArticles
          .whereType<Map<String, dynamic>>()
          .map(Article.fromJson)
          .toList();
      final merged = _mergeUnique(_results, parsed);
      setState(() {
        _results = merged;
        _hasMore = false;
      });
    } catch (e, stack) {
      final message = formatApiError(e, endpointName: "news.search");
      setState(() => _error = message);
      debugPrint("Search error: $message\n$stack");
    } finally {
      setState(() => _isLoading = false);
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
    final isInitial = !_hasSearched && !_isLoading;
    final alignment = isInitial ? Alignment(0, -0.2) : Alignment.topCenter;

    return Stack(
      children: [
        AnimatedAlign(
          alignment: alignment,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            opacity: isInitial ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 420),
            child: _buildSearchBar(context),
          ),
        ),
        Positioned.fill(
          top: isInitial ? 280 : 120,
          child: _buildResultsArea(),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(24),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: _submitSearch,
              decoration: InputDecoration(
                hintText: "Ask for news…",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
          if (!_hasSearched) ...[
            const SizedBox(height: 12),
            Text(
              "Try: ‘NFL playoffs’, ‘AI regulation’, ‘Overland Park weather’",
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_isLoading && _results.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          if (_query != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                "Finding content for \"$_query\"",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          const ShimmerLoader(itemCount: 6),
        ],
      );
    }

    if (_error != null) {
      return ErrorState(
        message: _error!,
        onAction: _hasSearched ? () => _loadMore(reset: true) : null,
      );
    }

    if (!_hasSearched && !_isLoading) {
      return const SizedBox.shrink();
    }

    if (_results.isEmpty) {
      return EmptyState(
        title: "No results yet.",
        onAction: _hasSearched ? () => _loadMore(reset: true) : null,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        if (_results.isNotEmpty) ...[
          HeroStoryCard(
            article: _results.first,
            onTap: () => _openDetail(_results.first),
          ),
          for (final article in _results.skip(1))
            StoryListRow(
              article: article,
              onTap: () => _openDetail(article),
            ),
        ],
        PagingFooter(
          isLoading: _isLoading,
          hasMore: _hasMore,
          onMore: () => _loadMore(),
        ),
      ],
    );
  }
}
