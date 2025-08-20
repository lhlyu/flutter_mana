import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/device_info.dart';

class ManaDeviceInfo extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => DeviceInfo(name: name);

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '设备信息';
      default:
        return 'Device Info';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_device_info';
}
