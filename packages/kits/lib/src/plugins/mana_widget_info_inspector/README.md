# 组件检查

点选界面组件，查看 Widget、边界和诊断详情，支持显示布局边界。

```dart
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

final controller = ManaController(plugins: [ManaWidgetInfoInspector()]);
```

仅支持 Debug 构建；检查时会拦截业务触摸事件。

[接入指南](../../../../../../docs/getting-started.md) · [完整示例](../../../../../example/lib/main.dart)
