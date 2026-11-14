import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class ScreenPixelGrabber {
  ScreenPixelGrabber({required this.repaintBoundaryKey});
  final GlobalKey repaintBoundaryKey;
  ByteData? _pixels;
  int _width = 0;
  int _height = 0;
  Size _size = Size.zero;
  int _generation = 0;
  bool _disposed = false;

  Future<void> captureImage({required double pixelRatio}) async {
    if (_disposed) return;
    final generation = ++_generation;
    final object = repaintBoundaryKey.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary ||
        !object.hasSize ||
        object.size.isEmpty) {
      throw StateError('Host is not ready for capture');
    }
    final size = object.size;
    final image = await object.toImage(pixelRatio: pixelRatio);
    try {
      final bytes = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (_disposed || generation != _generation) return;
      if (bytes == null) throw StateError('Host pixels are unavailable');
      _pixels = bytes;
      _width = image.width;
      _height = image.height;
      _size = size;
    } finally {
      image.dispose();
    }
  }

  Color? getColorAt(Offset globalPosition) {
    final object = repaintBoundaryKey.currentContext?.findRenderObject();
    final pixels = _pixels;
    if (object is! RenderBox ||
        pixels == null ||
        !object.attached ||
        object.size != _size) {
      return null;
    }
    final point = object.globalToLocal(globalPosition);
    if (!(Offset.zero & _size).contains(point)) return null;
    final x = (point.dx * _width / _size.width).floor().clamp(0, _width - 1);
    final y = (point.dy * _height / _size.height).floor().clamp(0, _height - 1);
    final offset = (y * _width + x) * 4;
    return Color.fromARGB(
      pixels.getUint8(offset + 3),
      pixels.getUint8(offset),
      pixels.getUint8(offset + 1),
      pixels.getUint8(offset + 2),
    );
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _pixels = null;
  }
}
