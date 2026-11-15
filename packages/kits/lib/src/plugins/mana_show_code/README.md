# 源代码浏览

搜索当前应用已加载的脚本，查看高亮源码并复制。

```dart
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

final controller = ManaController(plugins: [ManaShowCode()]);
```

仅支持非 Web 的 Debug 构建，需要 VM Service。

[接入指南](../../../../../../docs/getting-started.md) · [完整示例](../../../../../example/lib/main.dart)
