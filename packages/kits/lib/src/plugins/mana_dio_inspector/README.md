# Dio 网络检查器

按方法或关键词筛选请求，查看失败记录、请求 / 响应详情，复制 URL、cURL、HTTP 报文或响应。Dio 与插件须共享采集器：

```dart
import 'package:dio/dio.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

final network = ManaDioCollector();
final dio = Dio()..interceptors.add(network);
final controller = ManaController(plugins: [ManaDioInspector(collector: network)]);
```

面板齿轮设置展示当前保留的请求总数、条数上限，以及采集数据的估算大小 / 容量上限，不受搜索和方法筛选影响，清空后归零。

宿主负责卸载拦截器并释放采集器。超限内容会截断或淘汰；导出使用 Dio 默认转换规则，不支持不完整请求、自定义编码器、流和二进制。multipart 仅支持无文件字段的 cURL 重建。

[接入与释放](../../../../../../docs/getting-started.md#网络与日志采集) · [完整示例](../../../../../example/lib/main.dart)
