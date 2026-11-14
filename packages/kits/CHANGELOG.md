# 2.0.0（开发中）

- 内置插件和示例统一为彩色 SVG 图标，移除 PNG base64；面板与悬浮入口使用矢量 Widget，保留按尺寸和像素比生成图像的兼容入口。

- 基于 Flutter 3.50.0 / Dart 3.14.0，将全部插件迁移至 Widgets，移除 Material / Cupertino 导入，不新增 UI 依赖。
- 统一窗口、输入、选择菜单、工具栏、筛选、详情和异步失败／重试布局，支持键盘避让、小屏、大字体与 RTL。
- 将网络与日志采集改为可注入的有界实例；支持独立运行时和可释放的 debugPrint 捕获。
- 记录无响应的网络失败，修正原始请求体、表单、cURL 转义与不可还原上传的处理。
- 偏好编辑改用明确类型与校验；成功保存后再移除旧键，重名保护，清空前确认。
- 修正嵌入坐标、截图释放、触点事件透传、非法网格间距与全局调试开关的恢复。
- 内存诊断显示当前存活大小且不重置 VM 分配统计，移除回调套 Future 和逐函数 RPC；源码改为按脚本浏览。
- 删除旧高亮器、无用页面辅助器及 string_scanner 直接依赖，收敛元数据和本地化逻辑。
- 破坏性变更：采集器不再是单例；业务和插件需显式共享实例，debugPrint 捕获默认关闭。

# 1.4.0

- style: dart format
- chore: update dependencies

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