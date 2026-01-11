import 'package:flutter/material.dart';

import '../../models/article.dart';
import '../../services/news_service.dart';
import '../widgets/article_tile.dart';
import '../widgets/section_header.dart';
import 'raw_response_screen.dart';
import '../../services/api_client.dart';

class NewsSimilarScreen extends StatefulWidget {
  final NewsService news;
  const NewsSimilarScreen({super.key, required this.news});

  @override
  State<NewsSimilarScreen> createState() => _NewsSimilarScreenState();
}

class _NewsSimilarScreenState extends State<NewsSimilarScreen> {
  final _q = TextEditingController(text: "Apple earnings");
  final _url = TextEditingController(text: "");
  bool _loading = false;
  List<Article> _articles = [];
  Map<String, dynamic>? _lastJson;
  String? _lastRaw;

  Future<void> _run() async {
    setState(() => _loading = true);
    final resp = await widget.news.searchSimilar(
      q: _q.text.trim().isEmpty ? null : _q.text.trim(),
      url: _url.text.trim().isEmpty ? null : _url.text.trim(),
      page: 1,
      pageSize: 25,
      lang: "en",
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
          title: "Search Similar",
          trailing: TextButton(
            onPressed: (_lastJson == null && _lastRaw == null)
                ? null
                : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RawResponseScreen(
                    title: "Raw: Search Similar",
                    response: ApiResponse(status: 200, json: _lastJson, rawBody: _lastRaw),
                  ),
                ),
              );
            },
            child: const Text("View raw JSON"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              TextField(
                controller: _q,
                decoration: const InputDecoration(
                  labelText: "Query (q) (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _url,
                decoration: const InputDecoration(
                  labelText: "URL (optional, if supported)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: _loading ? null : _run,
                  child: _loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
                      : const Text("Run"),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _articles.isEmpty
              ? const Center(child: Text("No results yet."))
              : ListView.builder(
            itemCount: _articles.length,
            itemBuilder: (_, i) => ArticleTile(article: _articles[i]),
          ),
        ),
      ],
    );
  }
}
