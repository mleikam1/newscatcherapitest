import 'package:flutter/material.dart';

import '../../models/article.dart';
import '../../services/news_service.dart';
import '../widgets/article_tile.dart';
import '../widgets/section_header.dart';
import 'raw_response_screen.dart';
import '../../services/api_client.dart';

class NewsLatestScreen extends StatefulWidget {
  final NewsService news;
  const NewsLatestScreen({super.key, required this.news});

  @override
  State<NewsLatestScreen> createState() => _NewsLatestScreenState();
}

class _NewsLatestScreenState extends State<NewsLatestScreen> {
  bool _loading = false;
  List<Article> _articles = [];
  Map<String, dynamic>? _lastJson;
  String? _lastRaw;

  String _lang = "en";
  String _topic = "";

  Future<void> _run() async {
    setState(() => _loading = true);
    final resp = await widget.news.latestHeadlines(
      lang: _lang,
      topic: _topic.isEmpty ? null : _topic,
      page: 1,
      pageSize: 25,
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
          title: "Latest Headlines",
          trailing: TextButton(
            onPressed: (_lastJson == null && _lastRaw == null)
                ? null
                : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RawResponseScreen(
                    title: "Raw: Latest Headlines",
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
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: "Topic (optional)",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _topic = v,
                ),
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
