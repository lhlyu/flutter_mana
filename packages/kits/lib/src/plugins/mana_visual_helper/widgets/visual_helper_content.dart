import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../diagnostics/debug_session.dart';
import '../../../ui/kit_ui.dart';

class VisualHelperContent extends StatefulWidget {
  const VisualHelperContent({super.key});
  @override
  State<VisualHelperContent> createState() => _VisualHelperContentState();
}

class _VisualHelperContentState extends State<VisualHelperContent> {
  final _session = DebugSession();
  late double _speed = (1 / (DebugSession.read(.animation) as double)).clamp(
    .1,
    2,
  );
  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const .all(12),
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(
          '${kitText(context, 'visual_helper.animation_speed')} ×${_speed.toStringAsFixed(1)}',
          style: const TextStyle(fontWeight: .bold),
        ),
        ManaSlider(
          value: _speed,
          min: .1,
          max: 2,
          divisions: 19,
          formatValue: (v) => '×${v.toStringAsFixed(1)}',
          semanticLabel: kitText(context, 'visual_helper.animation_speed'),
          onChanged: (value) {
            setState(() => _speed = value);
            _session.set(.animation, 1 / value);
          },
        ),
        if (kDebugMode)
          for (final (flag, key) in [
            (DebugFlag.layout, 'visual_helper.layout_bounds'),
            (DebugFlag.repaint, 'visual_helper.repaint_highlight'),
            (DebugFlag.images, 'visual_helper.invert_oversized_images'),
          ])
            KitToggle(
              label: kitText(context, key),
              value: DebugSession.read(flag) as bool,
              onChanged: (value) => setState(() => _session.set(flag, value)),
            ),
        if (!kDebugMode)
          Text(
            kitText(context, 'common.unsupported'),
            style: const TextStyle(color: KitStyle.muted),
          ),
      ],
    ),
  );
}
