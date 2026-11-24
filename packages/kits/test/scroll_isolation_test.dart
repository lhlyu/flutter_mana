import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/widgets/dio_inspector_content.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/widgets/response_detail.dart';
import 'package:flutter_mana_kits/src/plugins/mana_license/widgets/license.dart';
import 'package:flutter_mana_kits/src/plugins/mana_log_viewer/widgets/log_viewer_content.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/widgets/shared_preferences_viewer_content.dart';
import 'package:flutter_mana_kits/src/plugins/mana_show_code/code/code_widget.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/host.dart';

Finder button(String label) => find.byWidgetPredicate(
  (widget) => widget is KitButton && widget.label == label,
);

Finder vertical(Finder parent) => find.descendant(
  of: parent,
  matching: find.byWidgetPredicate(
    (widget) => widget is Scrollable && widget.axis == Axis.vertical,
  ),
);

Future<void> dragDetails(WidgetTester tester, Finder details) async {
  final rect = tester.getRect(details);
  for (final delta in [
    const Offset(0, -250),
    const Offset(0, -2000),
    const Offset(0, -300),
    const Offset(0, 2000),
    const Offset(0, 300),
  ]) {
    await tester.dragFrom(rect.center, delta);
    await tester.pumpAndSettle();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      for (var index = 0; index < 80; index++) 'key_$index': 'value_$index',
    });
  });

  for (final kind in ['network', 'logs', 'preferences', 'source', 'license']) {
    testWidgets(
      '$kind panel isolates header, footer, body and host scrolling',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final outer = ScrollController();
        final hostKey = GlobalKey();
        final dio = ManaDioCollector();
        final logs = ManaLogCollector();
        for (var index = 0; index < 80; index++) {
          dio.addResponse(
            Response<dynamic>(
              requestOptions: RequestOptions(path: '/request/$index'),
              data: 'response $index',
              statusCode: 200,
            ),
          );
          logs.output(OutputEvent(LogEvent(Level.info, 'message $index'), []));
        }
        if (kind == 'license') {
          LicenseRegistry.reset();
          LicenseRegistry.addLicense(() async* {
            for (var index = 0; index < 80; index++) {
              yield LicenseEntryWithLineBreaks([
                'package_$index',
              ], 'License text');
            }
          });
          addTearDown(LicenseRegistry.reset);
        }
        final plugin = ManaLicense();
        final runtime = ManaController(
          plugins: [plugin],
          preferences: MemoryManaPreferences(),
        );
        Widget content = switch (kind) {
          'network' => DioInspectorContent(collector: dio),
          'logs' => LogViewerContent(collector: logs, verboseLogs: false),
          'preferences' => const SharedPreferencesViewerContent(),
          'source' => KitScaffold(
            header: const Text('Source header'),
            body: CodeWidget(
              code: List.generate(
                100,
                (index) => 'final value$index = $index;',
              ).join('\n'),
            ),
          ),
          _ => License(name: plugin.name),
        };
        await tester.pumpWidget(
          testHost(
            PrimaryScrollController(
              controller: outer,
              child: Stack(
                children: [
                  ListView.builder(
                    key: hostKey,
                    primary: true,
                    itemCount: 100,
                    itemBuilder: (_, index) =>
                        SizedBox(height: 50, child: Text('host $index')),
                  ),
                  Center(
                    child: SizedBox(
                      width: 360,
                      height: 440,
                      child: kind == 'license'
                          ? ManaWidget.builder(
                              controller: runtime,
                              child: const SizedBox(),
                            )
                          : content,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (kind == 'license') {
          await runtime.activatePlugin(plugin.name);
          await tester.pumpAndSettle();
        }
        expect(outer.positions, hasLength(1));
        if (kind == 'network' || kind == 'logs' || kind == 'preferences') {
          await tester.tap(button('Search'));
          await tester.pumpAndSettle();
        }
        final scaffold = find.byType(KitScaffold).first;
        Finder region(String key) => find
            .descendant(of: scaffold, matching: find.byKey(ValueKey(key)))
            .first;
        final body = region('kit-body');
        final header = region('kit-header');
        final headerBounds = tester.getRect(header);
        final footer = find.descendant(
          of: scaffold,
          matching: find.byKey(const ValueKey('kit-footer')),
        );
        final footerBounds = footer.evaluate().isEmpty
            ? null
            : tester.getRect(footer.first);
        final headerPosition = tester
            .state<ScrollableState>(vertical(header).first)
            .position;
        final headerOffset = headerPosition.pixels;
        final details = vertical(body).first;
        final detailsPosition = tester.state<ScrollableState>(details).position;
        expect(detailsPosition.maxScrollExtent, greaterThan(0));
        await tester.dragFrom(
          tester.getRect(body).center,
          const Offset(0, -180),
        );
        await tester.pumpAndSettle();
        expect(detailsPosition.pixels, greaterThan(0));
        await dragDetails(tester, body);
        expect(outer.offset, 0);
        expect(headerPosition.pixels, headerOffset);
        expect(tester.getRect(header), headerBounds);
        if (footerBounds != null) {
          expect(tester.getRect(footer.first), footerBounds);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await runtime.close();
        outer.dispose();
        dio.dispose();
        logs.dispose();
      },
    );
  }

  testWidgets(
    'short scaffold regions never attach to the same primary controller',
    (tester) async {
      final outer = ScrollController();
      await tester.pumpWidget(
        testHost(
          PrimaryScrollController(
            controller: outer,
            child: Center(
              child: SizedBox(
                width: 220,
                height: 120,
                child: KitScaffold(
                  header: Column(
                    children: List.generate(
                      8,
                      (i) => SizedBox(height: 30, child: Text('header $i')),
                    ),
                  ),
                  body: ListView.builder(
                    itemCount: 100,
                    itemBuilder: (_, i) =>
                        SizedBox(height: 30, child: Text('item $i')),
                  ),
                  footer: Column(
                    children: List.generate(
                      8,
                      (i) => SizedBox(height: 30, child: Text('footer $i')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      ScrollPosition position(String key) => tester
          .state<ScrollableState>(vertical(find.byKey(ValueKey(key))).first)
          .position;
      final header = position('kit-header');
      final body = position('kit-body');
      final footer = position('kit-footer');
      expect(outer.hasClients, isFalse);
      final headerRect = tester.getRect(
        find.byKey(const ValueKey('kit-header')),
      );
      await tester.dragFrom(headerRect.center, const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(header.pixels, greaterThan(0));
      final savedHeader = header.pixels;
      await dragDetails(tester, find.byKey(const ValueKey('kit-body')));
      expect(header.pixels, savedHeader);
      expect(footer.pixels, 0);
      expect(body, isNot(same(header)));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      outer.dispose();
    },
  );

  testWidgets('new log capture never interrupts an active manual drag', (
    tester,
  ) async {
    final logs = ManaLogCollector();
    for (var i = 0; i < 100; i++) {
      logs.output(OutputEvent(LogEvent(Level.info, 'message $i'), []));
    }
    await tester.pumpWidget(
      testHost(LogViewerContent(collector: logs, verboseLogs: false)),
    );
    await tester.pumpAndSettle();
    final list = find.byType(ListView);
    final position = tester.state<ScrollableState>(vertical(list)).position;
    final gesture = await tester.startGesture(tester.getCenter(list));
    await gesture.moveBy(const Offset(0, -90));
    await tester.pump();
    expect(position.isScrollingNotifier.value, isTrue);
    final before = position.pixels;
    logs.output(OutputEvent(LogEvent(Level.info, 'new record'), []));
    await tester.pump();
    await tester.pump();
    expect(position.pixels, before);
    expect(position.isScrollingNotifier.value, isTrue);
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    logs.dispose();
  });

  testWidgets(
    'opening settings dismisses request menus and preserves details',
    (tester) async {
      final collector = ManaDioCollector()
        ..addResponse(
          Response<dynamic>(
            requestOptions: RequestOptions(path: '/test'),
            data: 'response',
            statusCode: 200,
          ),
        );
      final plugin = ManaDioInspector(collector: collector);
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
      await tester.tap(find.textContaining('/test').first);
      await tester.pumpAndSettle();
      final more = find.byWidgetPredicate(
        (widget) => widget is ManaButton && widget.tooltip == 'More actions',
      );
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(button('Copy HTTP').hitTestable(), findsOneWidget);
      final settings = find.byWidgetPredicate(
        (widget) => widget is ManaButton && widget.tooltip == 'Settings',
      );
      // Accessibility activation has no outside pointer event to dismiss menus.
      tester.widget<ManaButton>(settings).onPressed!();
      await tester.pumpAndSettle();
      expect(button('Copy HTTP').hitTestable(), findsNothing);
      expect(button('Back').hitTestable(), findsNothing);
      tester.widget<ManaButton>(settings).onPressed!();
      await tester.pumpAndSettle();
      expect(button('Back').hitTestable(), findsOneWidget);
      expect(button('Copy HTTP').hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
      collector.dispose();
    },
  );

  testWidgets('response body drag leaves back and section tabs in place', (
    tester,
  ) async {
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/test'),
      data: List.generate(120, (i) => {'index': i}),
    );
    await tester.pumpWidget(
      testHost(
        Center(
          child: SizedBox(
            width: 360,
            height: 440,
            child: ResponseDetail(response: response, onClose: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Response'));
    await tester.pumpAndSettle();
    final body = find
        .ancestor(
          of: find.byType(KitCode),
          matching: find.byType(SingleChildScrollView),
        )
        .first;
    final before = tester.getRect(button('Back'));
    final tabs = tester.getRect(find.byType(KitTabs<int>));
    await dragDetails(tester, body);
    expect(tester.getRect(button('Back')), before);
    expect(tester.getRect(find.byType(KitTabs<int>)), tabs);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
