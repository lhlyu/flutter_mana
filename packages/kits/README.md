# Flutter Mana Kits

16 个基于 Flutter Widgets 的调试工具，覆盖界面、网络、日志、存储和运行时诊断。

**环境要求：Flutter 3.50.0+ / Dart 3.14.0+。完整体验需原生 Debug 模式。**

[使用指南](../../docs/getting-started.md) · [工具与平台支持](../../docs/kits.md) · [截图预览](../../docs/previews.md)

## 接入

```dart
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

final network = ManaDioCollector();
final logs = ManaLogCollector();
// 业务侧复用：dio.interceptors.add(network); Logger(output: logs);
final controller = ManaController(plugins: loadAllPlugins(
  dioCollector: network,
  logCollector: logs,
  captureDebugPrint: true, // 默认关闭
));
```

将 `controller` 传给 `ManaWidget.builder`。业务和插件须共享采集器；默认各保留 1000 条记录，可通过 `capacity` 调整。外部注入的采集器由宿主释放，详见 [采集与资源释放](../../docs/getting-started.md#网络与日志采集)。

## 新增内置工具

在仓库根目录运行：

```bash
dart run scripts/plugin.dart http_inspector 网络检查器
```

脚本生成 `BuiltinKit`、`KitWindow` / `KitScaffold` 内容及说明，更新导出并格式化，拒绝覆盖已有目录。支持 snake_case、camelCase 和 PascalCase。

- 为 `PluginIcon.demo` 占位图标补充专属 SVG。
- 使用 `kitText` 维护文案。
- 按需手动加入 `loadAllPlugins()`。

第三方插件直接实现公开的 `ManaPluggable`，见 [自定义插件](../../docs/custom-plugins.md)。

## 设计与布局约定

- **图标**：透明背景、鲜艳配色、轮廓易辨；不加底板或统一深色描边，24 px 下保留主要特征。
- **布局**：列表和详情使用 `KitScaffold`。内容按实际约束布局，不预估多行文字高度，不在无界高度中使用 `Expanded`。
- **低高度**：顶部和底部各最多占用 40%，超出部分独立滚动；`KitWindow` 不强设最小内容高度。
- **窄窗口**：宽度不足 160 logical px 时允许横向滚动，不缩小字体或隐藏操作。数据表、偏好和内存条目按宽度换行。
- **状态**：键盘弹出、缩放和切换语言时保留焦点与选中状态。

布局回归见 [responsive_layout_test.dart](test/responsive_layout_test.dart)，覆盖窄窗、低高度、大字体、中英文、RTL 和动态缩放。
