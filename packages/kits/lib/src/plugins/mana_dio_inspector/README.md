# Dio网络请求调试工具 - Dio Inspector

> 记得添加网络权限。Remember to add network permissions.

## 使用 - Use

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';


Dio dio = Dio();

/// add interceptor
dio.interceptors.add(ManaDioCollector());

void sendRequest() {
  
  dio.get('https://jsonplaceholder.typicode.com/posts/1').then((response) {}).catchError((
      error) {});
}

void main() {
  /// add plugin
  ManaPluginManager.instance.register(ManaDioInspector());

  runApp(ManaWidget(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dio Inspector',
      home: Scaffold(
			body: ElevatedButton(
			  onPressed: sendRequest,
			  child: const Text('Send Request'),
			),
		),
    );
  }
}
```