import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';

import 'screen_info_content.dart';

class ScreenInfo extends StatelessWidget with I18nMixin {
  final String name;

  const ScreenInfo({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(name: name, content: ScreenInfoContent());
  }
}
