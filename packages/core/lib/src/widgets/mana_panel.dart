import 'dart:async';

import 'package:flutter/widgets.dart';

import '../runtime/mana_scope.dart';
import 'mana_button.dart';
import 'mana_icon.dart';
import 'mana_style.dart';

class ManaPanel extends StatelessWidget {
  const ManaPanel({super.key});
  static const double iconSize = 40;

  @override
  Widget build(BuildContext context) {
    final controller = ManaScope.of(context);
    final locale = Localizations.localeOf(context);
    final entries = controller.plugins.entries;
    final labelHeight = MediaQuery.textScalerOf(context).scale(10) * 1.4 * 2;
    return GridView.builder(
      padding: const .all(8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 72,
        mainAxisExtent: iconSize + 4 + labelHeight,
        mainAxisSpacing: 4,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final plugin = entry.plugin;
        final ready = entry.status == .ready;
        final active = controller.state.activePluginId == plugin.name;
        return Semantics(
          value: entry.status.name,
          child: ManaButton(
            key: ValueKey(plugin.name),
            padding: .zero,
            tooltip: entry.error?.toString(),
            onPressed: ready
                ? () => unawaited(controller.activatePlugin(plugin.name))
                : null,
            child: Column(
              spacing: 4,
              children: [
                ClipRRect(
                  borderRadius: .circular(8),
                  child: SizedBox.square(
                    dimension: iconSize,
                    child: ready
                        ? plugin.buildIcon(context, size: iconSize)
                        : const ManaIcon(
                            .blocked,
                            color: ManaStyle.muted,
                            size: iconSize,
                          ),
                  ),
                ),
                Text(
                  plugin.getLocalizedDisplayName(locale),
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: active ? ManaStyle.danger : ManaStyle.text,
                    fontWeight: active ? .bold : .normal,
                  ),
                  maxLines: 2,
                  textAlign: .center,
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
