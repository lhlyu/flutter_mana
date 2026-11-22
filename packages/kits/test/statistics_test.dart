import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:flutter_mana_kits/src/data/bounded_collector.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/preference_entry.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/preferences_repository.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/widgets/shared_preferences_viewer_content.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/host.dart';

Finder button(String label) => find.byWidgetPredicate(
  (widget) => widget is KitButton && widget.label == label,
);

Finder get settingsButton => find.byWidgetPredicate(
  (widget) => widget is ManaButton && widget.tooltip == 'Settings',
);

KitDataStatistics statistics(WidgetTester tester) =>
    tester.widget<KitDataStatistics>(find.byType(KitDataStatistics));

Future<ManaController> openKit(
  WidgetTester tester,
  ManaPluggable plugin,
) async {
  final runtime = ManaController(
    plugins: [plugin],
    preferences: MemoryManaPreferences(),
  );
  await tester.pumpWidget(
    testHost(
      ManaWidget.builder(controller: runtime, child: const Text('Host')),
    ),
  );
  await tester.pumpAndSettle();
  await runtime.activatePlugin(plugin.name);
  await tester.pumpAndSettle();
  return runtime;
}

class ObservedErrorHandler extends ErrorInterceptorHandler {
  ObservedErrorHandler() {
    future.then<void>((_) {}, onError: (Object _, StackTrace _) {});
  }
}

class PendingPreferences extends PreferencesRepository {
  final result = Completer<List<PreferenceEntry>>();

  @override
  Future<List<PreferenceEntry>> load() => result.future;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final network in [true, false]) {
    testWidgets(
      '${network ? 'network' : 'log'} settings count retained records regardless of filters',
      (tester) async {
        final BoundedCollector<dynamic> collector;
        final ManaPluggable plugin;
        late void Function(int, {bool large}) capture;
        if (network) {
          final requests = ManaDioCollector(
            capacity: 3,
            maxBytes: 1536,
            maxEntryBytes: 1024,
          );
          collector = requests;
          plugin = ManaDioInspector(collector: requests);
          capture = (index, {large = false}) {
            final options = RequestOptions(
              path: '/request/$index',
              method: index.isEven ? 'GET' : 'POST',
            );
            if (index == 1) {
              final handler = ObservedErrorHandler();
              requests.onError(
                DioException(requestOptions: options, message: 'offline'),
                handler,
              );
              expect(handler.isCompleted, isTrue);
            } else {
              requests.addResponse(
                Response<dynamic>(
                  requestOptions: options,
                  data: large ? 'x' * 10000 : 'response',
                  statusCode: 200,
                ),
              );
            }
          };
        } else {
          final logs = ManaLogCollector(
            capacity: 3,
            maxBytes: 1536,
            maxEntryBytes: 1024,
          );
          collector = logs;
          plugin = ManaLogViewer(collector: logs);
          capture = (index, {large = false}) => logs.output(
            OutputEvent(
              LogEvent(
                index.isEven ? Level.info : Level.error,
                large ? 'x' * 10000 : 'message $index',
              ),
              ['line one', 'line two'],
            ),
          );
        }
        capture(0);
        capture(1);
        final runtime = await openKit(tester, plugin);
        await tester.tap(
          find.descendant(
            of: find.byType(KitTabs<String?>),
            matching: find.text(network ? 'GET' : 'INFO'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(button('Search'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'no results');
        await tester.pumpAndSettle();
        expect(find.text('No items'), findsOneWidget);
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
        expect(find.text('Data statistics'), findsOneWidget);
        expect(
          find.text(network ? 'Total requests' : 'Total logs'),
          findsOneWidget,
        );
        expect(statistics(tester).count, 2);
        expect(statistics(tester).capacity, 3);
        expect(statistics(tester).maxBytes, 1536);
        expect(find.textContaining('/ 1.5 KiB'), findsOneWidget);
        expect(statistics(tester).retainedBytes, collector.retainedBytes);
        if (!network) {
          expect(find.text('Verbose Logs'), findsOneWidget);
          await tester.tap(find.text('Verbose Logs'));
          await tester.pumpAndSettle();
          expect(
            runtime.preferences.read('mana_log_viewer_verbose_logs'),
            isTrue,
          );
        }
        capture(2);
        await tester.pumpAndSettle();
        expect(statistics(tester).count, 3);
        capture(3);
        await tester.pumpAndSettle();
        expect(statistics(tester).count, 3);
        capture(4, large: true);
        capture(6, large: true);
        await tester.pumpAndSettle();
        expect(collector.length, 1);
        expect(statistics(tester).count, 1);
        expect(statistics(tester).retainedBytes, collector.retainedBytes);
        collector.clear();
        await tester.pumpAndSettle();
        expect(statistics(tester).count, 0);
        expect(find.text('Approx. 0 B / 1.5 KiB'), findsOneWidget);
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          'no results',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await runtime.close();
        collector.dispose();
      },
    );
  }

  testWidgets('preference settings follow edits, refresh, deletion and clear', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'first': 'a', 'second': 'b'});
    final runtime = await openKit(tester, ManaSharedPreferencesViewer());
    Future<void> expectCount(int count) async {
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
      expect(statistics(tester).count, count);
      expect(statistics(tester).capacity, isNull);
      expect(find.text('Total key-value pairs'), findsOneWidget);
      expect(find.text('Captured data size'), findsNothing);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
    }

    await tester.tap(button('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'first');
    await tester.pumpAndSettle();
    await expectCount(2);
    await tester.tap(button('Search'));
    await tester.pumpAndSettle();
    await tester.tap(button('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'third');
    await tester.enterText(find.byType(EditableText).last, 'c');
    await tester.ensureVisible(button('Save'));
    await tester.tap(button('Save'));
    await tester.pumpAndSettle();
    await expectCount(3);
    await tester.tap(find.text('third'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'renamed');
    await tester.ensureVisible(button('Save'));
    await tester.tap(button('Save'));
    await tester.pumpAndSettle();
    await expectCount(3);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('external', true);
    await tester.tap(button('Refresh'));
    await tester.pumpAndSettle();
    await expectCount(4);
    await tester.tap(button('Delete').first);
    await tester.pumpAndSettle();
    await expectCount(3);
    await tester.tap(button('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(button('Clear all preferences'));
    await tester.pumpAndSettle();
    await expectCount(0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await runtime.close();
  });

  testWidgets('preference statistics ignore late results from an old source', (
    tester,
  ) async {
    final first = PendingPreferences();
    final second = PendingPreferences();
    final snapshots = <AsyncSnapshot<int>>[];
    Widget host(PreferencesRepository repository) => testHost(
      SharedPreferencesViewerContent(
        repository: repository,
        onStatisticsChanged: snapshots.add,
      ),
    );
    await tester.pumpWidget(host(first));
    await tester.pumpAndSettle();
    expect(snapshots.last.connectionState, ConnectionState.waiting);
    await tester.pumpWidget(host(second));
    await tester.pumpAndSettle();
    second.result.complete([
      const PreferenceEntry('current', 'value', .string),
    ]);
    await tester.pumpAndSettle();
    expect(snapshots.last.requireData, 1);
    final reports = snapshots.length;
    first.result.complete([]);
    await tester.pumpAndSettle();
    expect(snapshots, hasLength(reports));
    expect(snapshots.last.requireData, 1);
    await tester.pumpWidget(host(PendingPreferences()));
    await tester.pumpAndSettle();
    expect(snapshots.last.hasData, isFalse);
    final failing = PendingPreferences();
    await tester.pumpWidget(host(failing));
    await tester.pumpAndSettle();
    failing.result.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(snapshots.last.hasError, isTrue);
    expect(snapshots.last.hasData, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statistics handle captures emitted by a sibling build', (
    tester,
  ) async {
    final collector = BoundedCollector<int>();
    late StateSetter rebuild;
    var value = 0;
    await tester.pumpWidget(
      testHost(
        Row(
          children: [
            Expanded(
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  collector.add(value++);
                  return const SizedBox();
                },
              ),
            ),
            Expanded(
              child: KitCollectorStatistics(
                collector: collector,
                countLabel: 'Total logs',
              ),
            ),
          ],
        ),
      ),
    );
    rebuild(() {});
    await tester.pumpAndSettle();
    expect(statistics(tester).count, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    collector.dispose();
  });

  testWidgets('statistics fit a short RTL panel with large Chinese text', (
    tester,
  ) async {
    await tester.pumpWidget(
      testHost(
        Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: const Locale('zh'),
            child: const Center(
              child: SizedBox(
                width: 180,
                height: 100,
                child: SingleChildScrollView(
                  child: KitDataStatistics(
                    countLabel: '请求总数',
                    count: 1000,
                    capacity: 1000,
                    retainedBytes: 8 * 1024 * 1024,
                    maxBytes: 8 * 1024 * 1024,
                  ),
                ),
              ),
            ),
          ),
        ),
        direction: .rtl,
        scale: 3,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('数据统计'), findsOneWidget);
    expect(find.text('条数上限'), findsOneWidget);
    expect(find.text('约 8 MiB / 8 MiB'), findsOneWidget);
    await tester.ensureVisible(find.text('约 8 MiB / 8 MiB'));
    await tester.pumpAndSettle();
    final visible = tester
        .getRect(find.text('约 8 MiB / 8 MiB'))
        .intersect(tester.getRect(find.byType(SingleChildScrollView)));
    expect(visible.isEmpty, isFalse);
    expect(tester.takeException(), isNull);
  });
}
