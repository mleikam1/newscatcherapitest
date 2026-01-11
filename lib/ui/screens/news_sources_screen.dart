import 'package:flutter/material.dart';

import '../../services/news_service.dart';
import '../widgets/json_viewer.dart';
import '../widgets/section_header.dart';

class NewsSourcesScreen extends StatefulWidget {
  final NewsService news;
  const NewsSourcesScreen({super.key, required this.news});

  @override
  State<NewsSourcesScreen> createState() => _NewsSourcesScreenState();
}

class _NewsSourcesScreenState extends State<NewsSourcesScreen> {
  bool _loading = false;
  Map<String, dynamic>? _json;
  String? _raw;

  final _countries = TextEditingController(text: "US");
  final _languages = TextEditingController(text: "en");

  Future<void> _run() async {
    setState(() => _loading = true);
    final resp = await widget.news.sources(
      countries: _countries.text.trim().isEmpty ? null : _countries.text.trim(),
      languages: _languages.text.trim().isEmpty ? null : _languages.text.trim(),
      page: 1,
      pageSize: 50,
    );
    setState(() {
      _json = resp.json;
      _raw = resp.rawBody;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: "Sources",
          trailing: ElevatedButton(
            onPressed: _loading ? null : _run,
            child: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
                : const Text("Run"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _countries,
                  decoration: const InputDecoration(
                    labelText: "Countries (e.g., US,CA)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _languages,
                  decoration: const InputDecoration(
                    labelText: "Languages (e.g., en,es)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: JsonViewer(json: _json, rawFallback: _raw)),
      ],
    );
  }
}
