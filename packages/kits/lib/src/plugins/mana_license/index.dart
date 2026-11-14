import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import 'icon.dart';
import 'widgets/license.dart';

class ManaLicense extends BuiltinKit {
  ManaLicense()
    : super(
        name: 'mana_license',
        title: 'Licenses',
        chineseTitle: '开源许可',
        iconImageProvider: iconImage,
      );
  @override
  Widget buildWidget(BuildContext context) => License(name: name);
}
