import 'package:flutter/material.dart';

import '../../services/news_service.dart';
import '../widgets/json_viewer.dart';
import '../widgets/section_header.dart';

class NewsAggScreen extends StatefulWidget {
  final NewsService news;
  const NewsAggScreen({super.key, required this.news});

  @override
  State<NewsAggScreen> createState() => _NewsAggScreenState();
}

class _NewsAggScreenState extends State<NewsAggScreen> {
  bool _loading = false;
  Map<String, dynamic>? _json;
  String? _raw;

  final _q = TextEditingController(text: "NFL OR NBA");
  String _aggBy = "country";
  String _lang = "en";

  Future<void> _run() async {
    setState(() => _loading = true);
    final resp = await widget.news.aggregationCount(
      q: _q.text.trim(),
      lang: _lang,
      aggBy: _aggBy,
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
          title: "Aggregation Count",
          trailing: ElevatedButton(
            onPressed: _loading ? null : _run,
            child: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
                : const Text("Run"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              TextField(
                controller: _q,
                decoration: const InputDecoration(
                  labelText: "Query (q)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
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
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _aggBy,
                    items: const [
                      DropdownMenuItem(value: "country", child: Text("agg_by=country")),
                      DropdownMenuItem(value: "language", child: Text("agg_by=language")),
                      DropdownMenuItem(value: "topic", child: Text("agg_by=topic")),
                      DropdownMenuItem(value: "source", child: Text("agg_by=source")),
                    ],
                    onChanged: (v) => setState(() => _aggBy = v ?? "country"),
                  ),
                ],
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
