import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/memory_info.dart';

class ManaMemoryInfo extends ManaPluggable {
  ManaMemoryInfo();

  @override
  Widget? buildWidget(BuildContext? context) {
    return MemoryInfo(name: name);
  }

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '内存信息';
      default:
        return 'Memory Info';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_memory_info';

  @override
  void onTrigger() {}

  @override
  Future<void> initialize() async {}
}
