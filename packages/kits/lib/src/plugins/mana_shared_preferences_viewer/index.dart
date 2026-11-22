import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import 'widgets/shared_preferences_viewer.dart';

class ManaSharedPreferencesViewer extends BuiltinKit {
  ManaSharedPreferencesViewer()
    : super(
        name: 'mana_shared_preferences_viewer',
        title: 'Shared Preferences',
        chineseTitle: '偏好设置',
        icon: .preferences,
      );
  @override
  Widget buildWidget(BuildContext context) =>
      SharedPreferencesViewer(name: name);
}
