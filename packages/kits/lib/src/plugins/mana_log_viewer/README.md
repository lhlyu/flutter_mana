# 日志查看器 - LogViewer

> 收集并展示日志。Collect and display logs.

## 使用 - Use

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

void registerPlugin(ManaController controller) {
  controller.registerPlugin(ManaLogViewer());
}
```

宿主接入与 Material 环境配置见[完整示例](../../../../../example/lib/main.dart)。