# 内置插件与平台支持

[文档目录](README.md) · [完整预览](previews.md)

16 个工具可全部加载或按需注册，见 [使用指南](getting-started.md)。点击工具名查看用法。

## 支持矩阵

原生指 Android、iOS、macOS、Windows、Linux。平台和构建模式须同时满足；✅ 支持，❌ 不支持，⭕️ 部分支持。

| 工具 | 原生 | Web | Debug | Release |
| --- | :---: | :---: | :---: | :---: |
| [对齐标尺](../packages/kits/lib/src/plugins/mana_align_ruler/README.md) | ✅ | ✅ | ✅ | ✅ |
| [日志查看器](../packages/kits/lib/src/plugins/mana_log_viewer/README.md) | ✅ | ✅ | ✅ | ⭕️ |
| [设备信息](../packages/kits/lib/src/plugins/mana_device_info/README.md) | ✅ | ✅ | ✅ | ✅ |
| [颜色吸管](../packages/kits/lib/src/plugins/mana_color_sucker/README.md) | ✅ | ✅ | ✅ | ✅ |
| [Dio 网络检查器](../packages/kits/lib/src/plugins/mana_dio_inspector/README.md) | ✅ | ✅ | ✅ | ✅ |
| [组件检查](../packages/kits/lib/src/plugins/mana_widget_info_inspector/README.md) | ✅ | ✅ | ✅ | ❌ |
| [帧率监控](../packages/kits/lib/src/plugins/mana_fps_monitor/README.md) | ✅ | ❌ | ✅ | ✅ |
| [偏好设置](../packages/kits/lib/src/plugins/mana_shared_preferences_viewer/README.md) | ✅ | ✅ | ✅ | ✅ |
| [源代码浏览](../packages/kits/lib/src/plugins/mana_show_code/README.md) | ✅ | ❌ | ✅ | ❌ |
| [内存信息](../packages/kits/lib/src/plugins/mana_memory_info/README.md) | ✅ | ❌ | ✅ | ❌ |
| [包信息](../packages/kits/lib/src/plugins/mana_package_info/README.md) | ✅ | ✅ | ✅ | ✅ |
| [开源许可](../packages/kits/lib/src/plugins/mana_license/README.md) | ✅ | ✅ | ✅ | ✅ |
| [网格](../packages/kits/lib/src/plugins/mana_grid/README.md) | ✅ | ✅ | ✅ | ✅ |
| [视觉辅助](../packages/kits/lib/src/plugins/mana_visual_helper/README.md) | ✅ | ✅ | ✅ | ⭕️ |
| [触摸指示器](../packages/kits/lib/src/plugins/mana_touch_indicator/README.md) | ✅ | ✅ | ✅ | ✅ |
| [屏幕信息](../packages/kits/lib/src/plugins/mana_screen_info/README.md) | ✅ | ✅ | ✅ | ✅ |

## 使用限制

- **诊断**：内存信息和源代码浏览需要 VM Service；组件检查仅支持 Debug，帧率监控不支持 Web。
- **日志**：输出受 Logger 过滤策略影响，`debugPrint` 捕获默认关闭。
- **视觉辅助**：布局边界、重绘高亮等诊断选项仅在 Debug 可用。
- **平台差异**：设备、包信息字段随平台而异；不支持的工具会在面板中禁用。

采集器和资源管理见 [使用指南](getting-started.md#网络与日志采集)，内置工具开发见 [Kits 约定](../packages/kits/README.md)。仅在开发或内部演示环境使用，避免泄露调试数据。
