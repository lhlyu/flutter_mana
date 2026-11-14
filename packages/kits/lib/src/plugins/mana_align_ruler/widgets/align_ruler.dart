import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';
import 'align_ruler_barrier.dart';

class AlignRuler extends StatefulWidget {
  const AlignRuler({super.key, required this.name});
  final String name;
  @override
  State<AlignRuler> createState() => _AlignRulerState();
}

class _AlignRulerState extends State<AlignRuler> {
  Offset? _position;
  bool _snap = false;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final raw = _position ?? size.center(Offset.zero);
    final point = Offset(
      raw.dx.clamp(0, size.width),
      raw.dy.clamp(0, size.height),
    );
    return KitWindow(
      name: widget.name,
      initialHeight: 300,
      position: .top,
      barrier: AlignRulerBarrier(
        position: point,
        snap: _snap,
        onChanged: (value) => setState(() => _position = value),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            KitDataTable({
              'Left': point.dx.toStringAsFixed(1),
              'Top': point.dy.toStringAsFixed(1),
              'Right': (size.width - point.dx).toStringAsFixed(1),
              'Bottom': (size.height - point.dy).toStringAsFixed(1),
            }),
            KitToggle(
              label: kitText(context, 'align_ruler.snap'),
              value: _snap,
              onChanged: (value) => setState(() => _snap = value),
            ),
          ],
        ),
      ),
    );
  }
}
