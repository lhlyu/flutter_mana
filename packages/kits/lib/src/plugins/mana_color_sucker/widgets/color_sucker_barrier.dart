import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'screen_pixel_grabber.dart';

class ColorSuckerBarrier extends StatefulWidget {
  final double magnifierRadius;

  final Color borderColor;

  final double borderWidth;

  final double magnification;

  final Offset? initialPosition;

  final ValueChanged<Color>? onColorChanged;

  const ColorSuckerBarrier({
    super.key,
    this.magnifierRadius = 50,
    this.borderColor = Colors.grey,
    this.borderWidth = 2,
    this.magnification = 10.0,
    this.initialPosition,
    this.onColorChanged,
  });

  @override
  State<ColorSuckerBarrier> createState() => _ColorSuckerBarrierState();
}

class _ColorSuckerBarrierState extends State<ColorSuckerBarrier> {
  Offset? _dragPosition;
  late ScreenPixelGrabber _pixelGrabber;

  @override
  void initState() {
    super.initState();
    _pixelGrabber = ScreenPixelGrabber(repaintBoundaryKey: manaRootKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeColorSucker();
    });
  }

  Offset _getDefaultCenterPosition() {
    final Size screenSize = MediaQuery.sizeOf(context);
    return widget.initialPosition ??
        Offset(screenSize.width / 2, screenSize.height / 2);
  }

  Future<void> _initializeColorSucker() async {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    await _pixelGrabber.captureImage(pixelRatio: devicePixelRatio);

    if (mounted) {
      final defaultCenterPosition = _getDefaultCenterPosition();

      setState(() {
        _dragPosition = defaultCenterPosition;
      });
      _onUpdate(defaultCenterPosition, true);
    }
  }

  Future<void> _onUpdate(Offset globalPosition, [bool end = false]) async {
    setState(() {
      _dragPosition = globalPosition;
    });

    if (!end) {
      return;
    }

    final color = await _pixelGrabber.getColorAt(globalPosition);

    if (color != null) {
      widget.onColorChanged?.call(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultDragPosition = _getDefaultCenterPosition();

    final dragPosition = _dragPosition ?? defaultDragPosition;

    return GestureDetector(
      onPanDown: (details) => _onUpdate(details.globalPosition),
      onPanUpdate: (details) => _onUpdate(details.globalPosition),
      onPanEnd: (details) => _onUpdate(details.globalPosition, true),
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.transparent)),
          Positioned(
            left: dragPosition.dx - widget.magnifierRadius,
            top: dragPosition.dy - widget.magnifierRadius,
            child: RawMagnifier(
              size: Size(
                widget.magnifierRadius * 2,
                widget.magnifierRadius * 2,
              ),
              magnificationScale: widget.magnification,
              decoration: MagnifierDecoration(
                shape: CircleBorder(
                  side: BorderSide(
                    color: widget.borderColor,
                    width: widget.borderWidth,
                  ),
                ),
              ),
              focalPointOffset: Offset.zero,
              child: Container(
                width: widget.magnifierRadius * 2,
                height: widget.magnifierRadius * 2,
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
