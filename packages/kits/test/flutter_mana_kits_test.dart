import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/widgets/dio_inspector_content.dart';
import 'package:flutter_mana_kits/src/plugins/mana_log_viewer/widgets/log_viewer_content.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/widgets/preference_editor.dart';
import 'package:flutter_mana_kits/src/plugins/mana_widget_info_inspector/widgets/widget_info_inspector_detail.dart';
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
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Example',
      packageName: 'app.example',
      version: '1',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  for (final plugin in [
    ...loadAllPlugins(),
    Demo(),
  ].where((plugin) => plugin is! ManaShowCode && plugin is! ManaMemoryInfo)) {
    testWidgets(
      '${plugin.name} mounts, activates and closes in a Widgets-only host',
      (tester) async {
        final runtime = ManaController(
          plugins: [plugin],
          preferences: MemoryManaPreferences(),
        );
        try {
          await runtime.initializePlugins();
          await tester.pumpWidget(
            ManaWidget(
              controller: runtime,
              child: const Center(child: Text('Host')),
            ),
          );
          await tester.pumpAndSettle();
          if (plugin.isSupported) {
            expect(await runtime.activatePlugin(plugin.name), true);
            await tester.pumpAndSettle();
            expect(runtime.state.activePluginId, plugin.name);
            expect(tester.takeException(), isNull);
            await runtime.closePlugin();
            await tester.pumpAndSettle();
          }
        } finally {
          await tester.pumpWidget(const SizedBox());
          await runtime.close();
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('raw input supports keyboard editing and platform copy menus', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'hello');
    await tester.pumpWidget(
      testHost(KitField(controller: controller, label: 'Query')),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, isTrue);
    await tester.enterText(find.byType(EditableText), 'changed');
    expect(controller.text, 'changed');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 7);
    final state = tester.state<EditableTextState>(find.byType(EditableText));
    final shown = state.showToolbar();
    await tester.pumpAndSettle();
    if (kIsWeb && BrowserContextMenu.enabled) {
      expect(shown, isFalse); // The browser supplies its own clipboard menu.
    } else {
      expect(button('Copy'), findsOneWidget);
      await tester.tap(button('Copy'));
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('search hint is inside the input and only shown when empty', (
    tester,
  ) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      testHost(KitField(controller: controller, hintText: 'Search')),
    );
    final hint = find.text('Search');
    final input = find.byType(EditableText);
    expect(hint, findsOneWidget);
    expect(tester.getTopLeft(hint), tester.getTopLeft(input));

    await tester.tapAt(tester.getCenter(hint));
    await tester.pump();
    expect(tester.widget<EditableText>(input).focusNode.hasFocus, isTrue);
    await tester.enterText(input, 'query');
    await tester.pump();
    expect(hint, findsNothing);

    controller.clear();
    await tester.pump();
    expect(hint, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets(
    'pending saves run once, retain the editor on failure and allow retry',
    (tester) async {
      var calls = 0;
      final gate = Completer<void>();
      await tester.pumpWidget(
        testHost(
          PreferenceEditor(
            onClose: () {},
            onSave: (_) {
              calls++;
              return gate.future;
            },
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText).first, 'key');
      await tester.tap(button('Save'));
      await tester.pump();
      await tester.tap(find.text('Working…'));
      expect(calls, 1);
      gate.completeError(StateError('disk unavailable'));
      await tester.pumpAndSettle();
      expect(find.textContaining('disk unavailable'), findsOneWidget);
      expect(find.byType(PreferenceEditor), findsOneWidget);
      expect(
        tester
            .widget<ManaButton>(
              find.descendant(
                of: button('Save'),
                matching: find.byType(ManaButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'log filters are case insensitive and duplicate timestamps do not collide',
    (tester) async {
      final logs = ManaLogCollector();
      final time = DateTime(2026);
      for (final message in ['Alpha', 'Beta']) {
        logs.output(OutputEvent(LogEvent(Level.info, message, time: time), []));
      }
      await tester.pumpWidget(
        testHost(LogViewerContent(collector: logs, verboseLogs: false)),
      );
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      await tester.tap(button('Search'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'ALPHA');
      await tester.pumpAndSettle();
      expect(find.text('Beta'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      logs.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'network details stay within the panel and raw bodies are preserved',
    (tester) async {
      final collector = ManaDioCollector();
      collector.addResponse(
        Response<dynamic>(
          requestOptions: RequestOptions(
            path: 'https://example.test',
            method: 'PATCH',
          ),
          data: 'raw body',
          statusCode: 200,
        ),
      );
      await tester.pumpWidget(
        testHost(DioInspectorContent(collector: collector)),
      );
      await tester.tap(find.text('https://example.test'));
      await tester.pumpAndSettle();
      expect(find.byType(KitDetail), findsOneWidget);
      expect(find.byType(Navigator), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(KitTabs<int>),
          matching: find.text('Response'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('raw body'), findsOneWidget);
      await tester.tap(button('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(KitDetail), findsNothing);
      await tester.pumpWidget(const SizedBox());
      collector.dispose();
    },
  );

  testWidgets('async loads survive rebuilds, show errors and retry', (
    tester,
  ) async {
    var calls = 0;
    Future<String> load() async {
      if (calls++ == 0) throw StateError('offline');
      return 'ready';
    }

    Widget app() => testHost(
      KitAsync<String>(load: load, builder: (_, value) => Text(value)),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.textContaining('offline'), findsOneWidget);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.tap(button('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('ready'), findsOneWidget);
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('inspector search treats regex punctuation as plain text', (
    tester,
  ) async {
    late BuildContext target;
    await tester.pumpWidget(
      testHost(
        Builder(
          builder: (context) {
            target = context;
            return const Text('Target');
          },
        ),
      ),
    );
    final chain = (target as Element).debugGetDiagnosticChain();
    await tester.pumpWidget(
      testHost(InfoPage(elements: chain, onClose: () {})),
    );
    await tester.enterText(find.byType(EditableText), '[');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shared controls fit narrow RTL panels with large text', (
    tester,
  ) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      testHost(
        Center(
          child: SizedBox(
            width: 180,
            height: 550,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const KitToggle(label: 'A long wrapping label', value: true),
                  KitField(controller: controller, label: 'Search'),
                  KitToolbar(
                    children: [
                      KitButton(
                        label: 'Refresh',
                        icon: .refresh,
                        onPressed: () {},
                      ),
                      KitButton(
                        label: 'Filter',
                        icon: .filter,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const KitDataTable({
                    'a very long key': 'a very long value',
                    'b': 'value',
                  }),
                ],
              ),
            ),
          ),
        ),
        direction: .rtl,
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
