import 'package:flutter/widgets.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';

import '../builtin_kit.dart';
import 'icon.dart';

class Demo extends BuiltinKit {
  Demo()
    : super(
        name: 'demo',
        title: 'Demo',
        chineseTitle: '示例',
        iconImageProvider: iconImage,
      );
  @override
  Widget buildWidget(BuildContext context) => KitWindow(
    name: name,
    content: const Center(child: Text('Demo')),
  );
}
