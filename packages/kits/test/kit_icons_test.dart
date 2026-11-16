import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_mana_kits/src/ui/kit_icons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (size, scale) in [
    (18.0, 1.0),
    (18.0, 3.0),
    (24.0, 1.0),
    (24.0, 3.0),
    (36.0, 2.0),
  ]) {
    testWidgets('refresh arrow is connected at $size px / ${scale}x', (
      tester,
    ) async {
      const color = Color(0xFF455A64);
      await tester.pumpWidget(
        Center(
          child: KitGlyph(.refresh, size: size, color: color),
        ),
      );
      final paint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final pixels = (size * scale).round();
      paint.painter!.paint(canvas, Size.square(pixels.toDouble()));
      final picture = recorder.endRecording();
      final image = (await tester.runAsync(
        () => picture.toImage(pixels, pixels),
      ))!;
      try {
        final data = (await tester.runAsync(() => image.toByteData()))!;
        final ink = <int>{};
        for (var y = 0; y < pixels; y++) {
          for (var x = 0; x < pixels; x++) {
            final alpha = data.getUint8((y * pixels + x) * 4 + 3);
            if (x == 0 || y == 0 || x == pixels - 1 || y == pixels - 1) {
              expect(alpha, 0, reason: 'The glyph must not be clipped');
            }
            if (alpha >= 64) ink.add(y * pixels + x);
          }
        }
        expect(ink, isNotEmpty);

        // A detached arrowhead produces a second connected component.
        final pending = <int>[ink.first];
        final connected = <int>{ink.first};
        while (pending.isNotEmpty) {
          final current = pending.removeLast();
          final x = current % pixels;
          final y = current ~/ pixels;
          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              final nx = x + dx;
              final ny = y + dy;
              if (nx < 0 || ny < 0 || nx >= pixels || ny >= pixels) continue;
              final next = ny * pixels + nx;
              if (ink.contains(next) && connected.add(next)) pending.add(next);
            }
          }
        }
        expect(connected.length, ink.length, reason: 'Arrow must meet the arc');

        bool hasInkNear(double x, double y) {
          final px = (x / 24 * pixels).floor();
          final py = (y / 24 * pixels).floor();
          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              if (ink.contains((py + dy) * pixels + px + dx)) return true;
            }
          }
          return false;
        }

        final tip = Offset(12 + 8 / math.sqrt2, 12 - 8 / math.sqrt2);
        expect(hasInkNear(tip.dx, tip.dy), isTrue);
        expect(hasInkNear(tip.dx - 3, tip.dy), isTrue);
        expect(hasInkNear(tip.dx, tip.dy - 3), isTrue);
        // Leave an opening on the right so this reads as a clockwise arrow.
        final gapX = (20 / 24 * pixels).floor();
        final gapY = (12 / 24 * pixels).floor();
        expect(data.getUint8((gapY * pixels + gapX) * 4 + 3), 0);
      } finally {
        image.dispose();
        picture.dispose();
      }
    });
  }
}
