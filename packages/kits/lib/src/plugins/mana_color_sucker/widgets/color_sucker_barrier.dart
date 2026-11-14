import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';

import '../../../ui/kit_ui.dart';
import 'screen_pixel_grabber.dart';

class ColorSuckerBarrier extends StatefulWidget {
  const ColorSuckerBarrier({
    super.key,
    this.magnification = 10,
    this.onColorChanged,
  });
  final double magnification;
  final ValueChanged<Color>? onColorChanged;
  @override
  State<ColorSuckerBarrier> createState() => _ColorSuckerBarrierState();
}

class _ColorSuckerBarrierState extends State<ColorSuckerBarrier> {
  late final _grabber = ScreenPixelGrabber(
    repaintBoundaryKey: ManaScope.read(context).rootKey,
  );
  Offset? _position;
  Object? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sample();
    });
  }

  @override
  void dispose() {
    _generation++;
    _grabber.dispose();
    super.dispose();
  }

  Future<void> _sample() async {
    final generation = ++_generation;
    final box = context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(
      _position ?? box.size.center(Offset.zero),
    );
    try {
      await _grabber.captureImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
      final color = _grabber.getColorAt(position);
      if (!mounted || generation != _generation) return;
      setState(() => _error = null);
      if (color != null) widget.onColorChanged?.call(color);
    } catch (error) {
      if (mounted && generation == _generation) setState(() => _error = error);
    }
  }

  void _move(Offset position) {
    final box = context.findRenderObject() as RenderBox;
    setState(() {
      _generation++;
      _position = Offset(
        position.dx.clamp(0, box.size.width),
        position.dy.clamp(0, box.size.height),
      );
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final position = _position ?? constraints.biggest.center(Offset.zero);
      return GestureDetector(
        behavior: .opaque,
        onTapUp: (details) {
          _move(details.localPosition);
          _sample();
        },
        onPanStart: (details) => _move(details.localPosition),
        onPanUpdate: (details) => _move(details.localPosition),
        onPanEnd: (_) => _sample(),
        child: Stack(
          children: [
            Positioned(
              left: position.dx - 45,
              top: position.dy - 45,
              child: IgnorePointer(
                child: RawMagnifier(
                  size: const Size(90, 90),
                  magnificationScale: widget.magnification,
                  decoration: const MagnifierDecoration(
                    shape: CircleBorder(
                      side: BorderSide(color: KitStyle.accent, width: 2),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        border: Border.all(color: KitStyle.accent),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_error case final error?)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  '$error',
                  style: const TextStyle(color: KitStyle.danger),
                ),
              ),
          ],
        ),
      );
    },
  );
}
