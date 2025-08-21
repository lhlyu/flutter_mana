import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/visual_helper.dart';

class ManaVisualHelper extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => VisualHelper(name: name);

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '视觉辅助';
      default:
        return 'Visual Helper';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_visual_helper';
}
