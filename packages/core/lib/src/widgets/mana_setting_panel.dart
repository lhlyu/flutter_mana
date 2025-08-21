import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import '../core/mana_i18n_mixin.dart';

class ManaSettingPanel extends StatelessWidget with ManaI18n {
  const ManaSettingPanel({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          _buildFabSizeSlider(context),
          _buildFabOpacitySlider(context),
        ],
      ),
    );
  }

  Widget _buildFabSizeSlider(BuildContext context) {
    final manaState = ManaScope.of(context);

    return ValueListenableBuilder(
      valueListenable: manaState.floatingButtonSize,
      builder: (context, size, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t('float_button_size'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${size.toStringAsFixed(0)}px',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Slider(
              value: size,
              min: 30.0,
              max: 100.0,
              divisions: 7,
              padding: EdgeInsets.zero,
              label: size.toStringAsFixed(0),
              onChanged: (value) async {
                manaState.floatingButtonSize.value = value;
                await ManaStore.instance.setManaState(manaState);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFabOpacitySlider(BuildContext context) {
    final manaState = ManaScope.of(context);

    return ValueListenableBuilder(
      valueListenable: manaState.floatingButtonOpacity,
      builder: (context, opacity, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t('float_button_opacity'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${(opacity * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Slider(
              value: opacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              padding: EdgeInsets.zero,
              label: (opacity * 100).toStringAsFixed(0),
              onChanged: (value) async {
                manaState.floatingButtonOpacity.value = value;
                await ManaStore.instance.setManaState(manaState);
              },
            ),
          ],
        );
      },
    );
  }
}
