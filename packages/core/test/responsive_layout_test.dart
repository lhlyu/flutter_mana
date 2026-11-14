import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana/src/widgets/mana_panel.dart';
import 'package:flutter_mana/src/widgets/mana_setting_panel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/helpers.dart';

class _NamedPlugin extends TestPlugin {
  _NamedPlugin(int index) : super(name: 'tool_$index');
  @override
  String getLocalizedDisplayName(Locale locale) => locale.languageCode == 'zh'
      ? '偏好设置与多语言检查'
      : 'Widget Inspector with a long name';
}

void main() {
  testWidgets('floating settings wrap values at narrow widths and large text', (
    tester,
  ) async {
    final runtime = ManaController(preferences: MemoryManaPreferences());
    await runtime.initialize();
    try {
      await tester.pumpWidget(
        testApp(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(3)),
            child: ManaScope(
              controller: runtime,
              child: const SizedBox(
                width: 100,
                height: 80,
                child: ManaSettingPanel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    }
  });

  for (final scale in [1.0, 1.1, 1.25, 1.3, 1.5, 2.0, 3.0]) {
    testWidgets('panel uses natural label heights at text scale $scale', (
      tester,
    ) async {
      final runtime = ManaController(
        plugins: List.generate(16, _NamedPlugin.new),
        preferences: MemoryManaPreferences(),
      );
      await runtime.initializePlugins();
      try {
        for (final size in [
          const Size(600, 400),
          const Size(287, 200),
          const Size(60, 90),
        ]) {
          for (final language in ['en', 'zh']) {
            await tester.pumpWidget(
              testApp(
                Localizations(
                  locale: Locale(language),
                  delegates: const [DefaultWidgetsLocalizations.delegate],
                  child: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontFamily: 'Ahem',
                        letterSpacing: .3,
                      ),
                      child: ManaScope(
                        controller: runtime,
                        child: SizedBox(
                          width: size.width,
                          height: size.height,
                          child: const ManaPanel(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$size / $language');
            await tester.ensureVisible(find.byKey(const ValueKey('tool_15')));
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'scroll $size / $language',
            );
          }
        }
      } finally {
        await tester.pumpWidget(const SizedBox());
        await runtime.close();
      }
    });
  }
}
