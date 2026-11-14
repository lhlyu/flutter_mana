import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import 'widgets/align_ruler.dart';

class ManaAlignRuler extends BuiltinKit {
  ManaAlignRuler()
    : super(
        name: 'mana_align_ruler',
        title: 'Align Ruler',
        chineseTitle: '对齐标尺',
        icon: .ruler,
      );
  @override
  Widget buildWidget(BuildContext context) => AlignRuler(name: name);
}
