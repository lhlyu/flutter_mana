import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'selected_rect_painter.dart';

class AlignRulerBarrier extends StatefulWidget {
  final Size windowSize;

  final Size dotSize;

  final Offset dotCenterOffset;

  final TextStyle coordinateTextStyle;

  final Size coordinateTextSize;

  final bool snapToWidgetEnabled;

  final ValueChanged<Offset>? onDotPositionChanged;

  const AlignRulerBarrier({
    super.key,
    required this.windowSize,
    required this.dotSize,
    required this.dotCenterOffset,
    required this.coordinateTextStyle,
    required this.coordinateTextSize,
    required this.snapToWidgetEnabled,
    this.onDotPositionChanged,
  });

  @override
  State<AlignRulerBarrier> createState() => _AlignRulerBarrierState();
}

class _AlignRulerBarrierState extends State<AlignRulerBarrier> {
  late Offset _dotPosition;

  final ValueNotifier<RenderObject?> _selectedRenderObjectNotifier =
      ValueNotifier<RenderObject?>(null);

  @override
  void initState() {
    super.initState();

    _dotPosition = widget.windowSize.center(Offset.zero);
  }

  @override
  void dispose() {
    _selectedRenderObjectNotifier.dispose();
    super.dispose();
  }

  void _updateDotPosition(Offset newPosition, {bool isSnapping = false}) {
    setState(() => _dotPosition = newPosition);
    if (!isSnapping) {
      _selectedRenderObjectNotifier.value = null;
    }
    widget.onDotPositionChanged?.call(newPosition);
  }

  void _onPanUpdate(DragUpdateDetails dragDetails) {
    _updateDotPosition(dragDetails.globalPosition);
  }

  void _onPanEnd(DragEndDetails dragDetails) {
    if (!widget.snapToWidgetEnabled) {
      _selectedRenderObjectNotifier.value = null;
      return;
    }

    final List<RenderObject> objects = HitTestUtils.hitTest(_dotPosition);

    Offset? snappedOffset;
    RenderObject? snappedObject;

    for (final RenderObject obj in objects) {
      final Matrix4 transform = obj.getTransformTo(null);

      final Rect rect = obj.paintBounds.shift(
        Offset(transform.getTranslation().x, transform.getTranslation().y),
      );

      if (rect.contains(_dotPosition)) {
        double dx, dy;
        final double halfWidth = rect.width / 2;
        final double halfHeight = rect.height / 2;

        if (_dotPosition.dx <= rect.left + halfWidth) {
          dx = rect.left;
        } else {
          dx = rect.right;
        }

        if (_dotPosition.dy <= rect.top + halfHeight) {
          dy = rect.top;
        } else {
          dy = rect.bottom;
        }
        snappedOffset = Offset(dx, dy);
        snappedObject = obj;
        break;
      }
    }

    if (snappedOffset != null) {
      _updateDotPosition(snappedOffset, isSnapping: true);
      _selectedRenderObjectNotifier.value = snappedObject;
      HapticFeedback.mediumImpact();
    } else {
      _selectedRenderObjectNotifier.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double verticalLeftOffset =
        _dotPosition.dx - widget.coordinateTextSize.width;
    final double horizontalTopOffset =
        _dotPosition.dy - widget.coordinateTextSize.height;

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        Positioned.fill(
          child: ValueListenableBuilder<RenderObject?>(
            valueListenable: _selectedRenderObjectNotifier,
            builder: (context, selectedObject, child) {
              return CustomPaint(painter: SelectedRectPainter(selectedObject));
            },
          ),
        ),
        Positioned(
          left: 0,
          top: _dotPosition.dy,
          child: Container(
            width: widget.windowSize.width,
            height: 1,
            color: const Color(0xffff0000),
          ),
        ),
        Positioned(
          left: _dotPosition.dx,
          top: 0,
          child: Container(
            width: 1,
            height: widget.windowSize.height,
            color: const Color(0xffff0000),
          ),
        ),
        Positioned(
          top: horizontalTopOffset,
          left: _dotPosition.dx / 2 - widget.coordinateTextSize.width / 2,
          child: Text(
            _dotPosition.dx.toStringAsFixed(1),
            style: widget.coordinateTextStyle,
          ),
        ),
        Positioned(
          left: verticalLeftOffset,
          top: _dotPosition.dy / 2 - widget.coordinateTextSize.height / 2,
          child: Text(
            _dotPosition.dy.toStringAsFixed(1),
            style: widget.coordinateTextStyle,
          ),
        ),
        Positioned(
          left:
              _dotPosition.dx +
              (widget.windowSize.width - _dotPosition.dx) / 2 -
              widget.coordinateTextSize.width / 2,
          top: horizontalTopOffset,
          child: Text(
            (widget.windowSize.width - _dotPosition.dx).toStringAsFixed(1),
            style: widget.coordinateTextStyle,
          ),
        ),
        Positioned(
          top:
              _dotPosition.dy +
              (widget.windowSize.height - _dotPosition.dy) / 2 -
              widget.coordinateTextSize.height / 2,
          left: verticalLeftOffset,
          child: Text(
            (widget.windowSize.height - _dotPosition.dy).toStringAsFixed(1),
            style: widget.coordinateTextStyle,
          ),
        ),
        Positioned(
          left: _dotPosition.dx - widget.dotCenterOffset.dx,
          top: _dotPosition.dy - widget.dotCenterOffset.dy,
          child: GestureDetector(
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Container(
              height: widget.dotSize.height,
              width: widget.dotSize.width,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
                color: Colors.white.withAlpha(150),
              ),
              child: Center(
                child: Container(
                  height: widget.dotSize.width / 2.5,
                  width: widget.dotSize.height / 2.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withAlpha(130),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
