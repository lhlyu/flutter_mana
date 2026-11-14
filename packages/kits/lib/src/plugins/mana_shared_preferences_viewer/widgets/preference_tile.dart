import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';
import '../preference_entry.dart';

class PreferenceTile extends StatelessWidget {
  const PreferenceTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });
  final PreferenceEntry entry;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(horizontal: 4),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final value = ManaButton(
          onPressed: onTap,
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: 4,
            children: [
              Text(
                entry.key,
                maxLines: 2,
                overflow: .ellipsis,
                style: const TextStyle(fontWeight: .bold, fontSize: 13),
              ),
              Text(
                '${entry.kind.label}: ${entry.value}',
                maxLines: 2,
                overflow: .ellipsis,
                style: const TextStyle(fontSize: 12, color: KitStyle.muted),
              ),
            ],
          ),
        );
        final actions = [
          KitCopyButton(entry.key),
          KitButton(
            label: kitText(context, 'common.delete'),
            icon: .clear,
            iconOnly: true,
            onPressed: onDelete,
          ),
        ];
        if (constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(13) > 20) {
          return Column(
            crossAxisAlignment: .stretch,
            children: [
              value,
              Wrap(alignment: .end, children: actions),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: value),
            ...actions,
          ],
        );
      },
    ),
  );
}
