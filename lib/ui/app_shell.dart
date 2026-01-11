import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/api_client.dart';
import '../services/news_service.dart';
import '../services/local_news_service.dart';
import 'screens/news_search_screen.dart';
import 'screens/news_latest_screen.dart';
import 'screens/news_breaking_screen.dart';
import 'screens/news_authors_screen.dart';
import 'screens/news_similar_screen.dart';
import 'screens/news_sources_screen.dart';
import 'screens/news_agg_screen.dart';
import 'screens/news_subscription_screen.dart';
import 'screens/local_feed_screen.dart';
import 'screens/local_search_screen.dart';
import 'screens/local_sources_screen.dart';
import 'screens/local_search_by_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final ApiClient _client;
  late final NewsService _news;
  late final LocalNewsService _local;

  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _news = NewsService(_client);
    _local = LocalNewsService(_client);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final pages = <Widget>[
      NewsSearchScreen(news: _news),
      NewsLatestScreen(news: _news),
      NewsBreakingScreen(news: _news),
      NewsAuthorsScreen(news: _news),
      NewsSimilarScreen(news: _news),
      NewsSourcesScreen(news: _news),
      NewsAggScreen(news: _news),
      NewsSubscriptionScreen(news: _news),

      LocalFeedScreen(local: _local),
      LocalSearchScreen(local: _local),
      LocalSourcesScreen(local: _local),
      LocalSearchByScreen(local: _local),
    ];

    final labels = <String>[
      "News Search",
      "News Latest",
      "News Breaking",
      "News Authors",
      "News Similar",
      "News Sources",
      "News Agg",
      "News Subscription",
      "Local Near Me",
      "Local Search",
      "Local Sources",
      "Local Search By",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("NewsCatcher POC"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    appState.locationStatus,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => appState.initLocation(),
                  child: const Text("Refresh location"),
                )
              ],
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: ListView.builder(
              itemCount: labels.length,
              itemBuilder: (_, i) {
                final selected = i == _tab;
                return ListTile(
                  selected: selected,
                  title: Text(labels[i]),
                  onTap: () => setState(() => _tab = i),
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[_tab]),
        ],
      ),
    );
  }
}
