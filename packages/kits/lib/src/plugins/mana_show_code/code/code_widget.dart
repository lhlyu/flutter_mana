import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';
import 'code_highlighter.dart';

class CodeWidget extends StatefulWidget {
  const CodeWidget({super.key, required this.code});
  final String code;
  @override
  State<CodeWidget> createState() => _CodeWidgetState();
}

class _CodeWidgetState extends State<CodeWidget> {
  late TextSpan _span = highlightDart(widget.code);
  @override
  void didUpdateWidget(CodeWidget old) {
    super.didUpdateWidget(old);
    if (old.code != widget.code) _span = highlightDart(widget.code);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: .horizontal,
        padding: const .all(12),
        child: KitSelection(child: Text.rich(_span, softWrap: false)),
      ),
    ),
  );
}
