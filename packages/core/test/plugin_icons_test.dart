import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana/src/widgets/floating_button/index.dart';
import 'package:flutter_mana/src/widgets/mana_panel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/helpers.dart';

class _WidgetIconPlugin extends ManaPluggable {
  @override
  String get name => 'widget_icon';
  @override
  String getLocalizedDisplayName(Locale locale) => 'Widget icon';
  @override
  Widget buildIcon(BuildContext context, {double size = 40}) => SizedBox.square(
    key: const ValueKey('custom_icon'),
    dimension: size,
    child: const ColoredBox(color: Color(0xFF35B5D1)),
  );
  @override
  Widget buildWidget(BuildContext context) =>
      ManaFloatingWindow(name: name, content: const Text('Custom plugin'));
}

void main() {
  testWidgets('image-provider plugins retain their panel and entry icons', (
    tester,
  ) async {
    final plugin = TestPlugin();
    final runtime = ManaController(
      plugins: [plugin],
      preferences: MemoryManaPreferences(),
    );
    try {
      await tester.pumpWidget(
        ManaWidget(controller: runtime, child: const SizedBox.expand()),
      );
      await tester.pumpAndSettle();
      runtime.openPluginPanel();
      await tester.pumpAndSettle();
      final panelImage = tester.widget<Image>(
        find.descendant(
          of: find.byType(ManaPanel),
          matching: find.byType(Image),
        ),
      );
      expect(panelImage.image, same(plugin.iconImageProvider));
      expect(panelImage.width, 40);
      await runtime.activatePlugin(plugin.name);
      await tester.pumpAndSettle();
      final entryImage = tester.widget<Image>(
        find.descendant(
          of: find.byType(FloatingButton),
          matching: find.byType(Image),
        ),
      );
      expect(entryImage.image, same(plugin.iconImageProvider));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    }
  });

  testWidgets(
    'third-party widget icons need no image provider and resize in both hosts',
    (tester) async {
      final plugin = _WidgetIconPlugin();
      final runtime = ManaController(
        plugins: [plugin],
        preferences: MemoryManaPreferences(),
      );
      try {
        await tester.pumpWidget(
          ManaWidget(controller: runtime, child: const SizedBox.expand()),
        );
        await tester.pumpAndSettle();
        runtime.openPluginPanel();
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const ValueKey('custom_icon'))),
          const Size.square(40),
        );
        await runtime.activatePlugin(plugin.name);
        await tester.pumpAndSettle();
        runtime.updateSettings(buttonSize: 90);
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const ValueKey('custom_icon'))),
          const Size.square(60),
        );
        runtime.openPluginPanel();
        await tester.pumpAndSettle();
        final sizes = tester
            .widgetList<SizedBox>(find.byKey(const ValueKey('custom_icon')))
            .map((widget) => widget.width)
            .toSet();
        expect(sizes, {40, 60});
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await runtime.close();
      }
    },
  );
}
