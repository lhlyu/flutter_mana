import 'package:flutter/material.dart';

class GridBarrier extends StatelessWidget {
  final double gap;
  final bool showNumbers;

  const GridBarrier({super.key, required this.gap, required this.showNumbers});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(
          gap: gap,
          color: Colors.grey.withAlpha(180),
          centerColor: Colors.redAccent.withAlpha(180),
          strokeWidth: 0.5,
          showNumbers: showNumbers,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double gap;
  final Color color;
  final Color centerColor;
  final double strokeWidth;
  final bool showNumbers;

  _GridPainter({
    required this.gap,
    required this.color,
    required this.centerColor,
    required this.strokeWidth,
    required this.showNumbers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth;

    final centerPaint =
        Paint()
          ..color = centerColor
          ..strokeWidth = strokeWidth * 2;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    // 垂直线
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      if (showNumbers) {
        textPainter.text = TextSpan(
          text: x.toInt().toString(),
          style: TextStyle(fontSize: 10, color: color),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 2, 2));
      }
    }

    // 水平线
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      if (showNumbers) {
        textPainter.text = TextSpan(
          text: y.toInt().toString(),
          style: TextStyle(fontSize: 10, color: color),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(2, y + 2));
      }
    }

    // 中心参考线
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 垂直中心线
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      centerPaint,
    );
    if (showNumbers) {
      textPainter.text = TextSpan(
        text: centerX.toInt().toString(),
        style: TextStyle(fontSize: 10, color: centerColor),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerX + 2, 2));
    }

    // 水平中心线
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerPaint,
    );
    if (showNumbers) {
      textPainter.text = TextSpan(
        text: centerY.toInt().toString(),
        style: TextStyle(fontSize: 10, color: centerColor),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, centerY + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.gap != gap ||
        oldDelegate.color != color ||
        oldDelegate.centerColor != centerColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showNumbers != showNumbers;
  }
}
