import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/color_sucker.dart';

class ManaColorSucker extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => ColorSucker(name: name);

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '颜色吸管';
      default:
        return 'Color Sucker';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_color_sucker';
}
