# Dio网络请求调试工具 - Dio Inspector

> 记得添加网络权限。Remember to add network permissions.

## 使用 - Use

```dart
import 'package:dio/dio.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';


Dio dio = Dio();

/// add interceptor
dio.interceptors.add(ManaDioCollector());

void sendRequest() {
  
  dio.get('https://jsonplaceholder.typicode.com/posts/1').then((response) {}).catchError((
      error) {});
}

void registerPlugin(ManaController controller) {
  controller.registerPlugin(ManaDioInspector());
}
```

宿主接入与 Material 环境配置见[完整示例](../../../../../example/lib/main.dart)。