import 'package:flutter/material.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';

class AlignRulerContent extends StatelessWidget with I18nMixin {
  final Offset dotPosition;

  final Size windowSize;

  final bool snapToWidgetEnabled;

  final TextStyle coordinateTextStyle;

  final ValueChanged<bool> onSnapToWidgetChanged;

  final GestureDragUpdateCallback? onVerticalDragUpdate;

  const AlignRulerContent({
    super.key,
    required this.dotPosition,
    required this.windowSize,
    required this.snapToWidgetEnabled,
    required this.coordinateTextStyle,
    required this.onSnapToWidgetChanged,
    this.onVerticalDragUpdate,
  });

  static const double estimatedToolbarHeight = 60.0 + 40.0 + 16.0 + 12.0;

  Widget _buildDotPosition() {
    final left = dotPosition.dx.toStringAsFixed(1);
    final top = dotPosition.dy.toStringAsFixed(1);
    final right = (windowSize.width - dotPosition.dx).toStringAsFixed(1);
    final bottom = (windowSize.height - dotPosition.dy).toStringAsFixed(1);

    return Column(
      spacing: 4,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Left: $left'),
            Text('Top: $top'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Right: $right'),
            Text('Bottom: $bottom'),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onVerticalDragUpdate: onVerticalDragUpdate,
      child: Container(
        width: screenWidth * 0.8,
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            _buildDotPosition(),
            Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Switch(
                  value: snapToWidgetEnabled,
                  onChanged: onSnapToWidgetChanged,
                  activeColor: Colors.red,
                ),
                Expanded(
                  child: Text(
                    t('align_ruler.tip'),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
