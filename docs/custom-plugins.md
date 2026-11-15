# 自定义插件

[文档目录](README.md) · [使用指南](getting-started.md)

## 最小可运行示例

安装 `flutter_mana`，实现 `ManaPluggable` 并注册到宿主。不设置图标时使用 Mana 默认图标。

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';

class MyPlugin extends ManaPluggable {
  @override
  String get name => 'my_tool';

  @override
  String getLocalizedDisplayName(Locale locale) =>
      locale.languageCode == 'zh' ? '自定义工具' : 'My Tool';

  @override
  Widget buildWidget(BuildContext context) => ManaFloatingWindow(
    name: name,
    content: const Center(child: Text('My Tool')),
  );
}

void main() => runApp(ManaWidget(
  plugins: [MyPlugin()],
  child: const Center(child: Text('Example')),
));
```

`name` 是稳定、唯一的插件标识，浮窗须使用同名。已有应用通过 `ManaWidget.builder` 接入，见 [使用指南](getting-started.md#接入已有应用)。

## 图标

### 图片资源

覆盖 `iconImageProvider`，返回 `AssetImage`、`NetworkImage` 或 `MemoryImage`，无需转为 base64：

```dart
@override
ImageProvider get iconImageProvider =>
    const AssetImage('assets/my_plugin.png');
```

在宿主的 `pubspec.yaml` 声明资源：

```yaml
flutter:
  assets:
    - assets/my_plugin.png
```

### SVG 或自绘 Widget

使用 SVG 时，执行 `flutter pub add flutter_svg`，导入 `package:flutter_svg/flutter_svg.dart` 并声明资源，再覆盖：

```dart
@override
Widget buildIcon(BuildContext context, {double size = 40}) =>
    SvgPicture.asset('assets/my_plugin.svg', width: size, height: size);
```

图标用于面板和悬浮入口，应遵循宿主传入的 `size`。也可返回 `CustomPaint` 等自绘 Widget；第三方插件不受内置图标风格限制。

## 展示方式与平台限制

| 值 | 用途 |
| --- | --- |
| `ManaPresentation.window` | 默认值，普通工具浮窗。 |
| `ManaPresentation.overlay` | 覆盖层，例如触点或屏幕辅助线。 |
| `ManaPresentation.action` | 一次性操作；执行 `onTrigger` 后结束，不需要提供 Widget。 |

通过 `presentation` 选择展示方式。`ManaFloatingWindow` 可配置 `content` / `barrier` / `setting`、尺寸、位置和拖动；覆盖层应撑满视口，按需拦截触摸事件。

覆盖 `isSupported` 限制平台或构建模式，不支持的插件会禁用。参考 [帧率监控](../packages/kits/lib/src/plugins/mana_fps_monitor/index.dart) 和 [组件检查](../packages/kits/lib/src/plugins/mana_widget_info_inspector/index.dart)。

## 生命周期与动态注册

| 方法 | 职责 |
| --- | --- |
| `initialize()` | 初始化非 UI 资源，成功后不会在每次打开时重复执行。 |
| `onTrigger()` | 启动本次激活所需的工作。 |
| `deactivate()` | 停止当前会话的工作，例如切换或关闭工具时停止订阅。 |
| `dispose()` | 最终释放插件拥有的资源。 |

生命周期方法支持同步或异步实现。不要在 `buildWidget` 中创建长期订阅；外部共享资源由宿主释放。

动态管理插件：

```dart
controller.registerPlugin(MyPlugin());
await controller.activatePlugin('my_tool');
await controller.closePlugin();
await controller.unregisterPlugin('my_tool');
```

完整协议见 [ManaPluggable](../packages/core/lib/src/runtime/mana_pluggable.dart)。

## 为仓库新增内置 kit

在仓库根目录运行：

```bash
dart run scripts/plugin.dart http_inspector 网络检查器
```

脚本生成工具、内容、说明及导出，不覆盖已有目录，也不自动加入 `loadAllPlugins()`。图标、文案和布局约定见 [Kits 说明](../packages/kits/README.md)，实现可参考 [Demo](../packages/kits/lib/src/plugins/demo/index.dart)。

`BuiltinKit` / `KitWindow` 是仓库内部实现；第三方插件只需依赖公开的 `ManaPluggable`。
