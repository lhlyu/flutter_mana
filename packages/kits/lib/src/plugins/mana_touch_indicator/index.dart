import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';

import '../builtin_kit.dart';
import '../../ui/kit_ui.dart';
import 'widgets/touch_indicator_barrier.dart';

class ManaTouchIndicator extends BuiltinKit {
  ManaTouchIndicator()
    : super(
        name: 'mana_touch_indicator',
        title: 'Touch Indicator',
        chineseTitle: '触摸指示器',
        icon: .touch,
      );
  @override
  Widget buildWidget(BuildContext context) =>
      KitWindow(name: name, barrier: const TouchIndicatorBarrier());
  @override
  ManaPresentation get presentation => .overlay;
}
