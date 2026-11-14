import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'grid_barrier.dart';
import 'grid_content.dart';

class Grid extends StatefulWidget {
  final String name;

  const Grid({super.key, required this.name});

  @override
  State<Grid> createState() => _GridState();
}

class _GridState extends State<Grid> {
  double _gap = 50;
  bool _showNumbers = true;
  late final ManaPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = ManaScope.read(context).preferences;
    _gap = (_preferences.read('mana_grid_gap') as double?) ?? 50;
    _showNumbers =
        (_preferences.read('mana_grid_show_numbers') as bool?) ?? true;
  }

  void _onGapChanged(double value) async {
    setState(() => _gap = value);
    await _preferences.write('mana_grid_gap', value);
  }

  void _onShowNumbersChanged(bool value) async {
    setState(() => _showNumbers = value);
    await _preferences.write('mana_grid_show_numbers', value);
  }

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: widget.name,
      initialHeight: 180,
      content: GridContent(
        gap: _gap,
        showNumbers: _showNumbers,
        onGapChanged: _onGapChanged,
        onShowNumbersChanged: _onShowNumbersChanged,
      ),
      barrier: GridBarrier(gap: _gap, showNumbers: _showNumbers),
    );
  }
}
