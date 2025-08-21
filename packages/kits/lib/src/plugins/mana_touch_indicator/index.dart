import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/touch_indicator.dart';

class ManaTouchIndicator extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => TouchIndicator(name: name);

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_touch_indicator';

  @override
  String getLocalizedDisplayName(Locale locale) {
    if (locale.languageCode == 'zh') {
      return '触摸指示器';
    }
    return 'Touch Indicator';
  }
}
