# Dio 网络检查器

将同一采集器交给 Dio 和插件：

```dart
import 'package:dio/dio.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

final network = ManaDioCollector(capacity: 1000);
final dio = Dio()..interceptors.add(network);
final controller = ManaController(plugins: [ManaDioInspector(collector: network)]);
```

支持方法／关键词筛选、失败记录、请求响应详情和复制。宿主负责卸载拦截器并释放注入的采集器；流式上传无法还原为可执行 cURL 时会显示错误。

完整接入见 [example](../../../../../example/lib/main.dart)。
