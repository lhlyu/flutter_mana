# 帧率监控

显示 Raster / UI 每帧耗时，辅助排查卡顿。

```dart
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

final controller = ManaController(plugins: [ManaFpsMonitor()]);
```

仅支持原生平台，不支持 Web。

[接入指南](../../../../../../docs/getting-started.md) · [完整示例](../../../../../example/lib/main.dart)
