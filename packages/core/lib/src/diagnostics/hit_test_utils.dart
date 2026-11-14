import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' show GlobalKey;

/// Diagnostic hit testing against an explicit host root, in global coordinates.
abstract final class HitTestUtils {
  static List<RenderObject> hitTest(
    Offset position, {
    required GlobalKey rootKey,
  }) {
    final root = rootKey.currentContext?.findRenderObject();
    if (root is! RenderBox || !root.attached || !root.hasSize) return const [];
    final result = BoxHitTestResult();
    root.hitTest(result, position: root.globalToLocal(position));
    final objects = result.path
        .map((entry) => entry.target)
        .whereType<RenderObject>()
        .toList();
    objects.sort(
      (a, b) =>
          a.semanticBounds.size.area.compareTo(b.semanticBounds.size.area),
    );
    return objects;
  }
}

extension on Size {
  double get area => width * height;
}
