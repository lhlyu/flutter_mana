import 'package:flutter/widgets.dart';

import '../runtime/mana_plugin_manager.dart';
import '../runtime/mana_scope.dart';
import 'floating_button/index.dart';
import 'floating_window/index.dart';
import 'mana_panel.dart';
import 'mana_setting_panel.dart';

/// Presentation only; the controller owns state and resources.
class ManaOverlay extends StatelessWidget {
  const ManaOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ManaScope.of(context);
    final state = controller.state;
    final id = state.activePluginId;
    final plugin = id == null ? null : controller.plugins[id]?.plugin;
    return Stack(
      children: [
        if (plugin?.buildWidget(context) case final content?)
          KeyedSubtree(key: ValueKey(id), child: content),
        if (state.pluginPanelVisible)
          const ManaFloatingWindow(
            name: ManaPluginManager.name,
            content: ManaPanel(),
            setting: ManaSettingPanel(),
          ),
        if (state.floatingButtonVisible) const FloatingButton(),
      ],
    );
  }
}
