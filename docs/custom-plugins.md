# 自定义插件

[文档目录](README.md) · [使用指南](getting-started.md)

## 最小可运行示例

实现 `ManaPluggable` 并注册到宿主：

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

覆盖 `iconImageProvider`：

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

图标应遵循传入的 `size`，也可返回自绘 Widget。

## 展示方式与平台限制

| 值 | 用途 |
| --- | --- |
| `ManaPresentation.window` | 默认值，普通工具浮窗。 |
| `ManaPresentation.overlay` | 覆盖层，例如触点或屏幕辅助线。 |
| `ManaPresentation.action` | 一次性操作；执行 `onTrigger` 后结束，不需要提供 Widget。 |

通过 `presentation` 选择展示方式。`ManaFloatingWindow` 可配置 `content` / `barrier` / `setting`、尺寸、位置和拖动；覆盖层应撑满视口，按需拦截触摸事件。

覆盖 `isSupported` 限制平台或构建模式，不支持的插件会禁用。参考 [帧率监控](../packages/kits/lib/src/plugins/mana_fps_monitor/index.dart) 和 [组件检查](../packages/kits/lib/src/plugins/mana_widget_info_inspector/index.dart)。

## 生命周期与动态注册

生命周期见 [ManaPluggable](../packages/core/lib/src/runtime/mana_pluggable.dart)。关闭会话调用 `deactivate()`，最终释放调用 `dispose()`；外部共享资源由宿主释放。

动态管理插件：

```dart
controller.registerPlugin(MyPlugin());
await controller.activatePlugin('my_tool');
await controller.closePlugin();
await controller.unregisterPlugin('my_tool');
```

## 为仓库新增内置 kit

在仓库根目录运行：

```bash
dart run scripts/plugin.dart http_inspector 网络检查器
```

脚本生成工具与导出，不覆盖已有目录，需手动加入 `loadAllPlugins()`。约定见 [Kits 说明](../packages/kits/README.md)，参考 [Demo](../packages/kits/lib/src/plugins/demo/index.dart)。

`BuiltinKit` / `KitWindow` 是仓库内部实现；第三方插件只需依赖公开的 `ManaPluggable`。
