import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mana_style.dart';

/// A discrete slider built from gestures, focus and semantics.
class ManaSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) formatValue;
  final String semanticLabel;
  final ValueChanged<double> onChanged;

  const ManaSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.formatValue,
    required this.semanticLabel,
    required this.onChanged,
  }) : assert(max > min),
       assert(divisions > 0);

  @override
  State<ManaSlider> createState() => _ManaSliderState();
}

class _ManaSliderState extends State<ManaSlider> {
  final _focusNode = FocusNode();
  bool _focused = false;
  late double _lastValue = _value;

  double get _step => (widget.max - widget.min) / widget.divisions;
  double get _value => widget.value.isFinite
      ? widget.value.clamp(widget.min, widget.max)
      : widget.min;

  @override
  void didUpdateWidget(ManaSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _lastValue = _value;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  double _snap(double value) {
    final index = ((value.clamp(widget.min, widget.max) - widget.min) / _step)
        .round();
    return (widget.min + index * _step).clamp(widget.min, widget.max);
  }

  void _change(double value) {
    final next = _snap(value);
    // 一个拖动周期可能在父组件重建前多次落到同一档位。
    if ((next - _lastValue).abs() < _step * 1e-8) return;
    _lastValue = next;
    widget.onChanged(next);
  }

  void _updatePosition(double x, double width, bool rtl) {
    _focusNode.requestFocus();
    final radius = math.min(10.0, width / 2);
    final trackWidth = width - 2 * radius;
    if (trackWidth <= 0) return;
    var fraction = ((x - radius) / trackWidth).clamp(0.0, 1.0);
    if (rtl) fraction = 1 - fraction;
    _change(widget.min + fraction * (widget.max - widget.min));
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == .rtl;
    final fraction = (_value - widget.min) / (widget.max - widget.min);
    final canIncrease = _value < widget.max;
    final canDecrease = _value > widget.min;
    return Semantics(
      slider: true,
      label: widget.semanticLabel,
      value: widget.formatValue(_value),
      increasedValue: canIncrease
          ? widget.formatValue(_snap(_value + _step))
          : null,
      decreasedValue: canDecrease
          ? widget.formatValue(_snap(_value - _step))
          : null,
      onIncrease: canIncrease ? () => _change(_lastValue + _step) : null,
      onDecrease: canDecrease ? () => _change(_lastValue - _step) : null,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _change(_lastValue + (rtl ? -_step : _step)),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _change(_lastValue + (rtl ? _step : -_step)),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              _change(_lastValue + _step),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              _change(_lastValue - _step),
          const SingleActivator(LogicalKeyboardKey.home): () =>
              _change(widget.min),
          const SingleActivator(LogicalKeyboardKey.end): () =>
              _change(widget.max),
        },
        child: Focus(
          focusNode: _focusNode,
          onFocusChange: (value) => setState(() => _focused = value),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: LayoutBuilder(
              builder: (context, constraints) {
                assert(
                  constraints.hasBoundedWidth,
                  'ManaSlider requires a bounded width.',
                );
                void update(Offset position) =>
                    _updatePosition(position.dx, constraints.maxWidth, rtl);
                return GestureDetector(
                  behavior: .opaque,
                  excludeFromSemantics: true,
                  // 不在 tap-down 时更改值，避免竖向滚动尚未决出手势时误触。
                  onTapUp: (details) => update(details.localPosition),
                  onHorizontalDragStart: (details) =>
                      update(details.localPosition),
                  onHorizontalDragUpdate: (details) =>
                      update(details.localPosition),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 40),
                    painter: _SliderPainter(fraction, rtl, _focused),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderPainter extends CustomPainter {
  final double fraction;
  final bool rtl;
  final bool focused;

  const _SliderPainter(this.fraction, this.rtl, this.focused);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(10.0, size.width / 2);
    final start = Offset(radius, size.height / 2);
    final end = Offset(size.width - radius, size.height / 2);
    final thumb = Offset(
      start.dx + (end.dx - start.dx) * (rtl ? 1 - fraction : fraction),
      start.dy,
    );
    final paint = Paint()
      ..color = ManaStyle.border
      ..strokeWidth = 4
      ..strokeCap = .round;
    canvas.drawLine(start, end, paint);
    paint.color = ManaStyle.accent;
    canvas.drawLine(rtl ? end : start, thumb, paint);
    if (focused) {
      canvas.drawCircle(
        thumb,
        radius + 4,
        Paint()..color = ManaStyle.accent.withValues(alpha: 0.16),
      );
    }
    canvas.drawCircle(thumb, radius, paint);
  }

  @override
  bool shouldRepaint(_SliderPainter oldDelegate) =>
      fraction != oldDelegate.fraction ||
      rtl != oldDelegate.rtl ||
      focused != oldDelegate.focused;
}
