import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';

import 'mana_dio_collector.dart';
import '../../ui/kit_ui.dart';
import 'widgets/dio_inspector_content.dart';

class ManaDioInspector extends BuiltinKit {
  ManaDioInspector({ManaDioCollector? collector})
    : collector = collector ?? ManaDioCollector(),
      _ownsCollector = collector == null,
      super(
        name: 'mana_dio_inspector',
        title: 'Dio Inspector',
        chineseTitle: 'Dio 网络检查器',
        icon: .network,
      );
  final ManaDioCollector collector;
  final bool _ownsCollector;
  @override
  void dispose() {
    if (_ownsCollector) collector.dispose();
  }

  @override
  Widget buildWidget(BuildContext context) => KitWindow(
    name: name,
    showBarrier: false,
    initialWidth: double.infinity,
    position: .bottom,
    drag: false,
    content: DioInspectorContent(collector: collector),
  );
}
