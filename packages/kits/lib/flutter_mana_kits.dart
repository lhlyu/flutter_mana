library;

import 'package:flutter_mana/flutter_mana.dart';

import 'src/plugins/plugins.dart';

export 'src/plugins/plugins.dart';

List<ManaPluggable> loadAllPlugins() {
  return [
    ManaAlignRuler(),
    ManaColorSucker(),
    ManaDeviceInfo(),
    ManaDioInspector(),
    ManaFpsMonitor(),
    ManaGrid(),
    ManaLicense(),
    ManaLogViewer(),
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
