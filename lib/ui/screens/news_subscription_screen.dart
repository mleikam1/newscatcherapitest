import 'package:flutter/material.dart';

import '../../services/news_service.dart';
import '../widgets/json_viewer.dart';
import '../widgets/section_header.dart';

class NewsSubscriptionScreen extends StatefulWidget {
  final NewsService news;
  const NewsSubscriptionScreen({super.key, required this.news});

  @override
  State<NewsSubscriptionScreen> createState() => _NewsSubscriptionScreenState();
}

class _NewsSubscriptionScreenState extends State<NewsSubscriptionScreen> {
  bool _loading = false;
  Map<String, dynamic>? _json;
  String? _raw;

  Future<void> _run() async {
    setState(() => _loading = true);
    final resp = await widget.news.subscription();
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
          title: "Subscription",
          trailing: ElevatedButton(
            onPressed: _loading ? null : _run,
            child: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
                : const Text("Run"),
          ),
        ),
        Expanded(child: JsonViewer(json: _json, rawFallback: _raw)),
      ],
    );
  }
}
