# Flutter Mana

基于 Flutter Widgets 的应用内调试平台，不依赖 Material / Cupertino。

**环境要求：Flutter 3.50.0+ / Dart 3.14.0+。建议仅在开发环境开启。**

## 接入

```bash
flutter pub add flutter_mana
```

实现 `ManaPluggable` 注册自定义工具，或安装 `flutter_mana_kits` 使用内置工具。已有应用通过 `ManaWidget.builder` 接入；Navigator 配置 `ManaNavigatorObserver`，Router 传入 `backButtonDispatcher`。

[完整接入](../../docs/getting-started.md) · [自定义插件](../../docs/custom-plugins.md) · [示例应用](../example/README.md)

## 架构与能力

| 模块 | 职责 |
| --- | --- |
| Runtime | 插件注册、状态控制、生命周期与失败隔离。 |
| Storage | 设置持久化、自定义存储与命名空间隔离。 |
| Widgets | 悬浮入口、面板、浮窗；支持拖动、最小化、全屏、键盘、RTL 和无障碍。 |
| Diagnostics | 可选的 VM 诊断、Widget 检查与命中测试，单独导入 `flutter_mana_diagnostics.dart`。 |

图标支持图片、SVG 和自绘 Widget；`overlayBuilder` 可为调试层提供设计系统环境。外部传入的控制器由调用方释放。

[项目架构](../../docs/architecture.md) · [文档目录](../../docs/README.md)
