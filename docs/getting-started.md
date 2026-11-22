# 使用指南

[文档目录](README.md) · [内置插件](kits.md) · [自定义插件](custom-plugins.md)

## 环境与安装

需要 **Flutter 3.50.0+ / Dart 3.14.0+**。

```bash
flutter pub add flutter_mana
flutter pub add flutter_mana_kits
```

`flutter_mana` 是核心平台，`flutter_mana_kits` 提供 16 个可选工具。建议仅在开发环境开启；完整体验需**原生 Debug 模式**，见 [支持矩阵](kits.md)。

## 接入已有应用

在应用 `builder` 中接入。以下示例需安装 `material_ui`；`WidgetsApp` / `CupertinoApp` 接入方式相同。

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final controller = ManaController(plugins: loadAllPlugins());
  late final observer = ManaNavigatorObserver(controller);

  @override
  void dispose() {
    observer.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorObservers: [observer],
    home: const Scaffold(body: Center(child: Text('Example'))),
    builder: (context, child) => ManaWidget.builder(
      controller: controller,
      enable: kDebugMode,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
```

点击悬浮按钮选择工具，入口外观可在设置中调整。设置中的“显示调试浮层”开关可临时隐藏悬浮入口及工具窗口，下次启动自动显示；日志和网络采集继续运行。本次运行中如需恢复，可从业务入口调用 `controller.toggleOverlay(visible: true)`。

### 代码控制与临时隐藏

```dart
controller.toggleOverlay();
controller.toggleOverlay(visible: false);
controller.toggleOverlay(visible: true);
await controller.closePlugin();
```

隐藏保留状态和采集，需由业务入口恢复；显隐不持久化。录屏前可等待 `WidgetsBinding.instance.endOfFrame`。其他方法见 [API](api.md)。

### 返回行为与 Router

- **Navigator**：配置 `ManaNavigatorObserver`，让调试界面优先处理返回。
- **Router**：把宿主的 `BackButtonDispatcher` 传给 `ManaWidget.builder(backButtonDispatcher: ...)`，由子 dispatcher 处理返回。
- **设计系统**：通过 `overlayBuilder` 为调试层补充 Theme / Provider 等祖先。

### 独立宿主与按需加载

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

void main() => runApp(ManaWidget(
  plugins: [ManaGrid(), ManaScreenInfo()],
  child: const Center(child: Text('Example')),
));
```

传 `plugins` 时，宿主创建并释放控制器；传 `controller` 时，由调用方释放，两者不可同时传入。一个控制器只能挂到一个宿主上，不要在 `build` 中重复创建控制器或调用 `loadAllPlugins()`。

## 网络与日志采集

安装 `dio logger`，在 State 或服务类中创建共享实例：

```dart
import 'package:dio/dio.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:logger/logger.dart';

final network = ManaDioCollector();
final logs = ManaLogCollector();
final dio = Dio()..interceptors.add(network);
final logger = Logger(output: logs);
final controller = ManaController(
  plugins: loadAllPlugins(
    dioCollector: network,
    logCollector: logs,
    captureDebugPrint: true,
  ),
);
```

把 `controller` 传给 `ManaWidget.builder`，业务使用同一组 `dio` / `logger`。

采集器容量见 [API](api.md#内置工具与采集器)。`captureDebugPrint` 默认关闭；外部注入资源由宿主释放。

异步清理：

```dart
Future<void> closeDebugTools() async {
  dio.close(force: true);
  await controller.close();
  await logger.close();
  network.dispose();
  logs.dispose();
}
```

如有 `ManaNavigatorObserver`，先释放 observer。完整实现见 [DemoSession](../packages/example/lib/demo_session.dart)。

## 运行仓库示例

在仓库根目录执行：

```bash
flutter pub get
cd packages/example
flutter run -d macos
# 或 flutter run -d chrome / 移动设备 ID
```

示例无需联网，操作见 [example 说明](../packages/example/README.md)，效果见 [完整预览](previews.md)。
