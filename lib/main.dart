import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'services/api_client.dart';
import 'ui/app_scaffold.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState()..initLocation(),
        ),
        ChangeNotifierProvider.value(
          value: ApiDiagnostics.instance,
        ),
      ],
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
      home: const AppScaffold(),
    );
  }
}
