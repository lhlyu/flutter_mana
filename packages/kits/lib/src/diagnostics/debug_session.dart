import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

enum DebugFlag { layout, repaint, images, animation }

/// Leases global Flutter debug flags across tools.
class DebugSession {
  final _token = Object();
  final _flags = <DebugFlag>{};
  static final _slots =
      <DebugFlag, ({Object original, Map<Object, Object> owners})>{};
  static Object read(DebugFlag flag) => switch (flag) {
    .layout => debugPaintSizeEnabled,
    .repaint => debugRepaintRainbowEnabled,
    .images => debugInvertOversizedImages,
    .animation => timeDilation,
  };
  static void _write(DebugFlag flag, Object value) {
    switch (flag) {
      case .layout:
        debugPaintSizeEnabled = value as bool;
      case .repaint:
        debugRepaintRainbowEnabled = value as bool;
      case .images:
        debugInvertOversizedImages = value as bool;
      case .animation:
        timeDilation = value as double;
    }
  }

  void set(DebugFlag flag, Object value) {
    final slot = _slots.putIfAbsent(
      flag,
      () => (original: read(flag), owners: {}),
    );
    slot.owners.remove(_token);
    slot.owners[_token] = value;
    _flags.add(flag);
    _write(flag, value);
    repaint();
  }

  void dispose() {
    for (final flag in _flags) {
      final slot = _slots[flag]!;
      final previous = slot.owners.values.last;
      slot.owners.remove(_token);
      if (read(flag) == previous) {
        _write(
          flag,
          slot.owners.isEmpty ? slot.original : slot.owners.values.last,
        );
      }
      if (slot.owners.isEmpty) _slots.remove(flag);
    }
    _flags.clear();
    repaint();
  }

  static void repaint() {
    void visit(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(visit);
    }

    for (final view in RendererBinding.instance.renderViews) {
      visit(view);
    }
  }
}
