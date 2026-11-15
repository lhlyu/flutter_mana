# 源代码浏览

打开工具后自动定位当前可见路由中的页面组件，直接展示该组件定义所在 Dart 文件的高亮源码，并支持复制。不再提供全应用脚本列表或搜索入口。

定位仅遍历宿主应用，不包含 Mana 工具浮层；跳过非当前路由、Offstage 和 IndexedStack 的非活动页面。嵌套路由优先定位内层页面。没有 Navigator 时，使用宿主中的首个应用组件。

读取的是组件类的定义文件，而不是创建组件的调用位置；找不到页面时显示提示，不回退到任意脚本。源码在每次打开工具时定位，切换页面后重新打开即可查看新页面。

```dart
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

final controller = ManaController(plugins: [ManaShowCode()]);
```

仅支持非 Web 的 Debug 构建，需要 VM Service。

[接入指南](../../../../../../docs/getting-started.md) · [完整示例](../../../../../example/lib/main.dart)
