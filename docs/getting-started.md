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

在应用的 `builder` 中使用 `ManaWidget.builder`，复用主题和本地化环境。以下 Material 示例需先执行 `flutter pub add material_ui`；`WidgetsApp` / `CupertinoApp` 接入方式相同，无需额外引入 Material。

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

点击 Mana 悬浮按钮选择工具。窗口支持拖动、最小化和全屏；入口大小、透明度和位置可在设置中调整。

### 代码控制与临时隐藏

持有传给宿主的 `controller`，即可由业务代码控制调试界面：

```dart
controller.toggleOverlay();               // 切换整个调试层的显隐
controller.toggleOverlay(visible: false); // 隐藏，包括悬浮入口
controller.toggleOverlay(visible: true);  // 恢复
await controller.closePlugin();           // 只关闭当前插件
```

隐藏保留插件和窗口状态，不影响业务页面，也不停止网络 / 日志采集；恢复应由业务按钮或外部代码触发。显隐不持久化。录屏前如需等待隐藏绘制完成，可自行等待 `await WidgetsBinding.instance.endOfFrame`。

所有控制方法及区别见 [公开 API 速查](api.md)。

### 返回行为与 Router

- **Navigator**：配置 `ManaNavigatorObserver`，让调试界面优先处理返回。
- **Router**：把宿主的 `BackButtonDispatcher` 传给 `ManaWidget.builder(backButtonDispatcher: ...)`，由子 dispatcher 处理返回。
- **设计系统**：通过 `overlayBuilder` 为调试层补充 Theme / Provider 等祖先。

### 独立宿主与按需加载

独立宿主可直接注册所需工具：

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

**业务和插件必须共享采集器**，`loadAllPlugins()` 不会自动接管 Dio / Logger。先执行 `flutter pub add dio logger`，再将以下对象放在 State 或服务类中统一管理：

```dart
import 'package:dio/dio.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:logger/logger.dart';

final network = ManaDioCollector(capacity: 1000);
final logs = ManaLogCollector(capacity: 1000);
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

- 每个采集器默认保留 1000 条记录，`capacity` 可调整容量。
- `captureDebugPrint` 默认关闭，插件释放时恢复原行为。
- 外部注入的采集器由宿主释放；插件自行创建的由插件释放。

需要等待关闭完成时，在业务服务中异步清理：

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
