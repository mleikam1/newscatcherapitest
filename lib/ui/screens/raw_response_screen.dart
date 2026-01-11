import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../widgets/json_viewer.dart';

class RawResponseScreen extends StatelessWidget {
  final String title;
  final ApiResponse response;

  const RawResponseScreen({
    super.key,
    required this.title,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    final ok = response.status >= 200 && response.status < 300;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: ok ? Colors.green.shade50 : Colors.red.shade50,
            child: Text("HTTP ${response.status}"),
          ),
          Expanded(
            child: JsonViewer(json: response.json, rawFallback: response.rawBody),
          ),
        ],
      ),
    );
  }
}
