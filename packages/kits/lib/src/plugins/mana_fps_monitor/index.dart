import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/fps_monitor.dart';

class ManaFpsMonitor extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => FpsMonitor(name: name);

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '帧率监控';
      default:
        return 'Fps Monitor';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_fps_monitor';

  @override
  bool get isSupported => !kIsWeb;
}
