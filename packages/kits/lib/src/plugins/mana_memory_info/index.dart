import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import 'icon.dart';
import '../../ui/kit_ui.dart';
import 'widgets/memory_info_content.dart';

class ManaMemoryInfo extends BuiltinKit {
  ManaMemoryInfo()
    : super(
        name: 'mana_memory_info',
        title: 'Memory Info',
        chineseTitle: '内存信息',
        iconImageProvider: iconImage,
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
    content: const MemoryInfoContent(),
  );
  @override
  bool get isSupported => !kIsWeb && kDebugMode;
}
