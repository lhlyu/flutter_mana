# Flutter Mana

Flutter 应用内调试插件平台，基于基础 Widgets，不依赖 Material / Cupertino UI 包。

## 架构

- **Runtime**：插件、生命周期与状态控制。
- **Storage**：设置持久化，支持自定义存储与命名空间隔离。
- **Widgets**：悬浮入口、插件面板与浮窗。
- **Diagnostics**：可选的 VM 与 Widget 诊断，独立导入。

## 最低版本

Flutter **3.50.0** · Dart **3.14.0**

## 使用

安装：`flutter pub add flutter_mana`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';

void main() => runApp(ManaWidget(
  plugins: [MyPlugin()], // 实现 ManaPluggable
  child: const MyApp(),
));
```

内置插件可选用 `flutter_mana_kits` 的 `loadAllPlugins()`。
已有应用可用 `ManaWidget.builder`：Navigator 配置 `ManaNavigatorObserver`，Router 传入 `backButtonDispatcher`；`overlayBuilder` 为插件提供宿主设计系统环境。

## 功能

- 自定义插件、插件管理与生命周期管理。图标支持 `iconImageProvider`，或覆盖 `buildIcon(context, size: ...)` 返回 SVG／自绘 Widget。
- 浮窗拖动、最小化、全屏及自定义覆盖层。
- 悬浮按钮设置与位置保存。
- 本地化、RTL、键盘及无障碍支持。
- VM 诊断、Widget 检查与命中测试：导入 `flutter_mana_diagnostics.dart`。

更多示例见[项目文档](https://github.com/lhlyu/flutter_mana)。
