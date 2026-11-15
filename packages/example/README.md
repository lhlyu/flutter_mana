# Flutter Mana Example

展示全部 16 个内置工具的黑白单页示例。**Flutter 3.50.0+ / Dart 3.14.0+**。

## 运行

在仓库根目录执行：

```bash
flutter pub get
cd packages/example
flutter run -d macos
# 或 flutter run -d chrome / 移动设备 ID
```

完整体验请用**原生 Debug 模式**。Web 不支持帧率监控、内存信息和源代码浏览；不支持的工具会自动禁用。

## 体验

- **工具**：点击 Mana 悬浮按钮打开面板。
- **数据**：GET、POST、404、Timeout 使用本地 Dio Adapter，无需联网；日志和存储按钮只生成样本，不切换工具。
- **界面**：用标尺、取色、网格和组件检查检查灰阶色板、输入框与圆角；打开动画查看帧耗时。
- **浮层**：测试弹窗确认、取消、点击遮罩关闭及下拉选择。下拉选项在切换语言、主题后保留。
- **语言**：EN / 中文同步切换应用和工具文案，保留已打开工具及数据；历史日志不翻译。
- **主题**：顶部黑白图标切换浅色 / 深色。

## 代码与数据

- [main.dart](lib/main.dart)：应用环境、`ManaWidget.builder`、返回行为与单页界面；少量双语文案使用 `t(en, zh)`。
- [demo_session.dart](lib/demo_session.dart)：共享 Dio / Logger 采集器、控制器与样本数据，统一释放资源并恢复 `debugPrint`。

存储样本只写入 `example.*` 下的五个固定键；网络与日志各最多保留 100 条。共享采集器的接入方式见 [使用指南](../../docs/getting-started.md#网络与日志采集)。

## 重新截图

[截图流程](../../docs/screenshots.md) · [完整预览](../../docs/previews.md)

## 验证

在本目录运行：

```bash
flutter analyze
flutter test
```

[测试](test) 覆盖工具入口、数据采集、语言 / 主题切换、浮层交互、小屏大字体及资源释放。示例仅用于开发或内部演示，不向生产用户暴露调试数据。
