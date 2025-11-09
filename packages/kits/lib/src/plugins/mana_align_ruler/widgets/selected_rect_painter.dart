import 'package:flutter/material.dart';

class SelectedRectPainter extends CustomPainter {
  final RenderObject? selectedObject;

  static const Color fillColor = Colors.blue;

  static const Color borderColor = Colors.blue;

  static const double borderWidth = 2.0;

  const SelectedRectPainter(this.selectedObject);

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedObject == null) {
      return;
    }

    final Matrix4 transform = selectedObject!.getTransformTo(null);

    final Rect globalRect = selectedObject!.paintBounds.shift(
      Offset(transform.getTranslation().x, transform.getTranslation().y),
    );

    final Paint fillPaint =
        Paint()
          ..color = fillColor.withAlpha(50)
          ..style = PaintingStyle.fill;
    canvas.drawRect(globalRect, fillPaint);

    final Paint borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
    canvas.drawRect(globalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant SelectedRectPainter oldDelegate) {
    return oldDelegate.selectedObject != selectedObject;
  }
}
