# 视觉辅助

调整动画速度；Debug 模式下可显示布局边界、重绘高亮并反转超大图片。

```dart
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

final controller = ManaController(plugins: [ManaVisualHelper()]);
```

关闭工具后恢复原有调试设置。

[接入指南](../../../../../../docs/getting-started.md) · [完整示例](../../../../../example/lib/main.dart)
