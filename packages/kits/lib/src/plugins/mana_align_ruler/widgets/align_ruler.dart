import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'align_ruler_barrier.dart';
import 'align_ruler_content.dart';

class AlignRuler extends StatefulWidget {
  final String name;

  const AlignRuler({super.key, required this.name});

  @override
  State<AlignRuler> createState() => _AlignRulerState();
}

class _AlignRulerState extends State<AlignRuler> {
  Size _windowSize = Size.zero;

  Offset _dotPosition = Offset.zero;

  final Size _dotSize = const Size(80, 80);

  late Offset _dotCenterOffset;

  static final TextStyle _coordinateTextStyle = TextStyle(
    color: Colors.red,
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  Size _coordinateTextSize = Size.zero;

  double _toolBarY = 60.0;

  bool _snapToWidgetEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _windowSize = MediaQuery.of(context).size;
        _dotPosition = _windowSize.center(Offset.zero);
        _dotCenterOffset = _dotSize.center(Offset.zero);
        _coordinateTextSize = _getTextSize(_coordinateTextStyle);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _toolBarPanUpdate(DragUpdateDetails dragDetails) {
    setState(() {
      _toolBarY = dragDetails.globalPosition.dy - 40;
      _toolBarY = _toolBarY.clamp(0.0, _windowSize.height - AlignRulerContent.estimatedToolbarHeight - 16);
    });
  }

  Size _getTextSize(TextStyle style) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: '9999.9',
        style: style,
      ),
    );
    textPainter.layout();
    return Size(textPainter.width, textPainter.height);
  }

  void _switchSnapToWidget(bool enabled) {
    setState(() {
      _snapToWidgetEnabled = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_windowSize.isEmpty) {
      _windowSize = MediaQuery.of(context).size;
      _dotCenterOffset = _dotSize.center(Offset.zero);
      _coordinateTextSize = _getTextSize(_coordinateTextStyle);
    }

    return ManaFloatingWindow(
      name: widget.name,
      initialHeight: 180,
      position: PositionType.top,
      content: AlignRulerContent(
        dotPosition: _dotPosition,
        windowSize: _windowSize,
        snapToWidgetEnabled: _snapToWidgetEnabled,
        coordinateTextStyle: _coordinateTextStyle,
        onSnapToWidgetChanged: _switchSnapToWidget,
        onVerticalDragUpdate: _toolBarPanUpdate,
      ),
      barrier: AlignRulerBarrier(
        windowSize: _windowSize,
        dotSize: _dotSize,
        dotCenterOffset: _dotCenterOffset,
        coordinateTextStyle: _coordinateTextStyle,
        coordinateTextSize: _coordinateTextSize,
        snapToWidgetEnabled: _snapToWidgetEnabled,
        onDotPositionChanged: (Offset offset) {
          setState(() {
            _dotPosition = offset;
          });
        },
      ),
    );
  }
}
