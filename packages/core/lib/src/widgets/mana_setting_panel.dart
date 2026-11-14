import 'package:flutter/widgets.dart';

import '../runtime/mana_scope.dart';
import 'mana_i18n.dart';
import 'mana_slider.dart';
import 'mana_style.dart';

class ManaSettingPanel extends StatelessWidget with ManaI18n {
  const ManaSettingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ManaScope.of(context);
    final settings = controller.state.settings;
    final locale = Localizations.localeOf(context);
    return SingleChildScrollView(
      padding: const .all(16),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 8,
        children: [
          _slider(
            value: settings.buttonSize,
            label: t('float_button_size', locale: locale),
            min: 30,
            max: 100,
            divisions: 7,
            format: (value) => '${value.round()}px',
            onChanged: (value) => controller.updateSettings(buttonSize: value),
          ),
          _slider(
            value: settings.buttonOpacity,
            label: t('float_button_opacity', locale: locale),
            min: 0.1,
            max: 1,
            divisions: 9,
            format: (value) => '${(value * 100).round()}%',
            onChanged: (value) =>
                controller.updateSettings(buttonOpacity: value),
          ),
        ],
      ),
    );
  }

  Widget _slider({
    required double value,
    required String label,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) => Column(
    crossAxisAlignment: .stretch,
    spacing: 8,
    children: [
      Row(
        spacing: 8,
        children: [
          Expanded(child: Text(label, style: ManaStyle.textStyle)),
          Text(
            format(value),
            style: const TextStyle(fontSize: 12, color: ManaStyle.muted),
          ),
        ],
      ),
      ManaSlider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        formatValue: format,
        semanticLabel: label,
        onChanged: onChanged,
      ),
    ],
  );
}
