import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

void main() => runApp(const _KitsSmokeHost());

class _KitsSmokeHost extends StatefulWidget {
  const _KitsSmokeHost();
  @override
  State<_KitsSmokeHost> createState() => _KitsSmokeHostState();
}

class _KitsSmokeHostState extends State<_KitsSmokeHost> {
  late final _controller = ManaController(
    preferences: MemoryManaPreferences(),
    plugins: loadAllPlugins(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ManaWidget(
    controller: _controller,
    child: const Center(child: Text('Widgets-only Mana Kits')),
  );
}
