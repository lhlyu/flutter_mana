# 标尺 - AlignRuler

## 使用 - Use

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

void main() {
  /// add plugin
  ManaPluginManager.instance.register(ManaAlignRuler());

  runApp(ManaWidget(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AlignRuler',
      home: Text('Align Ruler'),
    );
  }
}
```