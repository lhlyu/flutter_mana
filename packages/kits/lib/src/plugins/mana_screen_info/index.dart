import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import '../../ui/kit_ui.dart';
import 'widgets/screen_info_content.dart';

class ManaScreenInfo extends BuiltinKit {
  ManaScreenInfo()
    : super(
        name: 'mana_screen_info',
        title: 'Screen Info',
        chineseTitle: '屏幕信息',
        icon: .screen,
      );
  @override
  Widget buildWidget(BuildContext context) => KitWindow(
    name: name,
    showBarrier: false,
    content: ScreenInfoContent(data: MediaQuery.of(context)),
  );
}
