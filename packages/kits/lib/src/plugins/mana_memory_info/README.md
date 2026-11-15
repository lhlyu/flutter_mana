# 内存信息

查看堆内存、外部内存及类的存活实例统计，支持搜索、排序和详情。

```dart
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

final controller = ManaController(plugins: [ManaMemoryInfo()]);
```

仅支持非 Web 的 Debug 构建，需要 VM Service；读取时不重置分配统计。

[接入指南](../../../../../../docs/getting-started.md) · [完整示例](../../../../../example/lib/main.dart)
