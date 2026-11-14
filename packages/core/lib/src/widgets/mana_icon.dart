import 'package:flutter/widgets.dart';

import 'mana_style.dart';

/// Small font-independent symbols used only by the debug UI.
enum ManaSymbol {
  fullscreen,
  exitFullscreen,
  minimize,
  settings,
  close,
  check,
  blocked,
}

class ManaIcon extends StatelessWidget {
  final ManaSymbol symbol;
  final double size;
  final Color color;

  const ManaIcon(
    this.symbol, {
    super.key,
    this.size = 16,
    this.color = ManaStyle.muted,
  });

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: .square(size), painter: _SymbolPainter(symbol, color));
}

class _SymbolPainter extends CustomPainter {
  final ManaSymbol symbol;
  final Color color;

  const _SymbolPainter(this.symbol, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = .stroke
      ..strokeWidth = 2
      ..strokeCap = .round
      ..strokeJoin = .round;
    final path = Path();
    switch (symbol) {
      case .fullscreen:
        path
          ..moveTo(9, 4)
          ..lineTo(4, 4)
          ..lineTo(4, 9)
          ..moveTo(15, 4)
          ..lineTo(20, 4)
          ..lineTo(20, 9)
          ..moveTo(4, 15)
          ..lineTo(4, 20)
          ..lineTo(9, 20)
          ..moveTo(15, 20)
          ..lineTo(20, 20)
          ..lineTo(20, 15);
      case .exitFullscreen:
        path
          ..moveTo(4, 9)
          ..lineTo(9, 9)
          ..lineTo(9, 4)
          ..moveTo(15, 4)
          ..lineTo(15, 9)
          ..lineTo(20, 9)
          ..moveTo(4, 15)
          ..lineTo(9, 15)
          ..lineTo(9, 20)
          ..moveTo(15, 20)
          ..lineTo(15, 15)
          ..lineTo(20, 15);
      case .minimize:
        path
          ..moveTo(5, 12)
          ..lineTo(19, 12);
      case .close:
        path
          ..moveTo(6, 6)
          ..lineTo(18, 18)
          ..moveTo(18, 6)
          ..lineTo(6, 18);
      case .check:
        path
          ..moveTo(4, 12)
          ..lineTo(9, 17)
          ..lineTo(20, 6);
      case .blocked:
        canvas.drawCircle(const Offset(12, 12), 9, paint);
        path
          ..moveTo(6, 18)
          ..lineTo(18, 6);
      case .settings:
        canvas.drawCircle(const Offset(12, 12), 6, paint);
        canvas.drawCircle(const Offset(12, 12), 2, paint);
        for (var i = 0; i < 8; i++) {
          canvas.save();
          canvas.translate(12, 12);
          canvas.rotate(i * 3.141592653589793 / 4);
          canvas.drawLine(const Offset(0, -7), const Offset(0, -9), paint);
          canvas.restore();
        }
    }
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SymbolPainter oldDelegate) =>
      symbol != oldDelegate.symbol || color != oldDelegate.color;
}
