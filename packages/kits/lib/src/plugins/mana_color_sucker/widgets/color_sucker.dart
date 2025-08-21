import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'color_sucker_barrier.dart';
import 'color_sucker_content.dart';

class ColorSucker extends StatefulWidget {
  final String name;

  const ColorSucker({super.key, required this.name});

  @override
  State<ColorSucker> createState() => _ColorSuckerState();
}

class _ColorSuckerState extends State<ColorSucker> {
  Color _color = Colors.black;
  double _magnification = 10.0;

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: widget.name,
      barrier: ColorSuckerBarrier(
        magnification: _magnification,
        onColorChanged: (color) {
          _color = color;
          setState(() {});
        },
      ),
      position: PositionType.top,
      initialWidth: 300,
      initialHeight: 200,
      content: ColorSuckerContent(
        color: _color,
        onMagnificationChanged: (value) {
          setState(() {
            _magnification = value;
          });
        },
      ),
    );
  }
}
