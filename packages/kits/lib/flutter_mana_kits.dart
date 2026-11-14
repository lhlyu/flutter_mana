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
    ManaAlignRuler(),
    ManaColorSucker(),
    ManaDeviceInfo(),
    ManaDioInspector(collector: dioCollector),
    ManaFpsMonitor(),
    ManaGrid(),
    ManaLicense(),
    ManaLogViewer(
      collector: logCollector,
      captureDebugPrint: captureDebugPrint,
    ),
    ManaMemoryInfo(),
    ManaPackageInfo(),
    ManaScreenInfo(),
    ManaSharedPreferencesViewer(),
    ManaShowCode(),
    ManaTouchIndicator(),
    ManaVisualHelper(),
    ManaWidgetInfoInspector(),
  ];
}
