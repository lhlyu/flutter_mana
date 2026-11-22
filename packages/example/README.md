# Flutter Mana Example

16 个内置工具的双页示例。需要 **Flutter 3.50.0+ / Dart 3.14.0+**。

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
- **切页**：两页共享会话和采集器；返回优先处理调试工具，再退出副页。
- **显隐**：页面按钮调用 `controller.toggleOverlay()`，保留状态和采集。
- **数据**：GET、POST、404、Timeout 使用本地 Dio Adapter，无需联网；日志和存储按钮只生成样本，不切换工具。
- **界面**：用标尺、取色、网格和组件检查检查灰阶色板、输入框与圆角；打开动画查看帧耗时。
- **浮层**：弹窗、遮罩和下拉选择。
- **语言**：EN / 中文切换；历史日志不翻译。
- **主题**：顶部黑白图标切换浅色 / 深色。

## 代码与数据

- [main.dart](lib/main.dart)：应用与主页。
- [secondary_page.dart](lib/secondary_page.dart)：副页。
- [demo_session.dart](lib/demo_session.dart)：共享会话与样本。

存储样本只写入 `example.*` 下的五个固定键；网络与日志各最多保留 100 条。共享采集器的接入方式见 [使用指南](../../docs/getting-started.md#网络与日志采集)。

## 重新截图

[截图流程](../../docs/screenshots.md) · [完整预览](../../docs/previews.md)

## 验证

在本目录运行：

```bash
flutter analyze
flutter test
```

[测试](test)。仅供开发或内部演示。
