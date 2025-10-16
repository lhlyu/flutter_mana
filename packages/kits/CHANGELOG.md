# 1.3.1

- feat: add loadAllPlugins function and update version

# 1.3.0

- feat: implement custom syntax highlighting and refactor the code to display components
- chore: update dependencies

# 1.2.0

- feat: add mana_screen_info plugin and documentation
- chore: restrict the development environment

# 1.1.1

- fix: remove activeThumbColor property from Switch

# 1.1.0

- refactor: migrate legacy Flutter project to Dart workspace and streamline codebase
- refactor: improve plugin UI consistency and text selection
- feat: add platform support checks to plugins
- feat: add touch indicator plugin and update UI layouts
- chore: adjust UI layout and dimensions for color sucker and align ruler
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