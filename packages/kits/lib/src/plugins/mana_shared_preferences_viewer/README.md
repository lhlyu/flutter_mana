# 偏好设置

查看、搜索、复制和编辑 SharedPreferences，支持新增、删除及清空。

```dart
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

final controller = ManaController(plugins: [ManaSharedPreferencesViewer()]);
```

面板齿轮设置展示当前加载的键值对总数，不受搜索影响，随刷新及增删改更新，清空后归零。

支持 `String`、`int`、`double`、`bool` 和 `List<String>`；重名写入受保护，清空需确认。

[接入指南](../../../../../../docs/getting-started.md) · [完整示例](../../../../../example/lib/main.dart)
