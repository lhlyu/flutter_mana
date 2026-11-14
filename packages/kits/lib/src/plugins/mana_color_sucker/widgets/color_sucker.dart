import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';

import 'color_sucker_barrier.dart';
import 'color_sucker_content.dart';

class ColorSucker extends StatefulWidget {
  final String name;

  const ColorSucker({super.key, required this.name});

  @override
  State<ColorSucker> createState() => _ColorSuckerState();
}

class _ColorSuckerState extends State<ColorSucker> {
  Color _color = KitStyle.text;
  double _magnification = 10.0;

  @override
  Widget build(BuildContext context) {
    return KitWindow(
      name: widget.name,
      barrier: ColorSuckerBarrier(
        magnification: _magnification,
        onColorChanged: (color) => setState(() => _color = color),
      ),
      position: .top,
      initialWidth: 300,
      initialHeight: 240,
      content: ColorSuckerContent(
        color: _color,
        magnification: _magnification,
        onMagnificationChanged: (value) =>
            setState(() => _magnification = value),
      ),
    );
  }
}
