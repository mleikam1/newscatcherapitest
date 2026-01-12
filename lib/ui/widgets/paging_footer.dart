import 'package:flutter/material.dart';

class PagingFooter extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onMore;

  const PagingFooter({
    super.key,
    required this.isLoading,
    required this.hasMore,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore && !isLoading) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ElevatedButton(
          onPressed: (isLoading || !hasMore) ? null : onMore,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("More"),
        ),
      ),
    );
  }
}
