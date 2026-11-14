# Flutter Mana Kits

16 个基于 Flutter Widgets 的调试插件。最低版本：Flutter 3.50.0 / Dart 3.14.0。

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

接入见 [example](../example/lib/main.dart)。
