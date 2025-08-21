import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/widget_info_inspector.dart';

class ManaWidgetInfoInspector extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => WidgetInfoInspector(name: name);

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return 'Widget 信息';
      default:
        return 'Widget Info';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_widget_info_inspector';

  @override
  bool get isSupported => kDebugMode;
}
