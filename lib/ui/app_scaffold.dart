import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/local_news_service.dart';
import '../services/news_service.dart';
import 'screens/home_tab_screen.dart';
import 'screens/local_tab_screen.dart';
import 'screens/search_tab_screen.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  late final ApiClient _client;
  late final NewsService _news;
  late final LocalNewsService _local;

  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _news = NewsService(_client);
    _local = LocalNewsService(_client);
  }

  @override
  Widget build(BuildContext context) {
    final titles = ["newscatcher test", "Local", "Search"];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tabIndex]),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          HomeTabScreen(news: _news),
          LocalTabScreen(local: _local),
          SearchTabScreen(news: _news),
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
            icon: Icon(Icons.place_outlined),
            label: "Local",
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
