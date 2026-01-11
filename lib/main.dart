import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'ui/app_shell.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..initLocation(),
      child: const NewscatcherPocApp(),
    ),
  );
}

class NewscatcherPocApp extends StatelessWidget {
  const NewscatcherPocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewsCatcher POC',
      theme: ThemeData(useMaterial3: true),
      home: const AppShell(),
    );
  }
}
