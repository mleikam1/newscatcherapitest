import 'package:flutter/material.dart';

import '../../services/local_news_service.dart';
import '../widgets/json_viewer.dart';
import '../widgets/section_header.dart';

class LocalSearchByScreen extends StatefulWidget {
  final LocalNewsService local;
  const LocalSearchByScreen({super.key, required this.local});

  @override
  State<LocalSearchByScreen> createState() => _LocalSearchByScreenState();
}

class _LocalSearchByScreenState extends State<LocalSearchByScreen> {
  bool _loading = false;
  Map<String, dynamic>? _json;
  String? _raw;

  // This payload is intentionally generic; adjust based on what your swagger shows.
  final _payload = TextEditingController(text: '''
{
  "q": "high school",
  "lang": "en",
  "page": 1,
  "page_size": 25,
  "country": "US"
}
''');

  Future<void> _run() async {
    setState(() => _loading = true);

    // Parse JSON from text area
    Map<String, dynamic> payload;
    try {
      payload = Map<String, dynamic>.from(
        (await Future.value(_payload.text)).trim().isEmpty
            ? {}
            : (jsonDecodeSafe(_payload.text)),
      );
    } catch (e) {
      setState(() {
        _json = {"error": "Invalid JSON payload: $e"};
        _raw = null;
        _loading = false;
      });
      return;
    }

    final resp = await widget.local.localSearchBy(payload: payload);
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
          title: "Local Search By (Raw Payload)",
          trailing: ElevatedButton(
            onPressed: _loading ? null : _run,
            child: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
                : const Text("Run"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _payload,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: "Payload JSON",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(child: JsonViewer(json: _json, rawFallback: _raw)),
      ],
    );
  }

  // Minimal JSON parse helper without importing extra libs.
  dynamic jsonDecodeSafe(String s) {
    // ignore: avoid_dynamic_calls
    return const _Json().decode(s);
  }
}

// Tiny wrapper to avoid adding an extra dependency.
// Uses dart:convert under the hood.
class _Json {
  const _Json();
  dynamic decode(String input) => json.decode(input);
}

import 'dart:convert';
