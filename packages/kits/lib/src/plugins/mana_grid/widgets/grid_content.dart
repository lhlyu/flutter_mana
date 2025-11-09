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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    t('grid.gap'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${_gap.toInt()}px',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              Slider(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                value: _gap,
                min: _gapOptions.first,
                max: _gapOptions.last,
                divisions: _gapOptions.length - 1,
                label: '${_gap.toInt()}px',
                onChanged: (value) {
                  // 吸附到最近的预设值（可选）
                  _gap = _gapOptions.reduce(
                    (a, b) => (value - a).abs() < (value - b).abs() ? a : b,
                  );
                  widget.onGapChanged?.call(_gap);
                  setState(() {});
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t('grid.show_numbers'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                value: _showNumbers,
                onChanged: _onShowNumbersChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
