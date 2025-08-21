# Flutter Mana

[![pub package](https://img.shields.io/pub/v/flutter_mana?label=flutter_mana)](https://pub.dev/packages/flutter_mana)
[![pub package](https://img.shields.io/pub/v/flutter_mana_kits?label=flutter_mana_kits)](https://pub.dev/packages/flutter_mana_kits)
![Last Commit](https://img.shields.io/github/last-commit/lhlyu/flutter_mana)

Flutter 应用内调试工具平台.
an in-app debug kits platform for Flutter.

> 因为flutter_ume不维护，项目因此而生，`mana`的名字来自于一部国漫《灵笼》中的玛娜设定，强烈推荐！


**尽量在开发环境使用，部分插件只在开发环境才能生效！！！**

## 使用

- 安装

```shell
flutter pub add flutter_mana
flutter pub add flutter_mana_kits
```

- 代码中使用

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';


void main() async {
  ManaPluginManager.instance
    ..register(ManaVisualHelper())
    ..register(ManaGrid())
    ..register(ManaLicense())
    ..register(ManaPackageInfo())
    ..register(ManaMemoryInfo())
    ..register(ManaShowCode())
    ..register(ManaLogViewer())
    ..register(ManaDeviceInfo())
    ..register(ManaColorSucker())
    ..register(ManaDioInspector())
    ..register(ManaWidgetInfoInspector())
    ..register(ManaFpsMonitor())
    ..register(ManaSharedPreferencesViewer())
    ..register(ManaAlignRuler());

  runApp(ManaWidget(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Example',
      home: Text('Example'),
    );
  }
}
```

## 插件&使用

```
✅ - 支持
❌ - 不支持
⭕️ - 部分支持
```


| 插件&文档                                                                                                                                                            | android | ios | macos | windows | linux | web | debug | release |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|-----|-------|---------|-------|-----|-------|---------|
| [标尺 - AlignRuler](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_align_ruler)                                              | ✅       | ✅   | ✅     | ✅       | ✅     | ✅   | ✅     | ✅       |
| [日志查看器 - LogViewer](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_logger)                                                 | ✅       | ✅   | ✅     | ✅       | ✅     | ✅   | ✅     | ⭕️      |
| [设备信息 - DeviceInfo](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_device_info)                                            | ✅       | ✅   | ✅     | ✅       | ✅     | ✅   | ✅     | ✅       |
| [颜色吸管 - ColorSucker](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_color_sucker)                                          | ✅       | ✅   | ✅     | ✅       | ✅     | ✅   | ✅     | ✅       |
| [Dio网络检查器 - DioInspector](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_dio)                                              | ✅       | ✅   | ✅     | ✅       | ✅     | ✅   | ✅     | ✅       |
| [Widget详情 - WidgetInfoInspector](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_widget_info_inspector)                     | ✅       | ✅   | ✅     | ✅       | ✅     | ✅   | ✅     | ❌       |
| [帧率监控 - FpsMonitor](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_fps_monitor)                                            | ✅       | ✅   | ✅     | ✅       | ✅     | ❌   | ✅     | ✅       |
| [SharedPreferences查看器 - SharedPreferencesViewer](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_shared_preferences_viewer) | ✅       | ✅   | ✅     | ✅       | ✅     | ✅   | ✅     | ✅       |
| [显示代码 - ShowCode](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_show_code)                                                | ✅       | ✅   | ✅     | ✅       | ✅     | ❌   | ✅     | ❌       |
| [内存信息 - MemoryInfo](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_memory_info)                                            | ✅       | ✅   | ✅     | ✅       | ✅     | ❌   | ✅     | ❌       |
| [包信息 - PackageInfo](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_package_info)                                           | ✅       | ✅   | ✅     | ✅       | ✅     | ✅   | ✅     | ✅       |
| [许可 - License](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_license)                                                     | ✅       | ✅   | ✅     | ✅       | ✅     | ✅   | ✅     | ✅       |
| [网格 - Grid](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_grid)                                                           | ✅       | ✅   | ✅     | ✅       | ✅     | ✅   | ✅     | ✅       |
| [视觉辅助 - VisualHelper](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_visual_helper)                                        | ✅       | ✅   | ✅     | ✅       | ✅     | ✅   | ✅     | ⭕️      |




| 插件                                                                                                                    |                                                                                                                                                    |                                                                                                                          |
|-----------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| 面板                                                                                                                    | 日志查看器                                                                                                                                              | 设备信息                                                                                                                     |
| <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_preview.png" alt="面板">        | <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_log_viewer.png" alt="日志查看器">                               | <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_device_info.png" alt="设备信息">     |
| 颜色吸管                                                                                                                  | Dio网络检查器                                                                                                                                           | Widget详情                                                                                                                 |
| <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_color_sucker.png" alt="颜色吸管"> | <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_dio_inspector.png" alt="Dio网络检查器">                         | <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_widget_info.png" alt="Widget详情"> |
| 帧率监控                                                                                                                  | SharedPreferences查看器                                                                                                                               | 标尺                                                                                                                       |
| <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_fps_monitor.png" alt="帧率监控">  | <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_shared_preferences_viewer.png" alt="SharedPreferences查看器"> | <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_align_ruler.png" alt="标尺">       |
| 显示代码                                                                                                                  | 内存信息                                                                                                                                               | 包信息                                                                                                                      |
| <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_show_code.png" alt="显示代码">    | <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_memory_info.png" alt="内存信息">                               | <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_package_info.png" alt="包信息">     |
| 许可                                                                                                                    | 网格                                                                                                                                                 | 视觉辅助                                                                                                                     |
| <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_license.png" alt="许可">        | <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_grid.png" alt="网格">                                        | <img width="200" src="https://github.com/lhlyu/flutter_mana/raw/master/screenshots/mana_visual_helper.png" alt="视觉辅助">   |

## 插件开发

- [参考](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/demo)

- 安装依赖

```shell
flutter pub add flutter_mana
```

- 实现接口

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

/// png to base64
const _iconData =
    r'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';

final _iconBytes = base64Decode(_iconData);

final iconImage = MemoryImage(_iconBytes);

/// 自定义接口
class Demo extends ManaPluggable {

  @override
  Widget? buildWidget(BuildContext? context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Center(child: Text('当前的插件是: demo')),
    );
  }

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '例子';
      default:
        return 'Demo';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'demo';

  @override
  void onTrigger() {}

  @override
  Future<void> initialize() async {}
  
  bool get isSupported => true;
}
```

- 注册接口使用

```dart
void main() {
  ManaPluginManager.instance.register(Demo());

  runApp(ManaWidget(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Example',
      home: Text('Example'),
    );
  }
}
```

## 工具

- [PNG图片转Base64](https://base64.guru/converter/encode/image/png)

## 参考

- [flutter_ume](https://github.com/bytedance/flutter_ume)
- [inspector](https://github.com/kekland/inspector)
- [logarte](https://github.com/kamranbekirovyz/logarte)
- [plus_plugins](https://github.com/fluttercommunity/plus_plugins)
- [free api](https://jsonplaceholder.typicode.com/)
- [info_popup](https://pub.dev/packages/info_popup)
- [do kit](https://github.com/didi/DoKit)
- [fps monitor](https://github.com/Nayuta403/fps_monitor)
- [code highlight](https://github.com/toly1994328/FlutterUnit/blob/master/modules/basic_system/toly_ui/lib/code/code_widget.dart)
- [vConsole](https://wechatfe.github.io/vconsole/demo.html)
- [debug friend](https://pub.dev/packages/debug_friend)
- [widget with codeview](https://github.com/X-Wei/widget_with_codeview)
- [flutter：全局 context 在 navigator 与 overlay 中的运用](https://juejin.cn/post/7200191765516615737)
- [fconsole](https://github.com/fluttercandies/fconsole/blob/8b32f57399396ecb7f5792c0e6c86df3e991d002/lib/src/widget/console.dart#L117)
- [内存泄漏检测原理](https://juejin.cn/post/6922625442323103758)
- [内存泄漏检测库](https://github.com/liujiakuoyx/leak_detector)
- [卡顿检测](https://juejin.cn/post/7434899217804902427)