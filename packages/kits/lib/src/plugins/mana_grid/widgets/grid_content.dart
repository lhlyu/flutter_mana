import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';

class GridContent extends StatelessWidget {
  const GridContent({
    super.key,
    required this.gap,
    required this.showNumbers,
    required this.onGapChanged,
    required this.onShowNumbersChanged,
  });
  final double gap;
  final bool showNumbers;
  final ValueChanged<double> onGapChanged;
  final ValueChanged<bool> onShowNumbersChanged;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const .all(12),
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(
          '${kitText(context, 'grid.gap')}: ${gap.round()}',
          style: const TextStyle(fontWeight: .bold),
        ),
        ManaSlider(
          value: gap,
          min: 10,
          max: 100,
          divisions: 18,
          formatValue: (v) => '${v.round()}',
          semanticLabel: kitText(context, 'grid.gap'),
          onChanged: onGapChanged,
        ),
        KitToggle(
          label: kitText(context, 'grid.show_numbers'),
          value: showNumbers,
          onChanged: onShowNumbersChanged,
        ),
      ],
    ),
  );
}
