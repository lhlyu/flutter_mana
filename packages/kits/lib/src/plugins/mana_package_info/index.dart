import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/package_info.dart';

class ManaPackageInfo extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => PackageInfo(name: name);

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '包信息';
      default:
        return 'Package Info';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_package_info';
}
