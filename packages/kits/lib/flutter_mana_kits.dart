library;

import 'package:flutter_mana/flutter_mana.dart';

import 'src/plugins/plugins.dart';

export 'src/plugins/plugins.dart';

/// Each call creates fresh plugins. Pass collectors shared with Dio and Logger.
List<ManaPluggable> loadAllPlugins({
  ManaDioCollector? dioCollector,
  ManaLogCollector? logCollector,
  bool captureDebugPrint = false,
}) {
  return [
    // 常用排查
    ManaDioInspector(collector: dioCollector),
    ManaLogViewer(
      collector: logCollector,
      captureDebugPrint: captureDebugPrint,
    ),
    ManaSharedPreferencesViewer(),

    // 性能诊断
    ManaFpsMonitor(),
    ManaMemoryInfo(),

    // 界面调试
    ManaWidgetInfoInspector(),
    ManaShowCode(),
    ManaVisualHelper(),
    ManaAlignRuler(),
    ManaGrid(),
    ManaColorSucker(),
    ManaTouchIndicator(),

    // 环境信息
    ManaDeviceInfo(),
    ManaScreenInfo(),
    ManaPackageInfo(),
    ManaLicense(),
  ];
}
