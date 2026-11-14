import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import 'widgets/color_sucker.dart';

class ManaColorSucker extends BuiltinKit {
  ManaColorSucker()
    : super(
        name: 'mana_color_sucker',
        title: 'Color Picker',
        chineseTitle: '颜色吸管',
        icon: .colorPicker,
      );
  @override
  Widget buildWidget(BuildContext context) => ColorSucker(name: name);
}
