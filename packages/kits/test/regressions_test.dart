import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/widgets/dio_inspector_content.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/widgets/response_tile.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/preferences_repository.dart';
import 'package:flutter_mana_kits/src/plugins/mana_log_viewer/widgets/log_viewer_content.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/preference_entry.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/widgets/preference_editor.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/src/plugins/mana_screen_info/widgets/screen_info_content.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/widgets/shared_preferences_viewer_content.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/host.dart';

Finder button(String label) => find.byWidgetPredicate(
  (widget) => widget is KitButton && widget.label == label,
);

class _PendingPreferences extends PreferencesRepository {
  final saved = Completer<void>();
  @override
  Future<List<PreferenceEntry>> load() async => [
    const PreferenceEntry('existing', 'old', .string),
  ];
  @override
  Future<void> save(PreferenceEntry? previous, PreferenceEntry next) =>
      saved.future;
}

void main() {
  testWidgets(
    'returning from request details preserves search and method filters',
    (tester) async {
      final collector = ManaDioCollector();
      for (final method in ['GET', 'POST']) {
        collector.addResponse(
          Response<dynamic>(
            requestOptions: RequestOptions(path: '/$method', method: method),
            statusCode: 200,
          ),
        );
      }
      await tester.pumpWidget(
        testHost(DioInspectorContent(collector: collector)),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(KitTabs<String?>),
          matching: find.text('POST'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(button('Search'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'POST');
      await tester.pumpAndSettle();
      final field = tester.widget<EditableText>(find.byType(EditableText));
      await tester.tap(find.byType(ResponseTile));
      await tester.pumpAndSettle();
      expect(field.focusNode.hasFocus, isFalse);
      await tester.tap(button('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'POST',
      );
      expect(
        tester.widget<KitTabs<String?>>(find.byType(KitTabs<String?>)).value,
        'POST',
      );
      expect(find.byType(ResponseTile), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      collector.dispose();
    },
  );

  testWidgets('hidden log feeds defer formatting until visible again', (
    tester,
  ) async {
    final logs = ManaLogCollector();
    var visible = true;
    late StateSetter rebuild;
    await tester.pumpWidget(
      testHost(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return TickerMode(
              enabled: visible,
              child: LogViewerContent(collector: logs, verboseLogs: false),
            );
          },
        ),
      ),
    );
    rebuild(() => visible = false);
    await tester.pumpAndSettle();
    logs.output(OutputEvent(LogEvent(Level.info, 'While hidden'), []));
    await tester.pumpAndSettle();
    expect(find.text('While hidden'), findsNothing);
    rebuild(() => visible = true);
    await tester.pumpAndSettle();
    expect(find.text('While hidden'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    logs.dispose();
  });
  testWidgets(
    'screen diagnostics retain host insets before window keyboard avoidance',
    (tester) async {
      final runtime = ManaController(
        plugins: [ManaScreenInfo()],
        preferences: MemoryManaPreferences(),
      );
      await tester.pumpWidget(
        testHost(
          ManaWidget.builder(
            controller: runtime,
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await runtime.activatePlugin('mana_screen_info');
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final content = tester.widget<ScreenInfoContent>(
        find.byType(ScreenInfoContent),
      );
      expect(
        content.data.viewInsets.bottom,
        240 / tester.view.devicePixelRatio,
      );
      expect(
        content.data.size.height,
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      );
      tester.view.resetViewInsets();
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    },
  );

  testWidgets('logs produced during a sibling build update the feed safely', (
    tester,
  ) async {
    final logs = ManaLogCollector();
    late StateSetter rebuild;
    var messages = 0;
    await tester.pumpWidget(
      testHost(
        Row(
          children: [
            Expanded(
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  logs.output(
                    OutputEvent(
                      LogEvent(Level.info, 'Message ${++messages}'),
                      [],
                    ),
                  );
                  return const SizedBox();
                },
              ),
            ),
            Expanded(
              child: LogViewerContent(collector: logs, verboseLogs: false),
            ),
          ],
        ),
      ),
    );
    rebuild(() {});
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Message 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    logs.dispose();
  });

  testWidgets('a cancelled save cannot close a later preference editor', (
    tester,
  ) async {
    final repository = _PendingPreferences();
    await tester.pumpWidget(
      testHost(SharedPreferencesViewerContent(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('existing'));
    await tester.pumpAndSettle();
    await tester.tap(button('Save'));
    await tester.pump();
    await tester.tap(button('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(button('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'new key');
    repository.saved.complete();
    await tester.pumpAndSettle();
    expect(find.byType(PreferenceEditor), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      'new key',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'a second failed retry is observed without an unhandled Future error',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        testHost(
          KitAsync<String>(
            load: () async {
              if (attempts++ < 2) throw StateError('offline');
              return 'ready';
            },
            builder: (_, value) => Text(value),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(button('Retry'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
      await tester.tap(button('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('ready'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'keyboard resize preserves query text and focus instead of recreating the feed',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final runtime = ManaController(
        plugins: [ManaDioInspector()],
        preferences: MemoryManaPreferences(),
      );
      await tester.pumpWidget(
        testHost(
          ManaWidget.builder(controller: runtime, child: const Text('Host')),
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
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      final after = tester.widget<EditableText>(find.byType(EditableText));
      expect(after.controller, same(before.controller));
      expect(after.controller.text, 'keep query');
      expect(after.focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    },
  );

  testWidgets(
    'two embedded log viewers retain independent collectors and sessions',
    (tester) async {
      final a = ManaLogCollector()
        ..output(OutputEvent(LogEvent(Level.info, 'First only'), []));
      final b = ManaLogCollector()
        ..output(OutputEvent(LogEvent(Level.info, 'Second only'), []));
      final first = ManaController(
        plugins: [ManaLogViewer(collector: a)],
        preferences: MemoryManaPreferences(),
      );
      final second = ManaController(
        plugins: [ManaLogViewer(collector: b)],
        preferences: MemoryManaPreferences(),
      );
      await tester.pumpWidget(
        testHost(
          Row(
            children: [
              Expanded(
                child: ManaWidget.builder(
                  controller: first,
                  child: const SizedBox.expand(),
                ),
              ),
              Expanded(
                child: ManaWidget.builder(
                  controller: second,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await first.activatePlugin('mana_log_viewer');
      await second.activatePlugin('mana_log_viewer');
      await tester.pumpAndSettle();
      expect(find.text('First only'), findsOneWidget);
      expect(find.text('Second only'), findsOneWidget);
      a.clear();
      await tester.pumpAndSettle();
      expect(find.text('First only'), findsNothing);
      expect(find.text('Second only'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await first.close();
      await second.close();
      a.dispose();
      b.dispose();
    },
  );

  testWidgets('clearing preferences is confirmed and can be cancelled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'kept': 'value'});
    await tester.pumpWidget(testHost(const SharedPreferencesViewerContent()));
    await tester.pumpAndSettle();
    await tester.tap(button('Clear'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('kept'), 'value');
    await tester.tap(button('Cancel'));
    await tester.pumpAndSettle();
    expect(prefs.getString('kept'), 'value');
    await tester.tap(button('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(button('Clear all preferences'));
    await tester.pumpAndSettle();
    expect(prefs.getKeys(), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('kit labels follow live locale changes and RTL', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final runtime = ManaController(
      plugins: [ManaGrid()],
      preferences: MemoryManaPreferences(),
    );
    await tester.pumpWidget(
      ManaWidget(controller: runtime, child: const Text('Host')),
    );
    await tester.pumpAndSettle();
    await runtime.activatePlugin('mana_grid');
    await tester.pumpAndSettle();
    expect(find.text('Show Numbers'), findsOneWidget);
    tester.platformDispatcher.localesTestValue = [const Locale('zh')];
    await tester.pumpAndSettle();
    expect(find.text('显示坐标'), findsOneWidget);
    tester.platformDispatcher.localesTestValue = [const Locale('ar')];
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(KitToggle))),
      TextDirection.rtl,
    );
    await tester.pumpWidget(const SizedBox());
    await runtime.close();
  });
}
