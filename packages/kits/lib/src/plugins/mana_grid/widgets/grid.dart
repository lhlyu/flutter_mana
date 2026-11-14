import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';

import '../../../ui/kit_ui.dart';
import 'grid_barrier.dart';
import 'grid_content.dart';

class Grid extends StatefulWidget {
  const Grid({super.key, required this.name});
  final String name;
  @override
  State<Grid> createState() => _GridState();
}

class _GridState extends State<Grid> {
  late final _preferences = ManaScope.read(context).preferences;
  late double _gap = switch (_preferences.read('mana_grid_gap')) {
    final num value when value.isFinite => value.toDouble().clamp(10, 100),
    _ => 50,
  };
  late bool _numbers = _preferences.read('mana_grid_show_numbers') != false;
  Object? _error;
  Future<void> _save(String key, Object value) async {
    try {
      await _preferences.write(key, value);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => KitWindow(
    name: widget.name,
    initialHeight: 210,
    barrier: GridBarrier(gap: _gap, showNumbers: _numbers),
    content: KitScaffold(
      body: GridContent(
        gap: _gap,
        showNumbers: _numbers,
        onGapChanged: (value) {
          setState(() => _gap = value);
          _save('mana_grid_gap', value);
        },
        onShowNumbersChanged: (value) {
          setState(() => _numbers = value);
          _save('mana_grid_show_numbers', value);
        },
      ),
      footer: _error == null
          ? null
          : Text('$_error', style: const TextStyle(color: KitStyle.danger)),
    ),
  );
}
