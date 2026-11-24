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

请求计时会保留业务 `extra` 内容，并通过新 Map 写入采集时间，兼容只读 Map。URL 无法解析或查询参数无法序列化时，采集器保留可读取的路径预览和响应信息，将快照标记为不完整并禁用 cURL / HTTP 导出，继续传递原始响应或错误。

宿主负责卸载拦截器并释放采集器。释放后的拦截回调仅转发请求和响应，不再采集或写入计时信息。超限内容会截断或淘汰；导出使用 Dio 默认转换规则，不支持不完整请求、自定义编码器、流和二进制。multipart 仅支持无文件字段的 cURL 重建。

[接入与释放](../../../../../../docs/getting-started.md#网络与日志采集) · [完整示例](../../../../../example/lib/main.dart)
