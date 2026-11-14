import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import 'icon.dart';
import '../../ui/kit_ui.dart';
import 'widgets/visual_helper_content.dart';

class ManaVisualHelper extends BuiltinKit {
  ManaVisualHelper()
    : super(
        name: 'mana_visual_helper',
        title: 'Visual Helper',
        chineseTitle: '视觉辅助',
        iconImageProvider: iconImage,
      );
  @override
  Widget buildWidget(BuildContext context) => KitWindow(
    name: name,
    initialHeight: 290,
    showBarrier: false,
    content: const VisualHelperContent(),
  );
}
