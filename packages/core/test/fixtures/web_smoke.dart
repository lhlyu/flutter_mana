import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana/flutter_mana_diagnostics.dart';

void main() {
  runApp(
    ManaWidget(
      controller: ManaController(preferences: MemoryManaPreferences()),
      child: Center(child: Text('VM supported: ${VmInspector().isSupported}')),
    ),
  );
}
