import 'package:flutter/material.dart';

import '../../../i18n/i18n_mixin.dart';

class GridContent extends StatefulWidget {
  final double gap;
  final bool showNumbers;

  final ValueChanged<bool>? onShowNumbersChanged;
  final ValueChanged<double>? onGapChanged;

  const GridContent({
    super.key,
    required this.gap,
    required this.showNumbers,
    this.onShowNumbersChanged,
    this.onGapChanged,
  });

  @override
  State<GridContent> createState() => _GridContentState();
}

class _GridContentState extends State<GridContent> with I18nMixin {
  bool _showNumbers = true;

  double _gap = 50;
  final List<double> _gapOptions = List.generate(
    20,
    (index) => (index + 1) * 10,
  );

  @override
  void initState() {
    super.initState();
    _gap = widget.gap;
    _showNumbers = widget.showNumbers;
  }

  void _onShowNumbersChanged(bool value) {
    widget.onShowNumbersChanged?.call(value);
    setState(() {
      _showNumbers = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        spacing: 8,
        children: [
          Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Switch(
                value: _showNumbers,
                onChanged: _onShowNumbersChanged,
                activeColor: Colors.red,
              ),
              Expanded(
                child: Text(
                  t('grid.show_numbers'),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text('${t('grid.gap')}: ${_gap.toInt()}px', style: TextStyle(fontSize: 16)),
              Slider(
                padding: EdgeInsets.zero,
                value: _gap,
                min: _gapOptions.first,
                max: _gapOptions.last,
                divisions: _gapOptions.length - 1,
                label: '${_gap.toInt()}px',
                onChanged: (value) {
                  // 吸附到最近的预设值（可选）
                  _gap = _gapOptions.reduce((a, b) => (value - a).abs() < (value - b).abs() ? a : b);
                  widget.onGapChanged?.call(_gap);
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
