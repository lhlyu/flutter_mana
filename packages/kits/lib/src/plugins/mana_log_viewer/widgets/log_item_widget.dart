import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';

import '../../../ui/kit_ui.dart';

String formatLog(OutputEvent event, {required bool verbose}) {
  final message = event.origin.message;
  return [
    message is Function && event.lines.isNotEmpty
        ? event.lines.join('\n').replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '')
        : message.toString(),
    if (verbose && event.origin.error != null) '${event.origin.error}',
    if (verbose && event.origin.stackTrace != null)
      '${event.origin.stackTrace}',
  ].join('\n');
}

class LogItemWidget extends StatelessWidget {
  const LogItemWidget({
    super.key,
    required this.verboseLogs,
    required this.log,
  });
  final bool verboseLogs;
  final OutputEvent log;
  @override
  Widget build(BuildContext context) {
    final text = formatLog(log, verbose: verboseLogs);
    final color = switch (log.level) {
      .error || .fatal => KitStyle.danger,
      .warning => KitStyle.warning,
      .info => KitStyle.accent,
      _ => KitStyle.muted,
    };
    return Padding(
      padding: const .all(12),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 4,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  children: [
                    Text(
                      log.level.name.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: .bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      log.origin.time.toIso8601String().split('T').last,
                      style: const TextStyle(
                        color: KitStyle.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              KitCopyButton(text),
            ],
          ),
          KitSelection(child: Text(text, style: KitStyle.code)),
        ],
      ),
    );
  }
}
