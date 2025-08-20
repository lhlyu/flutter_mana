import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'dio_inspector_content.dart';

class DioInspector extends StatelessWidget {
  final String name;

  const DioInspector({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: name,
      showBarrier: false,
      initialWidth: double.infinity,
      position: PositionType.bottom,
      drag: false,
      content: DioInspectorContent(),
    );
  }
}
