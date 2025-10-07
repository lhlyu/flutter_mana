import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'show_code_content.dart';

class ShowCode extends StatelessWidget {
  final String name;

  const ShowCode({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: name,
      position: PositionType.bottom,
      initialWidth: double.infinity,
      initialHeight: double.infinity,
      drag: false,
      showBarrier: false,
      maintainContent: false,
      content: ShowCodeContent(),
    );
  }
}
