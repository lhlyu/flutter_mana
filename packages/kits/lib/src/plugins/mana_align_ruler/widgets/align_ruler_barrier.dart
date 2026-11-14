import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana/flutter_mana_diagnostics.dart';

import '../../../ui/kit_ui.dart';

class AlignRulerBarrier extends StatelessWidget {
  const AlignRulerBarrier({
    super.key,
    required this.position,
    required this.snap,
    required this.onChanged,
  });
  final Offset position;
  final bool snap;
  final ValueChanged<Offset> onChanged;
  void _move(BuildContext context, Offset global, {bool release = false}) {
    final box = context.findRenderObject() as RenderBox;
    var point = box.globalToLocal(global);
    if (release && snap) {
      for (final object in HitTestUtils.hitTest(
        global,
        rootKey: ManaScope.read(context).rootKey,
      )) {
        if (!object.attached) continue;
        final rect = MatrixUtils.transformRect(
          object.getTransformTo(box),
          object.paintBounds,
        );
        if (!rect.isFinite || !rect.contains(point)) continue;
        final x = (point.dx - rect.left).abs() < (point.dx - rect.right).abs()
            ? rect.left
            : rect.right;
        final y = (point.dy - rect.top).abs() < (point.dy - rect.bottom).abs()
            ? rect.top
            : rect.bottom;
        point = (point.dx - x).abs() < (point.dy - y).abs()
            ? Offset(x, point.dy)
            : Offset(point.dx, y);
        HapticFeedback.selectionClick();
        break;
      }
    }
    onChanged(
      Offset(
        point.dx.clamp(0, box.size.width),
        point.dy.clamp(0, box.size.height),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _RulerPainter(position, MediaQuery.textScalerOf(context)),
          ),
        ),
      ),
      Positioned(
        left: position.dx - 24,
        top: position.dy - 24,
        child: Semantics(
          label: 'Ruler position',
          child: GestureDetector(
            behavior: .opaque,
            onPanUpdate: (d) => _move(context, d.globalPosition),
            onPanEnd: (d) => _move(context, d.globalPosition, release: true),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: .circle,
                color: KitStyle.surface.withValues(alpha: .7),
                border: Border.all(color: KitStyle.danger, width: 2),
              ),
              child: const Center(
                child: KitGlyph(.add, color: KitStyle.danger),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _RulerPainter extends CustomPainter {
  const _RulerPainter(this.point, this.scaler);
  final Offset point;
  final TextScaler scaler;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = KitStyle.danger
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, point.dy), Offset(size.width, point.dy), paint);
    canvas.drawLine(Offset(point.dx, 0), Offset(point.dx, size.height), paint);
    final text = TextPainter(textDirection: .ltr, textScaler: scaler);
    for (final (value, offset) in [
      (point.dx, Offset(point.dx / 2, point.dy - 20)),
      (
        size.width - point.dx,
        Offset((size.width + point.dx) / 2, point.dy - 20),
      ),
      (point.dy, Offset(point.dx + 4, point.dy / 2)),
      (
        size.height - point.dy,
        Offset(point.dx + 4, (size.height + point.dy) / 2),
      ),
    ]) {
      text.text = TextSpan(
        text: value.toStringAsFixed(1),
        style: const TextStyle(color: KitStyle.danger, fontSize: 11),
      );
      text.layout(maxWidth: size.width);
      text.paint(
        canvas,
        Offset(
          offset.dx.clamp(
            0,
            (size.width - text.width).clamp(0, double.infinity),
          ),
          offset.dy.clamp(
            0,
            (size.height - text.height).clamp(0, double.infinity),
          ),
        ),
      );
    }
    text.dispose();
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.point != point || old.scaler != scaler;
}
