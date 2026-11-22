import 'package:flutter/widgets.dart';

import '../runtime/mana_scope.dart';
import 'mana_button.dart';
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
          _overlaySwitch(
            value: controller.state.overlayVisible,
            label: t('debug_overlay_visible', locale: locale),
            hint: t('debug_overlay_visible_hint', locale: locale),
            onPressed: () => controller.toggleOverlay(),
          ),
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

  Widget _overlaySwitch({
    required bool value,
    required String label,
    required String hint,
    required VoidCallback onPressed,
  }) => Semantics(
    label: label,
    hint: hint,
    toggled: value,
    onTap: onPressed,
    child: ExcludeSemantics(
      child: ManaButton(
        onPressed: onPressed,
        padding: const .symmetric(vertical: 8),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: 4,
                children: [
                  Text(label, style: ManaStyle.textStyle),
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: ManaStyle.muted,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 24,
              padding: const .all(3),
              alignment: value
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              decoration: BoxDecoration(
                color: value ? ManaStyle.accent : ManaStyle.border,
                borderRadius: .circular(12),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: ManaStyle.surface,
                  shape: .circle,
                ),
                child: SizedBox.square(dimension: 18),
              ),
            ),
          ],
        ),
      ),
    ),
  );

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
      Wrap(
        alignment: .spaceBetween,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(label, style: ManaStyle.textStyle),
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
