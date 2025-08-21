import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScreenPixelGrabber {
  final GlobalKey repaintBoundaryKey;
  ui.Image? _capturedImage;

  ScreenPixelGrabber({required this.repaintBoundaryKey});

  Future<void> captureImage({required double pixelRatio}) async {
    try {
      final RenderRepaintBoundary? boundary =
          repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint("Error: Repaint boundary context is null or not a RenderRepaintBoundary.");
        _capturedImage = null;
        return;
      }

      _capturedImage = await boundary.toImage(pixelRatio: pixelRatio);
    } catch (e) {
      debugPrint("Error capturing screenshot: $e");
      _capturedImage = null;
    }
  }

  Future<Color?> getColorAt(Offset globalPosition) async {
    if (_capturedImage == null) {
      debugPrint("Warning: No image captured yet to get color from.");
      return null;
    }

    final RenderBox? box = repaintBoundaryKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      debugPrint("Warning: Repaint boundary context or RenderBox is null in getColorAt.");
      return null;
    }

    final Offset local = box.globalToLocal(globalPosition);

    final double pixelRatio = _capturedImage!.width / box.size.width;

    int px = (local.dx * pixelRatio).round().clamp(0, _capturedImage!.width - 1);
    int py = (local.dy * pixelRatio).round().clamp(0, _capturedImage!.height - 1);

    final ByteData? data = await _capturedImage!.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) {
      debugPrint("Error: Could not get byte data from image in getColorAt.");
      return null;
    }

    final int bytesPerPixel = 4;
    final int offset = (py * _capturedImage!.width + px) * bytesPerPixel;

    if (offset < 0 || offset + bytesPerPixel > data.lengthInBytes) {
      debugPrint(
          "Error: Pixel offset out of bounds in getColorAt. Offset: $offset, Data length: ${data.lengthInBytes}");
      return null;
    }

    final int r = data.getUint8(offset);
    final int g = data.getUint8(offset + 1);
    final int b = data.getUint8(offset + 2);
    final int a = data.getUint8(offset + 3);

    return Color.fromARGB(a, r, g, b);
  }
}
