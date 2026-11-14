# 日志查看器

将同一采集器交给 Logger 和插件：

```dart
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:logger/logger.dart';

final logs = ManaLogCollector(capacity: 1000);
final logger = Logger(output: logs);
final controller = ManaController(plugins: [
  ManaLogViewer(collector: logs, captureDebugPrint: true),
]);
```

支持级别／关键词筛选、详细日志、滚动锁定和复制。debugPrint 捕获默认关闭，插件释放时自动恢复；注入的采集器由宿主释放。

完整接入见 [example](../../../../../example/lib/main.dart)。
