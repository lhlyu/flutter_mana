import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/align_ruler.dart';

class ManaAlignRuler extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => AlignRuler(name: name);

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_align_ruler';

  @override
  String getLocalizedDisplayName(Locale locale) {
    if (locale.languageCode == 'zh') {
      return '对齐标尺';
    }
    return 'Align Ruler';
  }
}
