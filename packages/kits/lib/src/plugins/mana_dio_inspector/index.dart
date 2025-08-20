import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/dio_inspector.dart';

class ManaDioInspector extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => DioInspector(name: name);

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return 'Dio网络检查器';
      default:
        return 'Dio Inspector';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_dio_inspector';
}
