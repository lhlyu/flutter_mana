import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

import 'show_code_content.dart';

class ShowCode extends StatelessWidget {
  final String name;

  final HighlighterTheme theme;

  const ShowCode({super.key, required this.name, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: name,
      position: PositionType.bottom,
      initialWidth: double.infinity,
      initialHeight: double.infinity,
      drag: false,
      showBarrier: false,
      content: ShowCodeContent(theme: theme),
    );
  }
}
