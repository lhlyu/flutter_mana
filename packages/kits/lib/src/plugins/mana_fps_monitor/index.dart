import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import 'icon.dart';
import '../../ui/kit_ui.dart';

class ManaFpsMonitor extends BuiltinKit {
  ManaFpsMonitor()
    : super(
        name: 'mana_fps_monitor',
        title: 'Frame Timing',
        chineseTitle: '帧率监控',
        iconImageProvider: iconImage,
      );
  @override
  Widget buildWidget(BuildContext context) => KitWindow(
    name: name,
    initialHeight: 220,
    initialWidth: 420,
    showBarrier: false,
    content: PerformanceOverlay.allEnabled(),
  );
  @override
  bool get isSupported => !kIsWeb;
}
