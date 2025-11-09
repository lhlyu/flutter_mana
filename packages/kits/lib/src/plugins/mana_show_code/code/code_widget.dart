import 'package:flutter/material.dart';

import 'high_light_code.dart';
import 'highlighter_style.dart';
import 'language/dart_languge.dart';

class CodeWidget extends StatelessWidget {
  const CodeWidget({
    super.key,
    required this.code,
    required this.style,
    this.fontSize = 13,
    this.fontFamily,
  });

  final String code;
  final HighlighterStyle style;
  final double fontSize;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    Widget body;
    Widget codeWidget;
    try {
      codeWidget = SelectableText.rich(
        selectionControls: MaterialTextSelectionControls(),
        TextSpan(
          style: TextStyle(fontSize: fontSize, fontFamily: fontFamily),
          children: <TextSpan>[
            CodeHighlighter(
              style: style,
              language: const DartLanguage(),
            ).format(code),
          ],
        ),
      );
    } catch (err) {
      debugPrint('$err');
      codeWidget = SelectableText(code);
    }
    body = SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: codeWidget,
      ),
    );
    return body;
  }
}
