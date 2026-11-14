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
    categoryOf: (event) => event.level.name.toUpperCase(),
    searchText: (event) => formatLog(event, verbose: true),
    itemBuilder: (context, event) =>
        LogItemWidget(log: event, verboseLogs: verboseLogs),
  );
}
