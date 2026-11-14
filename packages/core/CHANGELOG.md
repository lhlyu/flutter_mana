# 2.0.0（开发中）

- 新增可覆盖的 `buildIcon`，面板与悬浮入口支持自定义 Widget 图标，兼容原有 `iconImageProvider`，缺省使用 Mana 图标。

- 以 Flutter 3.50.0 / Dart 3.14.0 为最低版本。
- 用实例级 ManaController、不可变状态和统一命令取代全局单例与可写通知器。
- 插件注册表只读，支持逐插件初始化、失败隔离与重试、动态注册和生命周期清理。
- 引入可注入的 ManaPreferences，分离设置模型、内存实现与 SharedPreferences 适配器。
- 新增 ManaWidget.builder、设计系统 overlayBuilder，以及 Navigator / Router 返回键集成。
- 将诊断能力移至 flutter_mana_diagnostics.dart，VM 连接实例化并提供 Web 条件导出。
- 同步迁移 kits 与 example，补充运行时、回归、宿主集成和诊断测试。
- 将 core UI 迁移至 Flutter Widgets 层，移除 Material / Cupertino 导入，不新增设计系统包依赖。
- 使用 WidgetsApp 保留浮层、路由、返回键和 Widgets 本地化，并缓存入口初始化任务。
- 使用基础按钮、滑块、RawTooltip 和绘制图标实现调试面板，支持键盘和无障碍操作。
- 修复确认按钮的异步等待、忙碌态、异常上报及销毁后的计时器处理。
- 修复普通浮窗最小化后的遮罩与返回键拦截，关闭管理面板不再关闭当前插件；保留插件自定义覆盖层。
- 修复小窗口坐标边界、悬浮按钮通知器泄漏、浮窗缩放重置位置及异常持久化配置。
- 合并设置项构建逻辑，滑块去重并统一无障碍单位；插件网格按需构建，适配大字体。
- 支持运行时语言切换和 Widgets 支持的 RTL 布局，初始化失败显式上报。
- 破坏性变更：CheckIconButton 移除 ButtonStyle 参数，改用 padding、constraints 和 decoration。
- 破坏性变更：不再为插件自动提供 Material 祖先、主题或设计系统本地化，插件应自行配置。

# 1.4.0

- fix: [issues#29](https://github.com/lhlyu/flutter_mana/issues/29)
- style: dart format

# 1.3.0

- chore: update dependencies

# 1.2.0

- chore: restrict the development environment

# 1.1.0

- refactor: migrate legacy Flutter project to Dart workspace and streamline codebase
- feat: add platform support checks to plugins and update docs
- style: reduce icon size

# 1.0.4

- feat: add mana_visual_helper plugin and documentation
- style: dart format

# 1.0.3

- fix: mana_grid bug

# 1.0.2

- feat: add mana_grid plugin and documentation

# 1.0.1

- refactor(ui): preserve state when switching panels
- feat: add mana_license plugin and documentation
- chore: update dependencies and adjust ui
- style: dart format

# 1.0.0

## 首个正式版本发布！

### 插件

- **ManaPackageInfo**：显示应用包信息（版本号、构建号等）。
- **ManaMemoryInfo**：查看内存信息。
- **ManaShowCode**：展示当前页面源码，仅在 Debug 模式生效。
- **ManaLogViewer**：实时日志查看器，支持分类筛选。
- **ManaDeviceInfo**：展示设备硬件、系统信息。
- **ManaColorSucker**：屏幕吸色器，调试颜色取样。
- **ManaDioInspector**：支持 Dio 拦截与请求详情查看。
- **ManaWidgetInfoInspector**：快速查看 Widget 树信息、布局详情。
- **ManaFpsMonitor**：帧率实时监控，辅助性能优化。
- **ManaSharedPreferencesViewer**：以 key-value 方式查看本地缓存。
- **ManaAlignRuler**：标尺工具，辅助对齐与布局调试。