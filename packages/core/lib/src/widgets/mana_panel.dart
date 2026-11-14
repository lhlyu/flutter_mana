import 'dart:async';
import 'dart:math' as math;

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
    return SingleChildScrollView(
      padding: const .all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Let text determine each run's height: fonts, fractional scaling and
          // fallback glyphs cannot reliably be reduced to a fixed line height.
          const spacing = 4.0;
          final preferredWidth =
              72 *
              (MediaQuery.textScalerOf(context).scale(10) / 10).clamp(1, 2);
          final columns = math.max(
            1,
            ((constraints.maxWidth + spacing) / (preferredWidth + spacing))
                .floor(),
          );
          final width = math.max(
            0.0,
            (constraints.maxWidth - spacing * (columns - 1)) / columns,
          );
          final icon = math.min(iconSize, math.max(0.0, width - 8));
          return Wrap(
            spacing: spacing,
            runSpacing: 8,
            children: [
              for (final entry in entries)
                SizedBox(
                  width: width,
                  child: Semantics(
                    value: entry.status.name,
                    child: ManaButton(
                      key: ValueKey(entry.plugin.name),
                      padding: const .all(4),
                      tooltip:
                          entry.error?.toString() ??
                          entry.plugin.getLocalizedDisplayName(locale),
                      onPressed: entry.status == .ready
                          ? () => unawaited(
                              controller.activatePlugin(entry.plugin.name),
                            )
                          : null,
                      child: Column(
                        mainAxisSize: .min,
                        spacing: 4,
                        children: [
                          ClipRRect(
                            borderRadius: .circular(8),
                            child: SizedBox.square(
                              dimension: icon,
                              child: entry.status == .ready
                                  ? entry.plugin.buildIcon(context, size: icon)
                                  : ManaIcon(
                                      .blocked,
                                      size: icon,
                                      color: ManaStyle.muted,
                                    ),
                            ),
                          ),
                          Text(
                            entry.plugin.getLocalizedDisplayName(locale),
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.4,
                              color:
                                  controller.state.activePluginId ==
                                      entry.plugin.name
                                  ? ManaStyle.danger
                                  : ManaStyle.text,
                              fontWeight:
                                  controller.state.activePluginId ==
                                      entry.plugin.name
                                  ? .bold
                                  : .normal,
                            ),
                            maxLines: 2,
                            textAlign: .center,
                            overflow: .ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
