import 'package:flutter/material.dart';

class ScreenInfoContent extends StatelessWidget {
  const ScreenInfoContent({super.key});

  static const _borderSide = BorderSide(width: 1, color: Color(0xFFE0E0E0));
  static const _tableBorder = TableBorder(
    top: _borderSide,
    bottom: _borderSide,
    horizontalInside: _borderSide,
    verticalInside: _borderSide,
  );

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return SelectionArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Table(
          border: _tableBorder,
          columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
          children: [
            TableRow(
              children: [
                _Cell('size.width', bold: true),
                _Cell('${mediaQuery.size.width}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('size.height', bold: true),
                _Cell('${mediaQuery.size.height}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('devicePixelRatio', bold: true),
                _Cell('${mediaQuery.devicePixelRatio}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('orientation', bold: true),
                _Cell('${mediaQuery.orientation}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('padding.top', bold: true),
                _Cell('${mediaQuery.padding.top}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('padding.bottom', bold: true),
                _Cell('${mediaQuery.padding.bottom}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('padding.bottom', bold: true),
                _Cell('${mediaQuery.padding.left}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('padding.right', bold: true),
                _Cell('${mediaQuery.padding.right}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('viewPadding.top', bold: true),
                _Cell('${mediaQuery.viewPadding.top}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('viewPadding.bottom', bold: true),
                _Cell('${mediaQuery.viewPadding.bottom}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('viewPadding.left', bold: true),
                _Cell('${mediaQuery.viewPadding.left}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('viewPadding.right', bold: true),
                _Cell('${mediaQuery.viewPadding.right}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('viewInsets.top', bold: true),
                _Cell('${mediaQuery.viewInsets.top}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('viewInsets.bottom', bold: true),
                _Cell('${mediaQuery.viewInsets.bottom}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('viewInsets.left', bold: true),
                _Cell('${mediaQuery.viewInsets.left}'),
              ],
            ),
            TableRow(
              children: [
                _Cell('viewInsets.right', bold: true),
                _Cell('${mediaQuery.viewInsets.right}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 复用 DeviceInfoContent 中的单元格组件
class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      text,
      style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
    ),
  );
}
