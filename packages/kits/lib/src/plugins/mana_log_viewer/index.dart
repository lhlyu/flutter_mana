import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';

import 'icon.dart';
import 'mana_log_collector.dart';
import 'widgets/log_viewer.dart';

class ManaLogViewer extends BuiltinKit {
  ManaLogViewer({ManaLogCollector? collector, this.captureDebugPrint = false})
    : collector = collector ?? ManaLogCollector(),
      _ownsCollector = collector == null,
      super(
        name: 'mana_log_viewer',
        title: 'Log Viewer',
        chineseTitle: '日志查看器',
        iconImageProvider: iconImage,
      );
  final ManaLogCollector collector;
  final bool _ownsCollector;
  final bool captureDebugPrint;
  VoidCallback? _releaseCapture;
  @override
  void initialize() {
    if (captureDebugPrint) _releaseCapture ??= collector.captureDebugPrint();
  }

  @override
  void dispose() {
    _releaseCapture?.call();
    if (_ownsCollector) collector.dispose();
  }

  @override
  Widget buildWidget(BuildContext context) =>
      LogViewer(name: name, collector: collector);
}
