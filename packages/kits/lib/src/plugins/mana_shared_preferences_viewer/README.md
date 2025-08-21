# Shared Preferences查看器 - SharedPreferencesViewer

## 使用 - Use

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

void main() {
  /// add plugin
  ManaPluginManager.instance.register(ManaSharedPreferencesViewer());

  runApp(ManaWidget(child: App()));
}

void addSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('counter', 10);
  await prefs.setBool('repeat', true);
  await prefs.setDouble('decimal', 1.5);
  await prefs.setString('action', 'Start');
  await prefs.setStringList('items', <String>['Earth', 'Moon', 'Sun']);
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shared Preferences Viewer',
      home: Scaffold(
          body: ElevatedButton(
            onPressed: addSharedPreferences,
            child: const Text('Add SharedPreferences'),
          ),
        ),
    );
  }
}
```