import 'package:flutter/material.dart';

/// 触摸指示器
class TouchIndicatorBarrier extends StatefulWidget {
  final bool enabled;

  const TouchIndicatorBarrier({super.key, this.enabled = true});

  @override
  State<TouchIndicatorBarrier> createState() => _TouchIndicatorBarrierState();
}

class _TouchIndicatorBarrierState extends State<TouchIndicatorBarrier> {
  final Map<int, Offset> _touchPoints = {};

  static const _time = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        setState(() {
          _touchPoints[event.pointer] = event.position;
        });
      },
      onPointerMove: (event) {
        setState(() {
          _touchPoints[event.pointer] = event.position;
        });
      },
      onPointerUp: (event) {
        Future.delayed(_time, () {
          if (mounted) {
            setState(() {
              _touchPoints.remove(event.pointer);
            });
          }
        });
      },
      onPointerCancel: (event) {
        Future.delayed(_time, () {
          if (mounted) {
            setState(() {
              _touchPoints.remove(event.pointer);
            });
          }
        });
      },
      child: Stack(
        children: [
          // 绘制触点指示器
          ..._touchPoints.entries.map((entry) {
            final offset = entry.value;
            return Positioned(
              left: offset.dx - 15,
              top: offset.dy - 15,
              child: _buildIndicator(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.pinkAccent.withAlpha(150),
        border: Border.all(color: Colors.pinkAccent, width: 2),
      ),
    );
  }
}
