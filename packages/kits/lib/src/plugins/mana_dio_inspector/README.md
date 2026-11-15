# Dio 网络检查器

按方法或关键词筛选请求，查看失败记录、请求 / 响应详情，复制 URL、cURL、HTTP 报文或响应。Dio 与插件须共享采集器：

```dart
import 'package:dio/dio.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

final network = ManaDioCollector(capacity: 1000);
final dio = Dio()..interceptors.add(network);
final controller = ManaController(plugins: [ManaDioInspector(collector: network)]);
```

宿主负责卸载拦截器并释放注入的采集器。流式或二进制请求体无法还原为可执行 cURL 时会报错。

[接入与释放](../../../../../../docs/getting-started.md#网络与日志采集) · [完整示例](../../../../../example/lib/main.dart)
