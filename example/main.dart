import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

void main() async {
  ManaPluginManager.instance
    ..register(ManaVisualHelper())
    ..register(ManaGrid())
    ..register(ManaLicense())
    ..register(ManaPackageInfo())
    ..register(ManaMemoryInfo())
    ..register(ManaShowCode())
    ..register(ManaLogViewer())
    ..register(ManaDeviceInfo())
    ..register(ManaColorSucker())
    ..register(ManaDioInspector())
    ..register(ManaWidgetInfoInspector())
    ..register(ManaFpsMonitor())
    ..register(ManaSharedPreferencesViewer())
    ..register(ManaAlignRuler());

  runApp(ManaWidget(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Example',
      home: Text('Example'),
    );
  }
}
