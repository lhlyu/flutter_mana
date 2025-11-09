import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';

class FpsMonitor extends StatelessWidget with I18nMixin {
  final String name;

  const FpsMonitor({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: name,
      initialHeight: 200,
      initialWidth: kIsWeb ? null : double.infinity,
      showBarrier: false,
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child:
            kIsWeb
                ? Center(child: Text(t('fps_monitor.tip'), style: TextStyle(color: Colors.red, fontSize: 20)))
                : PerformanceOverlay.allEnabled(),
      ),
    );
  }
}
