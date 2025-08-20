import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/src/icons/kit_icons.dart';
import 'package:logger/logger.dart';

const Map<Level, Color> _levelColorMap = {
  Level.debug: Colors.green,
  Level.info: Colors.blue,
  Level.warning: Colors.orange,
  Level.error: Colors.red,
};

class LogItemWidget extends StatelessWidget {
  final bool verboseLogs;
  final OutputEvent log;

  const LogItemWidget({super.key, required this.verboseLogs, required this.log});

  Color get _levelColor => _levelColorMap[log.level] ?? Colors.black;

  String _buildFullMessage() {
    final buf = StringBuffer(log.origin.message);
    if (verboseLogs) {
      if (log.origin.error != null) {
        buf.write('\n--------------- error ---------------\n${log.origin.error}');
      }
      if (log.origin.stackTrace != null) {
        buf.write('\n--------------- stackTrace ---------------\n${log.origin.stackTrace}');
      }
    }
    return buf.toString().trim();
  }

  Future<void> _copyToClipboard(String fullMessage) async {
    await Clipboard.setData(ClipboardData(text: fullMessage));
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = log.origin.time.toIso8601String().split('T')[1];
    final String fullMessage = _buildFullMessage();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: log.origin.level.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _levelColor,
                        fontSize: 12,
                      ),
                    ),
                    const TextSpan(text: '  '),
                    TextSpan(text: timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 12),
                  CheckIconButton(
                    initialIcon: KitIcons.copy,
                    changedIcon: KitIcons.copy_success,
                    size: 14,
                    style: IconButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _copyToClipboard(fullMessage),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(fullMessage, style: const TextStyle(fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }
}
