# 公开 API 速查

[文档目录](README.md) · [使用指南](getting-started.md) · [自定义插件](custom-plugins.md)

本文面向应用接入方，集中列出接入、调试层控制、插件管理、设置和数据采集的常用接口。业务代码通过 `ManaController` 发命令，通过 `state` 读取状态。

```dart
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
```

## 获取控制器

创建并长期持有一个控制器，传给 `ManaWidget.builder(controller: controller, child: ...)`；不要在 `build` 中反复创建。控制器只能挂到一个宿主，外部传入时由调用方释放。

```dart
final controller = ManaController(plugins: loadAllPlugins());
```

在 `ManaScope` 的后代中也可以获取控制器：

| 方法 | 说明 |
| --- | --- |
| `ManaScope.of(context)` | 获取控制器并订阅变化，适用于 `build`。 |
| `ManaScope.read(context)` | 获取控制器但不订阅变化，适用于回调或 `initState`。 |

上下文不在 `ManaScope` 下时会抛出 `FlutterError`。应用外部服务可直接持有传给宿主的 controller，无需 `BuildContext`。

## 调试层、面板与窗口

以下方法均在 `ManaController` 上调用：

| 方法 | 返回值 | 说明 |
| --- | --- | --- |
| `toggleOverlay({bool? visible})` | `void` | 不传参数时切换整个调试层的显隐；传 `visible: false / true` 明确隐藏 / 显示。 |
| `openPluginPanel()` | `void` | 打开工具选择面板。 |
| `closePluginPanel()` | `void` | 关闭工具选择面板，不关闭当前插件。 |
| `togglePluginPanel()` | `void` | 切换工具选择面板。 |
| `activatePlugin(String id)` | `Future<bool>` | 初始化并触发指定插件，返回是否成功；`id` 是 `plugin.name`。同一插件重复激活不会重复触发资源，最小化时会恢复窗口。 |
| `closePlugin()` | `Future<void>` | 关闭当前插件并等待清理完成，不注销插件、不关闭工具面板。 |
| `minimizeWindow()` | `void` | 最小化当前插件窗口，不停用插件。 |
| `restoreWindow()` | `void` | 恢复最小化前的普通 / 全屏模式。 |
| `toggleFullscreen()` | `void` | 在普通与全屏模式之间切换；无激活插件时不操作。 |
| `handleBack()` | `bool` | 处理一次调试界面的返回动作，返回是否已消费。隐藏整个调试层时返回 `false`。 |

### 隐藏 / 显示整个调试层

```dart
controller.toggleOverlay();               // 切换
controller.toggleOverlay(visible: false); // 隐藏
controller.toggleOverlay(visible: true);  // 显示
```

- 范围包含悬浮入口、工具选择面板、当前插件及调试 Overlay 内的浮层，不影响业务页面。
- 隐藏时保留插件、窗口和界面状态；恢复时不重新打开插件。
- 隐藏期间调试层不显示、不接收交互、不拦截返回；网络和日志采集仍继续。
- 显隐只存在于当前运行时，不写入偏好设置；新控制器默认显示。
- 隐藏期间仍可调用其他控制方法，它们不会自动显示整个调试层；恢复时展示最新状态。
- 方法是同步状态命令，不会等待屏幕刷新。录屏 / 截图前可自行等待 `await WidgetsBinding.instance.endOfFrame`，录屏结束后何时恢复由接入方决定。
- 隐藏后悬浮入口也不可见，应由业务页面按钮或外部代码恢复。示例首页的“隐藏调试层 / 显示调试层”按钮演示了这一点。

`toggleOverlay` 与 `ManaWidget(enable: false)` 不同：前者保留已挂载的调试组件；后者不构建 Mana 宿主，适合决定是否启用调试功能。

### 监听状态更新按钮

```dart
ListenableBuilder(
  listenable: controller,
  builder: (context, _) => TextButton(
    onPressed: () => controller.toggleOverlay(),
    child: Text(controller.state.overlayVisible ? '隐藏调试层' : '显示调试层'),
  ),
)
```

此片段使用 Material 的 `TextButton`，需由宿主提供对应导入；控制器本身不依赖 Material。按钮应放在业务页面内，而不是调试层内，否则隐藏后无法点它恢复。

## 插件管理与资源释放

`ManaWidget` 启用时自动初始化控制器，通常无需手动初始化。

| `ManaController` 方法 | 返回值 | 说明 |
| --- | --- | --- |
| `initializePlugins()` | `Future<void>` | 等待宿主及已注册插件的初始化完成；插件失败单独记录，不阻塞其他插件。 |
| `retryInitialization()` | `Future<void>` | 重试偏好设置等宿主初始化失败。 |
| `retryPluginInitialization(String id)` | `Future<void>` | 重试指定失败插件的初始化。 |
| `registerPlugin(ManaPluggable plugin)` | `void` | 注册插件；启动后新增的插件会自动初始化。空白 ID、保留 ID 或重复 ID 会报错。 |
| `unregisterPlugin(String id)` | `Future<void>` | 注销并释放插件；若为当前插件，先关闭并等待会话清理。 |
| `close()` | `Future<void>` | 关闭控制器，等待插件释放和设置保存完成。可重复调用。 |
| `dispose()` | `void` | 关闭控制器并启动异步清理；需要等待清理完成时使用 `await close()`。 |

```dart
controller.registerPlugin(MyPlugin());
final opened = await controller.activatePlugin('my_plugin');
if (opened) await controller.closePlugin();
await controller.unregisterPlugin('my_plugin');
```

`MyPlugin` 是接入方实现的 `ManaPluggable`，详见 [自定义插件](custom-plugins.md)。

## 设置与可读状态

| `ManaController` 成员 | 说明 |
| --- | --- |
| `updateSettings({double? buttonSize, double? buttonOpacity, Offset? buttonPosition})` | 更新并异步合并保存悬浮入口设置；须初始化完成。尺寸限制为 `30–100`，透明度为 `0.1–1`，非有限数值忽略。 |
| `flushSettings()` → `Future<void>` | 等待当前待保存的设置写入完成。 |
| `state` → `ManaState` | 当前只读运行时快照。 |
| `plugins` → `ManaPluginRegistry` | 可监听的只读插件注册表。 |
| `isReady` / `isClosed` | 宿主是否完成初始化 / 控制器是否已关闭。 |
| `initializationError` | 最近一次宿主初始化错误；无错误为 `null`。 |
| `canHandleBack` | 当前是否有可处理的调试返回动作；整个调试层隐藏时为 `false`。 |
| `onError` | 可选 `ManaErrorHandler`：`void Function(Object error, StackTrace stack)`。 |
| `addListener(callback)` / `removeListener(callback)` | 订阅 / 取消订阅控制器变化，继承自 `ChangeNotifier`。 |

`ManaState` 字段：

| 字段 | 含义 |
| --- | --- |
| `overlayVisible` | 整个调试层是否允许显示，默认 `true`。 |
| `activePluginId` | 当前插件 ID，无激活插件时为 `null`。 |
| `windowMode` | `ManaWindowMode.normal / minimized / fullscreen`。 |
| `pluginPanelVisible` | 工具选择面板的打开状态。 |
| `windowVisible` | 根据当前插件和窗口模式计算的局部可见状态。 |
| `floatingButtonVisible` | 根据窗口模式、工具面板状态计算的局部入口可见状态。 |
| `settings` | `ManaSettings`：`buttonSize`、`buttonOpacity`、`buttonPosition`。 |

注意：`overlayVisible` 是整体开关；隐藏时仍保留其他局部状态。因此不能只用 `windowVisible`、`floatingButtonVisible` 或 `pluginPanelVisible` 判断屏幕上是否正在显示相应组件。

## 宿主与返回集成

| API | 说明 |
| --- | --- |
| `ManaWidget(child: ..., controller: ..., plugins: ..., enable: ..., overlayBuilder: ...)` | 独立宿主，自带基础 Widgets 应用环境。 |
| `ManaWidget.builder(child: ..., controller: ..., plugins: ..., enable: ..., overlayBuilder: ..., backButtonDispatcher: ...)` | 放入已有应用的 `builder`，复用宿主环境。Router 应传入 dispatcher。 |
| `ManaNavigatorObserver(controller)` | Navigator 返回集成：调试 UI 优先消费返回动作。 |
| `ManaNavigatorObserver.dispose()` | 移除监听和本地历史项；应在关闭 controller 前调用。 |

`controller` 与非空 `plugins` 不可同时传入。省略 controller 时宿主自建并释放控制器；传入时调用方负责释放。`enable` 默认 `true`，`overlayBuilder` 可为整个调试 UI 提供 Theme / Provider 等祖先。

## 查询插件

`controller.plugins` 是 `ManaPluginRegistry`，只提供查询和监听：

| 成员 | 说明 |
| --- | --- |
| `entries` | 不可修改的 `List<ManaPluginInfo>`，每项包含 `plugin`、`status`、`error`、`stackTrace`。 |
| `pluginsMap` | 不可修改的 ID → 插件映射。 |
| `registry[id]` | 查询插件状态，不存在时为 `null`。 |
| `addListener(...)` / `removeListener(...)` | 监听注册表变化。 |

`ManaPluginStatus`：`pending`、`initializing`、`ready`、`unsupported`、`failed`。

注册、注销和激活插件统一使用上文的 `ManaController` 方法。需要开发自己的插件时，见 [自定义插件](custom-plugins.md)。

## 配置偏好存储

控制器默认通过 SharedPreferences 保存悬浮入口设置，也可以在创建时指定存储：

```dart
final controller = ManaController(
  plugins: loadAllPlugins(),
  preferences: ManaStore(namespace: 'my_app'),
);
```

- `ManaStore({String namespace = ''})`：默认持久化存储；指定 namespace 可隔离不同控制器的设置。
- `MemoryManaPreferences()`：不落盘，适用于测试或临时调试。
- 如需自定义存储，可实现 `ManaPreferences` 后传入 `preferences`。

控制器负责存储的载入、设置保存与关闭，接入方无需手动管理。

## 内置工具与采集器

| API | 说明 |
| --- | --- |
| `loadAllPlugins({ManaDioCollector? dioCollector, ManaLogCollector? logCollector, bool captureDebugPrint = false})` | 每次返回新建的 16 个插件；传入与业务共享的采集器，不会自动接管业务 Dio / Logger。 |
| `ManaDioCollector({int capacity = 1000})` | Dio 拦截器，挂到 `dio.interceptors`，同时传给 `ManaDioInspector(collector: ...)`。 |
| `ManaDioCollector.addResponse(response)` | 手动添加响应并记录结束时间。 |
| `ManaLogCollector({int capacity = 1000})` | Logger 的 `output`，同时传给 `ManaLogViewer(collector: ...)`。 |
| `ManaLogCollector.captureDebugPrint()` → `VoidCallback` | 开始采集 `debugPrint`，返回可重复调用的解除采集回调。 |

两种采集器共有：

| 成员 | 说明 |
| --- | --- |
| `data` | 按时间顺序排列的只读数据列表。 |
| `capacity` / `isDisposed` | 最大容量（至少 1）/ 是否已释放。 |
| `add(value)` | 添加一条数据，满容量时丢弃最早记录。 |
| `clear()` | 清空记录。 |
| `addListener(...)` / `removeListener(...)` | 监听数据变化。 |
| `dispose()` | 释放并清空；后续生产者回调会被忽略。日志采集器还会解除其 `debugPrint` 采集。 |

外部传入的采集器由调用方释放，先关闭插件 / controller，再释放共享采集器。插件自行创建的采集器由插件释放。

完整接线见 [网络与日志采集](getting-started.md#网络与日志采集)，各工具的参数和限制见 [内置插件与平台支持](kits.md)。
