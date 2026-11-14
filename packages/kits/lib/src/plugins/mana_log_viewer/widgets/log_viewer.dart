import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';

import '../../../ui/kit_ui.dart';
import '../mana_log_collector.dart';
import 'log_viewer_content.dart';

class LogViewer extends StatefulWidget {
  const LogViewer({super.key, required this.name, required this.collector});
  final String name;
  final ManaLogCollector collector;
  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  late final _preferences = ManaScope.read(context).preferences;
  late bool _verbose =
      _preferences.read('mana_log_viewer_verbose_logs') == true;
  Object? _error;
  Future<void> _change(bool value) async {
    setState(() {
      _verbose = value;
      _error = null;
    });
    try {
      await _preferences.write('mana_log_viewer_verbose_logs', value);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => KitWindow(
    name: widget.name,
    showBarrier: false,
    initialWidth: double.infinity,
    position: .bottom,
    drag: false,
    content: LogViewerContent(
      collector: widget.collector,
      verboseLogs: _verbose,
    ),
    setting: SingleChildScrollView(
      child: Column(
        children: [
          KitToggle(
            label: kitText(context, 'log_viewer.verbose_logs'),
            value: _verbose,
            onChanged: _change,
          ),
          if (_error case final error?) KitMessage('$error', error: true),
        ],
      ),
    ),
  );
}
