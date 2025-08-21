import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'memory_info_content.dart';

class MemoryInfo extends StatelessWidget {
  final String name;

  const MemoryInfo({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: name,
      initialHeight: double.infinity,
      initialWidth: double.infinity,
      position: PositionType.bottom,
      drag: false,
      showBarrier: false,
      maintainContent: false,
      content: MemoryInfoContent(),
    );
  }
}
