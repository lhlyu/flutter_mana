import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'visual_helper_content.dart';

class VisualHelper extends StatelessWidget {
  final String name;

  const VisualHelper({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: name,
      initialHeight: 290,
      showBarrier: false,
      content: VisualHelperContent(),
    );
  }
}
