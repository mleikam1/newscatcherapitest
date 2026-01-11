import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/article.dart';
import '../../services/local_news_service.dart';
import '../widgets/article_tile.dart';
import '../widgets/section_header.dart';

class LocalSearchScreen extends StatefulWidget {
  final LocalNewsService local;
  const LocalSearchScreen({super.key, required this.local});

  @override
  State<LocalSearchScreen> createState() => _LocalSearchScreenState();
}

class _LocalSearchScreenState extends State<LocalSearchScreen> {
  final _q = TextEditingController(text: "crime OR weather");
  bool _loading = false;
  List<Article> _articles = [];

  Future<void> _run(double lat, double lon) async {
    setState(() => _loading = true);
    final resp = await widget.local.localSearch(
      q: _q.text.trim(),
      lat: lat,
      lon: lon,
      radiusKm: 50,
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
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lat = appState.latitude;
    final lon = appState.longitude;

    return Column(
      children: [
        SectionHeader(
          title: "Local Search (Near Me)",
          trailing: ElevatedButton(
            onPressed: _loading || lat == null || lon == null
                ? null
                : () => _run(lat, lon),
            child: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
                : const Text("Run"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _q,
            decoration: const InputDecoration(
              labelText: "Query (q)",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        if (lat == null || lon == null)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text("Location not ready. Use Refresh location in the header."),
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
