import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/screen_info.dart';

class ManaScreenInfo extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => ScreenInfo(name: name);

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_screen_info';

  @override
  String getLocalizedDisplayName(Locale locale) {
    if (locale.languageCode == 'zh') {
      return '屏幕信息';
    }
    return 'Screen Info';
  }
}
