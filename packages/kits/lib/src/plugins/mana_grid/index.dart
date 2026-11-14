import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import 'widgets/grid.dart';

class ManaGrid extends BuiltinKit {
  ManaGrid()
    : super(name: 'mana_grid', title: 'Grid', chineseTitle: '网格', icon: .grid);
  @override
  Widget buildWidget(BuildContext context) => Grid(name: name);
}
