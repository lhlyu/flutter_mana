import 'package:flutter/material.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';

class LogViewerSetting extends StatelessWidget with I18nMixin {
  final bool verboseLogs;
  final ValueChanged<bool?>? onChanged;

  const LogViewerSetting({
    super.key,
    required this.verboseLogs,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              Checkbox(
                value: verboseLogs,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: onChanged,
              ),
              Text(t('log_viewer.verbose_logs')),
            ],
          ),
        ],
      ),
    );
  }
}
