import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/content_aggregation_manager.dart';
import '../services/news_service.dart';
import 'screens/home_tab_screen.dart';
import 'screens/search_tab_screen.dart';
import 'widgets/debug_banner.dart';
import 'widgets/error_utils.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  late final ApiClient _client;
  late final NewsService _news;
  late final ContentAggregationManager _aggregation;

  int _tabIndex = 0;
  List<String> _smokeTestErrors = [];

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _news = NewsService(_client);
    _aggregation = ContentAggregationManager(_news);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSmokeTests();
    });
  }

  Future<void> _runSmokeTests() async {
    final errors = <String>[];
    try {
      await _news.latestHeadlines();
    } catch (e) {
      errors.add(formatApiError(e, endpointName: "news.home"));
    }

    if (!mounted) return;
    setState(() {
      _smokeTestErrors = errors;
    });
  }

  Widget _buildErrorBanner(List<String> errors) {
    if (errors.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      color: Colors.red.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Startup checks failed:"),
            for (final error in errors)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(error),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastErrorBanner(ApiDiagnostics diagnostics) {
    final message = diagnostics.lastErrorMessage;
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      color: Colors.red.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        "Last API error: $message",
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ["newscatcher test", "Search"];
    final diagnostics = context.watch<ApiDiagnostics>();

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tabIndex]),
      ),
      body: Column(
        children: [
          _buildErrorBanner(_smokeTestErrors),
          _buildLastErrorBanner(diagnostics),
          DebugBanner(diagnostics: diagnostics),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                HomeTabScreen(aggregation: _aggregation),
                SearchTabScreen(news: _news),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (value) => setState(() => _tabIndex = value),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Search",
          ),
        ],
      ),
    );
  }
}
