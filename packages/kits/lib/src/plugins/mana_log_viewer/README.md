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

面板齿轮设置展示当前保留的日志总数、条数上限，以及采集数据的估算大小 / 容量上限。一条多行日志按一个事件计数，不受搜索和级别筛选影响，清空后归零；原有详细日志开关保留。

超限内容会截断或淘汰，复制仅含保留部分。新日志到达时不会打断正在进行的手动拖动；需要持续查看历史记录时可锁定自动滚动。

`debugPrint` 捕获默认关闭，插件释放时恢复；注入的采集器由宿主释放。日志是否输出仍受 Logger 过滤策略影响。

[接入与释放](../../../../../../docs/getting-started.md#网络与日志采集) · [完整示例](../../../../../example/lib/main.dart)
