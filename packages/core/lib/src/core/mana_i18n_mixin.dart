import 'package:flutter_mana/flutter_mana.dart';

mixin ManaI18n {
  static const _strings = {
    'float_button_size': ['Float Button Size', '浮动按钮大小'],
    'float_button_opacity': ['Float Button Opacity', '浮动按钮透明度'],
  };

  static final _language = manaLocale.languageCode;

  String t(String k, [String defaultValue = '']) {
    final ss = _strings[k];
    if (ss == null) {
      return defaultValue;
    }
    switch (_language) {
      case 'zh':
        return ss[1];
      default:
        return ss[0];
    }
  }
}
