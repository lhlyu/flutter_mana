import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';

class TouchIndicatorBarrier extends StatefulWidget {
  const TouchIndicatorBarrier({super.key, this.enabled = true});
  final bool enabled;
  @override
  State<TouchIndicatorBarrier> createState() => _TouchIndicatorBarrierState();
}

class _TouchIndicatorBarrierState extends State<TouchIndicatorBarrier> {
  final _points = <int, Offset>{};
  final _timers = <int, Timer>{};
  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_pointer);
  }

  void _pointer(PointerEvent event) {
    if (!mounted || !widget.enabled) return;
    final root = ManaScope.read(context).rootKey.currentContext
        ?.findRenderObject();
    if (root is! RenderBox || !root.attached) return;
    if (event is PointerDownEvent || event is PointerMoveEvent) {
      final local = root.globalToLocal(event.position);
      if (!(Offset.zero & root.size).contains(local) &&
          !_points.containsKey(event.pointer)) {
        return;
      }
      _timers.remove(event.pointer)?.cancel();
      setState(() => _points[event.pointer] = local);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (!_points.containsKey(event.pointer)) return;
      _timers.remove(event.pointer)?.cancel();
      _timers[event.pointer] = Timer(const Duration(milliseconds: 200), () {
        _timers.remove(event.pointer);
        if (mounted) setState(() => _points.remove(event.pointer));
      });
    }
  }

  @override
  void didUpdateWidget(TouchIndicatorBarrier old) {
    super.didUpdateWidget(old);
    if (!widget.enabled) {
      _points.clear();
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    }
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_pointer);
    for (final timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: Stack(
        children: [
          for (final point in _points.values)
            Positioned(
              left: point.dx - 15,
              top: point.dy - 15,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: .circle,
                  color: const Color(0xFFB52973).withValues(alpha: .3),
                  border: Border.all(color: const Color(0xFFB52973), width: 2),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
