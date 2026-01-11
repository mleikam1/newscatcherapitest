import 'package:flutter/material.dart';

import '../../models/article.dart';
import '../../services/news_service.dart';
import '../widgets/article_tile.dart';
import '../widgets/section_header.dart';
import 'raw_response_screen.dart';

class NewsSearchScreen extends StatefulWidget {
  final NewsService news;
  const NewsSearchScreen({super.key, required this.news});

  @override
  State<NewsSearchScreen> createState() => _NewsSearchScreenState();
}

class _NewsSearchScreenState extends State<NewsSearchScreen> {
  final _q = TextEditingController(text: "AI AND mobile");
  bool _loading = false;
  String _lang = "en";
  int _page = 1;
  List<Article> _articles = [];
  Map<String, dynamic>? _lastJson;
  String? _lastRaw;

  Future<void> _run() async {
    setState(() => _loading = true);
    final resp = await widget.news.search(
      q: _q.text.trim(),
      lang: _lang,
      page: _page,
      pageSize: 25,
      clustering: true,
      includeNlp: true,
      sortBy: "relevancy",
    );

    final items = (resp.json?["articles"] as List<dynamic>?) ?? const [];
    final parsed = items
        .whereType<Map<String, dynamic>>()
        .map(Article.fromJson)
        .toList();

    setState(() {
      _articles = parsed;
      _lastJson = resp.json;
      _lastRaw = resp.rawBody;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: "News Search",
          trailing: TextButton(
            onPressed: (_lastJson == null && _lastRaw == null)
                ? null
                : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RawResponseScreen(
                    title: "Raw: News Search",
                    response: ApiResponse(
                      status: 200,
                      json: _lastJson,
                      rawBody: _lastRaw,
                    ),
                  ),
                ),
              );
            },
            child: const Text("View raw JSON"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _q,
                  decoration: const InputDecoration(
                    labelText: "Query (q)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _lang,
                items: const [
                  DropdownMenuItem(value: "en", child: Text("en")),
                  DropdownMenuItem(value: "es", child: Text("es")),
                  DropdownMenuItem(value: "fr", child: Text("fr")),
                ],
                onChanged: (v) => setState(() => _lang = v ?? "en"),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loading ? null : _run,
                child: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
                    : const Text("Run"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _articles.isEmpty
              ? const Center(child: Text("No results yet. Run a search."))
              : ListView.builder(
            itemCount: _articles.length,
            itemBuilder: (_, i) => ArticleTile(article: _articles[i]),
          ),
        ),
      ],
    );
  }
}
