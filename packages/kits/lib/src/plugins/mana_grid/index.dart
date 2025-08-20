import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/grid.dart';

class ManaGrid extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => Grid(name: name);

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '网格';
      default:
        return 'Grid';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_grid';
}
