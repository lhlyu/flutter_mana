import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/shared_preferences_viewer.dart';

class ManaSharedPreferencesViewer extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) =>
      SharedPreferencesViewer(name: name);

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return 'Shared Preferences';
      default:
        return 'Shared Preferences';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_shared_preferences_viewer';
}
