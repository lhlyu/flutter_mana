import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/widgets/response_detail.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/widgets/preference_editor.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/widgets/preference_tile.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/widgets/shared_preferences_viewer_content.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/host.dart';

Finder button(String label) => find.byWidgetPredicate(
  (widget) => widget is KitButton && widget.label == label,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'a.long.preference.key': <Object?>['English', '中文'],
      'a.boolean': true,
    });
    PackageInfo.setMockInitialValues(
      appName: 'Example',
      packageName: 'test.example',
      version: '2.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  for (final (size, scale, language) in [
    (const Size(1024, 768), 1.0, 'en'),
    (const Size(360, 640), 1.15, 'zh'),
    (const Size(240, 320), 2.0, 'zh'),
    (const Size(160, 200), 3.0, 'en'),
    (const Size(96, 140), 2.0, 'zh'),
    (const Size(640, 160), 1.5, 'zh'),
    (const Size(360, 100), 3.0, 'en'),
  ]) {
    testWidgets('all kits at $size / text $scale / $language', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      tester.platformDispatcher.localesTestValue = [Locale(language)];
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final requests = ManaDioCollector()
        ..addResponse(
          Response(
            requestOptions: RequestOptions(
              path: 'https://example.test/a/long/path',
            ),
            statusCode: 200,
            data: {'hello': '你好'},
          ),
        );
      final logs = ManaLogCollector()
        ..output(
          OutputEvent(
            LogEvent(
              Level.warning,
              'A multiline message / 一条中文日志\nsecond line',
            ),
            [],
          ),
        );
      final runtime = ManaController(
        plugins: loadAllPlugins(dioCollector: requests, logCollector: logs),
        preferences: MemoryManaPreferences(),
      );
      try {
        await tester.pumpWidget(
          ManaWidget(controller: runtime, child: const Text('Host')),
        );
        await tester.pumpAndSettle();
        runtime.openPluginPanel();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'tool panel');
        runtime.closePluginPanel();
        for (final entry in runtime.plugins.entries.where(
          (entry) => entry.plugin.isSupported,
        )) {
          await runtime.activatePlugin(entry.plugin.name);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: entry.plugin.name);
          final settings = find
              .byWidgetPredicate(
                (widget) =>
                    widget is ManaButton &&
                    widget.tooltip == (language == 'zh' ? '设置' : 'Settings'),
              )
              .hitTestable();
          if (settings.evaluate().isNotEmpty) {
            await tester.tap(settings);
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.plugin.name} settings',
            );
            await tester.tap(settings);
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.plugin.name} settings closed',
            );
          }
          runtime.toggleFullscreen();
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.plugin.name} fullscreen',
          );
          await runtime.closePlugin();
          await tester.pumpAndSettle();
        }
      } finally {
        await tester.pumpWidget(const SizedBox());
        await runtime.close();
        requests.dispose();
        logs.dispose();
      }
    });
  }

  testWidgets('live resizing preserves search, focus and active session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final runtime = ManaController(
      plugins: [ManaDioInspector()],
      preferences: MemoryManaPreferences(),
    );
    try {
      await tester.pumpWidget(
        testHost(
          ManaWidget.builder(controller: runtime, child: const Text('Host')),
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      await runtime.activatePlugin('mana_dio_inspector');
      await tester.pumpAndSettle();
      await tester.ensureVisible(button('Search'));
      await tester.tap(button('Search'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'keep query');
      final before = tester.widget<EditableText>(find.byType(EditableText));
      for (final size in [
        const Size(240, 320),
        const Size(640, 160),
        const Size(96, 140),
        const Size(700, 600),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        final after = tester.widget<EditableText>(find.byType(EditableText));
        expect(after.controller, same(before.controller));
        expect(after.controller.text, 'keep query');
        expect(after.focusNode.hasFocus, isTrue);
        expect(runtime.state.activePluginId, 'mana_dio_inspector');
        expect(tester.takeException(), isNull, reason: '$size');
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    }
  });

  testWidgets('short response details keep actions scrollable at large text', (
    tester,
  ) async {
    final response = Response<Object?>(
      requestOptions: RequestOptions(
        path: 'https://example.test/very/long/request',
        data: {'hello': '你好'},
      ),
      statusCode: 200,
      data: {'response': 'body'},
    );
    await tester.pumpWidget(
      testHost(
        Center(
          child: SizedBox(
            width: 180,
            height: 100,
            child: ResponseDetail(response: response, onClose: () {}),
          ),
        ),
        scale: 3,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final moreMenu = find.byWidgetPredicate(
      (widget) => widget is ManaButton && widget.tooltip == 'More actions',
    );
    await tester.ensureVisible(moreMenu);
    await tester.tap(moreMenu);
    await tester.pumpAndSettle();
    await tester.ensureVisible(button('Copy HTTP'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(button('Copy HTTP').hitTestable(), findsOneWidget);
    expect(tester.getSize(find.byType(KitScaffold).first).height, 100);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('preference list ignores inherited top safe-area padding', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 48);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(testHost(const SharedPreferencesViewerContent()));
    await tester.pumpAndSettle();

    final list = find.byType(ListView);
    final firstRow = find.byType(PreferenceTile).first;
    expect(tester.getTopLeft(firstRow).dy, tester.getTopLeft(list).dy);
  });

  testWidgets(
    'preference filter and clear confirmation remain reachable in a short window',
    (tester) async {
      await tester.pumpWidget(
        testHost(
          Center(
            child: SizedBox(
              width: 180,
              height: 100,
              child: const SharedPreferencesViewerContent(),
            ),
          ),
          scale: 3,
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['Search', 'Clear', 'Cancel']) {
        await tester.ensureVisible(button(label));
        await tester.pumpAndSettle();
        final visible = tester
            .getRect(button(label))
            .intersect(
              tester.getRect(find.byType(SharedPreferencesViewerContent)),
            );
        expect(visible.isEmpty, isFalse);
        await tester.tapAt(visible.center);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: label);
      }
      expect(button('Cancel'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('a.boolean'), isTrue);
      await tester.ensureVisible(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'a.boolean');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('preference editing remains usable in a short RTL viewport', (
    tester,
  ) async {
    var saved = false;
    await tester.pumpWidget(
      testHost(
        Center(
          child: SizedBox(
            width: 180,
            height: 100,
            child: PreferenceEditor(
              onClose: () {},
              onSave: (_) async {
                saved = true;
              },
            ),
          ),
        ),
        scale: 2,
        direction: .rtl,
      ),
    );
    await tester.pumpAndSettle();
    final key = find.byType(EditableText).first;
    await tester.ensureVisible(key);
    await tester.enterText(key, 'new.key');
    await tester.ensureVisible(button('Save'));
    await tester.tap(button('Save'));
    await tester.pumpAndSettle();
    expect(saved, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
