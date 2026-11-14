import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';

class ColorSuckerContent extends StatelessWidget {
  const ColorSuckerContent({
    super.key,
    required this.color,
    required this.magnification,
    required this.onMagnificationChanged,
  });
  final Color color;
  final double magnification;
  final ValueChanged<double> onMagnificationChanged;
  @override
  Widget build(BuildContext context) {
    final hex =
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final rgb =
        'rgba(${(color.r * 255).round()}, ${(color.g * 255).round()}, ${(color.b * 255).round()}, ${color.a.toStringAsFixed(2)})';
    return SingleChildScrollView(
      padding: const .all(12),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            spacing: 8,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: KitStyle.border),
                ),
              ),
              Expanded(child: Text(hex, style: KitStyle.code)),
              KitCopyButton(hex),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text(rgb, style: KitStyle.code)),
              KitCopyButton(rgb),
            ],
          ),
          Text(
            '${kitText(context, 'color_sucker.magnification')} ×${magnification.round()}',
          ),
          ManaSlider(
            value: magnification,
            min: 2,
            max: 20,
            divisions: 18,
            formatValue: (v) => '×${v.round()}',
            semanticLabel: kitText(context, 'color_sucker.magnification'),
            onChanged: onMagnificationChanged,
          ),
        ],
      ),
    );
  }
}
