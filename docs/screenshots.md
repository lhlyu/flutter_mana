# 重新截图

[文档目录](README.md) · [完整预览](previews.md)

使用 **iPhone 模拟器 + 原生 Debug** 截取 16 个工具和面板。原生截图可保留性能图层、放大镜和触点；内存与源码读取真实 VM Service。

## 采集步骤

1. 启动模拟器，在仓库根目录打开终端运行：

   ```bash
   cd packages/example
   flutter run -d <模拟器ID> --debug -t tool/screenshot_app.dart
   ```

2. 等待输出 `Screenshot controller: 127.0.0.1:17931`，另开终端在仓库根目录运行：

   ```bash
   dart run scripts/screenshots.dart --device=<模拟器ID>
   # 可选：--date=2026-11-15，默认当天日期
   ```

3. 完成后退出截图应用，更新 [完整预览](previews.md) 和首页精选图的路径，移除被替换的旧图。

## 采集规则

- 使用 example 的本地请求、日志和五种存储样本；自动演示动画帧耗时、取色、触点和组件选择。
- 状态栏设为 9:41，结束后恢复。
- 保存到 `screenshots/{YYYY-MM-DD}_{kit}.png`，面板名为 `mana_preview`；同日期覆盖，不同日期保留。
- 控制服务仅在独立 Debug 入口启用并绑定本机回环地址，正常 `lib/main.dart` 不启动服务。

自定义端口：应用加 `--dart-define=MANA_SCREENSHOT_PORT=<端口>`，采集脚本加 `--port=<端口>`。
