import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';

import '../../../ui/kit_feed.dart';
import '../mana_log_collector.dart';
import 'log_item_widget.dart';

class LogViewerContent extends StatelessWidget {
  const LogViewerContent({
    super.key,
    required this.collector,
    required this.verboseLogs,
  });
  final ManaLogCollector collector;
  final bool verboseLogs;

  static String _categoryOf(OutputEvent event) =>
      event.level.name.toUpperCase();

  static String _searchText(OutputEvent event) =>
      formatLog(event, verbose: true);

  @override
  Widget build(BuildContext context) => KitFeed<OutputEvent>(
    collector: collector,
    categories: [
      for (final level in [
        Level.trace,
        Level.debug,
        Level.info,
        Level.warning,
        Level.error,
        Level.fatal,
      ])
        level.name.toUpperCase(),
    ],
    categoryOf: _categoryOf,
    searchText: _searchText,
    itemBuilder: (context, event) =>
        LogItemWidget(log: event, verboseLogs: verboseLogs),
  );
}
