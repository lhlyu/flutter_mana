import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/show_code.dart';

class ManaShowCode extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => ShowCode(name: name);

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '显示代码';
      default:
        return 'Show Code';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_show_code';

  @override
  bool get isSupported => !kIsWeb && kDebugMode;
}
