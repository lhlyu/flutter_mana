# Flutter Mana Example

极简黑白单页示例，展示 `flutter_mana` 接入与全部 16 个 kits。Flutter 3.50+ / Dart 3.14+。

## 运行

```bash
flutter pub get
cd packages/example
flutter run -d macos
# 或 flutter run -d chrome / 移动设备 ID
```

完整体验请使用**原生 Debug 模式**。Web 不支持 FPS，内存与源码浏览需要原生 Debug 的 VM Service；不可用的工具会自动禁用。

## 怎么试

- **打开工具**：统一通过 Mana 悬浮按钮进入工具面板，页面不提供重复的工具入口。
- **生成数据**：GET、POST、404、Timeout 使用本地 Dio Adapter，无需联网。日志和存储按钮只生成样本，不打开或切换工具；从悬浮面板进入对应工具查看结果。
- **检查界面**：用标尺、取色、网格、组件检查器检查灰阶色板、输入框和圆角样本；打开动画后可测试 FPS。
- **弹窗与下拉菜单**：点击「Open dialog / 打开弹窗」体验确认、取消和点击遮罩关闭；确认后显示提示。下拉菜单可选择默认、紧凑、舒适三种示例选项，切换语言或主题后保留选择，可配合 Mana 工具检查浮层。
- **测试 i18n**：顶部 **EN / 中文** 切换真实的 `MaterialApp.locale`，应用、工具名称与工具内部文案一起切换。可以保持网格等工具打开，对比切换前后的效果，控制器与测试数据不重置。示例不引入额外翻译框架，少量界面文案直接在 `t(en, zh)` 中声明。
- **切换主题**：顶部黑白图标切换浅色 / 深色。

## 代码只有两个文件

```text
lib/
  main.dart          # MaterialApp、Locale、ManaWidget.builder 和单页界面
  demo_session.dart  # 共享 Collectors、Controller、Dio / Logger / 存储样本
```

接入重点在 `DemoSession`：业务侧的 Dio、Logger 与 `loadAllPlugins` 必须共享同一组 Collectors。`main.dart` 将 Controller 传给 `ManaWidget.builder`，并用 `ManaNavigatorObserver` 处理返回行为。

存储样本仅写入 `example.*` 下的五个固定键，不清空其他数据。网络和日志各最多保留 100 条。样本日志保留中英文原文，切换语言不会翻译历史记录。

应用退出时释放 Controller、Logger 和 Collectors，恢复被捕获的 `debugPrint`。此示例仅用于开发 / 内部演示，不要向生产用户暴露调试数据。

## 验证

```bash
flutter analyze
flutter test
```

测试包括悬浮面板入口、生成数据不切换工具、已打开工具的实时语言切换、小屏大字体、主题、输入 / 动画、弹窗确认 / 取消 / 遮罩关闭、下拉菜单选择与语言切换、Dio 成功与异常、五种存储类型、日志捕获与资源释放。
