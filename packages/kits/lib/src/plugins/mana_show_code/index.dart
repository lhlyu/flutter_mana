import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';

import '../builtin_kit.dart';
import '../../ui/kit_ui.dart';
import 'widgets/show_code_content.dart';

class ManaShowCode extends BuiltinKit {
  ManaShowCode()
    : super(
        name: 'mana_show_code',
        title: 'Source Browser',
        chineseTitle: '源代码浏览',
        icon: .code,
      );
  @override
  Widget buildWidget(BuildContext context) => KitWindow(
    name: name,
    initialHeight: double.infinity,
    initialWidth: double.infinity,
    position: .bottom,
    drag: false,
    showBarrier: false,
    maintainContent: false,
    content: ShowCodeContent(
      root: ManaScope.read(context).rootKey.currentContext,
    ),
  );
  @override
  bool get isSupported => !kIsWeb && kDebugMode;
}
