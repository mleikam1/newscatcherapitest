import 'package:flutter/material.dart';

import '../../services/news_service.dart';
import '../widgets/json_viewer.dart';
import '../widgets/section_header.dart';

class NewsAuthorsScreen extends StatefulWidget {
  final NewsService news;
  const NewsAuthorsScreen({super.key, required this.news});

  @override
  State<NewsAuthorsScreen> createState() => _NewsAuthorsScreenState();
}

class _NewsAuthorsScreenState extends State<NewsAuthorsScreen> {
  final _q = TextEditingController(text: "technology");
  bool _loading = false;
  Map<String, dynamic>? _json;
  String? _raw;
  String _lang = "en";

  Future<void> _run() async {
    setState(() => _loading = true);
    final resp = await widget.news.authors(q: _q.text.trim(), lang: _lang, page: 1, pageSize: 50);
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
        SectionHeader(title: "Authors", trailing: ElevatedButton(
          onPressed: _loading ? null : _run,
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
              : const Text("Run"),
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _q,
                  decoration: const InputDecoration(
                    labelText: "Query (optional)",
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
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: JsonViewer(json: _json, rawFallback: _raw)),
      ],
    );
  }
}
