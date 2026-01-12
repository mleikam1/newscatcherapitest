import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/api_client.dart';

class DebugBanner extends StatelessWidget {
  final ApiDiagnostics diagnostics;

  const DebugBanner({super.key, required this.diagnostics});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall;

    return Container(
      width: double.infinity,
      color: Colors.blueGrey.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: DefaultTextStyle(
        style: textStyle?.copyWith(color: Colors.white70) ??
            const TextStyle(color: Colors.white70),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Worker: ${diagnostics.workerBaseUrl}"),
            Text("Last URL: ${diagnostics.lastRequestUrl ?? "—"}"),
            Text("Last status: ${diagnostics.lastStatus?.toString() ?? "—"}"),
            Text("Last error: ${diagnostics.lastErrorMessage ?? "—"}"),
          ],
        ),
      ),
    );
  }
}
