# 日志查看器

按级别或关键词筛选日志，支持详情、复制和滚动锁定。Logger 与插件须共享采集器：

```dart
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:logger/logger.dart';

final logs = ManaLogCollector();
final logger = Logger(output: logs);
final controller = ManaController(plugins: [
  ManaLogViewer(collector: logs, captureDebugPrint: true),
]);
```

超限内容会截断或淘汰，复制仅含保留部分。

`debugPrint` 捕获默认关闭，插件释放时恢复；注入的采集器由宿主释放。日志是否输出仍受 Logger 过滤策略影响。

[接入与释放](../../../../../../docs/getting-started.md#网络与日志采集) · [完整示例](../../../../../example/lib/main.dart)
