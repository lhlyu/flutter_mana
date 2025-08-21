# 日志查看器 - LogViewer

> 收集并展示日志。Collect and display logs.

## 使用 - Use

```dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

void main() {
  /// add plugin
  ManaPluginManager.instance.register(ManaLogViewer());

  runApp(ManaWidget(child: App()));
}

/// use logger to set output
final logger = Logger(output: ManaLoggerCollector());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logger',
      home: Scaffold(
          body: ElevatedButton(
            onPressed: () {
              logger.e('error');

              /// use debugPrint
              debugPrint('hello');
            },
            child: const Text('Add Log'),
          ),
        ),
    );
  }
}
```