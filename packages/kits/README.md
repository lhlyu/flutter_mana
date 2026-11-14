# Flutter Mana Kits

16 个基于 Flutter Widgets 的调试插件，采用统一的彩色 SVG 图标。最低版本：Flutter 3.50.0 / Dart 3.14.0。

[图标预览](../../screenshots/kits_icons.svg)

## 接入

```dart
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

final network = ManaDioCollector();
final logs = ManaLogCollector();
// dio.interceptors.add(network);
// Logger(output: logs);
final controller = ManaController(plugins: loadAllPlugins(
  dioCollector: network,
  logCollector: logs,
  captureDebugPrint: true, // 默认关闭
));
```

在应用 builder 中接入 `ManaWidget.builder(controller: controller, child: child!)`。Navigator 配置 `ManaNavigatorObserver`；Router 传入 `backButtonDispatcher`。无需 Material / Cupertino 环境。

业务和插件须共享同一个采集器，默认保留 1000 条记录，可通过 `capacity` 调整。宿主释放注入的采集器；插件释放自行创建的资源。

## 功能

- 标尺、网格、取色、触点、视觉辅助。
- 网络请求、失败记录、日志筛选和复制。
- 设备、应用包、屏幕、开源许可信息。
- 偏好查看、编辑、删除。
- Widget 检查、VM 内存、源码浏览。

内存和源码仅支持非 Web 的 Debug 构建；Widget 检查仅支持 Debug，性能叠层不支持 Web。清空偏好需确认。流式或二进制请求体不支持导出 cURL。

## 新增插件

在仓库根目录运行：

```bash
dart run scripts/plugin.dart http_inspector 网络检查器
```

生成 Widgets-only 的 `BuiltinKit`、`KitWindow` / `KitScaffold` 内容和接入说明，自动按顺序补充 `src/plugins/plugins.dart` 导出并格式化。支持 snake_case、camelCase、PascalCase，拒绝覆盖已有目录。

生成的图标暂用 `PluginIcon.demo`，请添加专属 SVG；内容文案通过 `kitText` 维护。是否加入默认的 `loadAllPlugins()` 由维护者手动确认。

## 尺寸与布局

- 列表和详情页使用统一的 `KitScaffold`：顶部搜索 / 筛选、中间内容、底部操作区。正常尺寸按内容自然高度布局；低高度时顶部和底部各最多占用 40%，超出部分独立滚动，避免挤掉列表。
- `KitWindow` 不再用固定的最小内容高度兜底。内容使用真实可用高度，键盘弹出和窗口缩放时保留搜索、焦点及选中状态。
- 宽度不足 160 logical px 时允许横向滚动，不通过缩小字体或隐藏操作来规避溢出。正常宽度按实际约束换行。
- 数据表在窄窗或大字体下改为上下排列；偏好条目将操作按钮移到下方，内存条目将统计信息分组换行。
- 新布局应优先使用自然高度、`Wrap`、可滚动内容和 `KitScaffold`，避免给多行文本估算固定高度，也不要在无界高度中使用 `Expanded`。

尺寸回归测试见 `test/responsive_layout_test.dart`，包含窄窗、横屏低高度、大字体、中英文、RTL 和动态缩放。

接入见 [example](../example/lib/main.dart)。
