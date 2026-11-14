import 'package:flutter/widgets.dart' show Locale;

mixin ManaI18n {
  static const _strings = {
    'float_button_size': ('Float Button Size', '浮动按钮大小'),
    'float_button_opacity': ('Float Button Opacity', '浮动按钮透明度'),
  };

  String t(String key, {required Locale locale}) {
    final text = _strings[key];
    return text == null
        ? key
        : locale.languageCode == 'zh'
        ? text.$2
        : text.$1;
  }
}
