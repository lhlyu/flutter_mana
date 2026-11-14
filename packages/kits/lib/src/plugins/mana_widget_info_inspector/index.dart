import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import 'widgets/widget_info_inspector.dart';

class ManaWidgetInfoInspector extends BuiltinKit {
  ManaWidgetInfoInspector()
    : super(
        name: 'mana_widget_info_inspector',
        title: 'Widget Inspector',
        chineseTitle: '组件检查',
        icon: .inspector,
      );
  @override
  Widget buildWidget(BuildContext context) => WidgetInfoInspector(name: name);
  @override
  bool get isSupported => kDebugMode;
}
