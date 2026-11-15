import 'package:flutter/widgets.dart';

enum KitIcon {
  copy,
  check,
  search,
  close,
  refresh,
  add,
  lock,
  unlock,
  clear,
  top,
  bottom,
  filter,
  sortAsc,
  sortDesc,
  sort,
  eye,
  back,
  chevronDown,
  more,
}

class KitGlyph extends StatelessWidget {
  const KitGlyph(this.icon, {super.key, this.size = 18, this.color});
  final KitIcon icon;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(icon, color ?? const Color(0xFF455A64)),
    ),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.icon, this.color);
  final KitIcon icon;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final p = Paint()
      ..color = color
      ..style = .stroke
      ..strokeWidth = 1.8
      ..strokeCap = .round
      ..strokeJoin = .round;
    void line(double x, double y, double a, double b) =>
        canvas.drawLine(Offset(x, y), Offset(a, b), p);
    void path(List<Offset> points) =>
        canvas.drawPath(Path()..addPolygon(points, false), p);
    switch (icon) {
      case .copy:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(8, 8, 12, 13),
            const Radius.circular(2),
          ),
          p,
        );
        path(const [Offset(15, 4), Offset(4, 4), Offset(4, 16)]);
      case .check:
        path(const [Offset(4, 12), Offset(10, 18), Offset(20, 6)]);
      case .chevronDown:
        path(const [Offset(6, 9), Offset(12, 15), Offset(18, 9)]);
      case .close:
        line(6, 6, 18, 18);
        line(6, 18, 18, 6);
      case .add:
        line(4, 12, 20, 12);
        line(12, 4, 12, 20);
      case .search:
        canvas.drawCircle(const Offset(10, 10), 6, p);
        line(15, 15, 21, 21);
      case .refresh:
        canvas.drawArc(const Rect.fromLTWH(4, 4, 16, 16), 0.5, 5, false, p);
        path(const [Offset(15, 4), Offset(20, 4), Offset(20, 9)]);
      case .clear:
        line(4, 6, 20, 6);
        line(9, 3, 15, 3);
        path(const [
          Offset(6, 6),
          Offset(7, 21),
          Offset(17, 21),
          Offset(18, 6),
        ]);
        line(10, 10, 10, 17);
        line(14, 10, 14, 17);
      case .lock || .unlock:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, 10, 14, 11),
            const Radius.circular(2),
          ),
          p,
        );
        canvas.drawArc(
          const Rect.fromLTWH(8, 2, 8, 15),
          3.14,
          icon == .lock ? 3.14 : 2,
          false,
          p,
        );
        line(12, 14, 12, 17);
      case .top || .bottom:
        final up = icon == .top;
        final y = up ? 7.0 : 17.0;
        line(12, 5, 12, 19);
        path([Offset(7, 12), Offset(12, y), Offset(17, 12)]);
        line(4, up ? 3 : 21, 20, up ? 3 : 21);
      case .filter:
        line(3, 5, 21, 5);
        line(6, 12, 18, 12);
        line(9, 19, 15, 19);
      case .sortAsc || .sortDesc || .sort:
        if (icon != .sortDesc) {
          path(const [Offset(7, 9), Offset(12, 4), Offset(17, 9)]);
        }
        if (icon != .sortAsc) {
          path(const [Offset(7, 15), Offset(12, 20), Offset(17, 15)]);
        }
      case .back:
        path(const [Offset(14, 5), Offset(7, 12), Offset(14, 19)]);
      case .eye:
        canvas.drawOval(const Rect.fromLTWH(2, 6, 20, 12), p);
        canvas.drawCircle(const Offset(12, 12), 3, p);
      case .more:
        p.style = .fill;
        for (final x in [5.0, 12.0, 19.0]) {
          canvas.drawCircle(Offset(x, 12), 1.5, p);
        }
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.icon != icon || old.color != color;
}
