import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import 'icon.dart';
import '../../ui/kit_ui.dart';
import 'widgets/shared_preferences_viewer_content.dart';

class ManaSharedPreferencesViewer extends BuiltinKit {
  ManaSharedPreferencesViewer()
    : super(
        name: 'mana_shared_preferences_viewer',
        title: 'Shared Preferences',
        chineseTitle: '偏好设置',
        iconImageProvider: iconImage,
      );
  @override
  Widget buildWidget(BuildContext context) => KitWindow(
    name: name,
    initialWidth: double.infinity,
    position: .bottom,
    drag: false,
    showBarrier: false,
    content: const SharedPreferencesViewerContent(),
  );
}
