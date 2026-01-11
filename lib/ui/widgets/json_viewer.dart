import 'dart:convert';
import 'package:flutter/material.dart';

class JsonViewer extends StatelessWidget {
  final Map<String, dynamic>? json;
  final String? rawFallback;

  const JsonViewer({super.key, required this.json, required this.rawFallback});

  @override
  Widget build(BuildContext context) {
    final text = (json != null)
        ? const JsonEncoder.withIndent("  ").convert(json)
        : (rawFallback ?? "(no response)");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: "monospace"),
      ),
    );
  }
}
