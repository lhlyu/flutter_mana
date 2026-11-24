import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:flutter_mana_kits/src/plugins/mana_widget_info_inspector/inspector_snapshot.dart';
import 'package:flutter_mana_kits/src/plugins/mana_widget_info_inspector/widgets/widget_info_inspector.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/host.dart';

Finder button(String label) => find.byWidgetPredicate(
  (widget) => widget is KitButton && widget.label == label,
);
Finder get settings => find.byWidgetPredicate(
  (widget) => widget is ManaButton && widget.tooltip == 'Settings',
);
Finder get panel => find.descendant(
  of: find.byType(KitWindow),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).boxShadow?.isNotEmpty == true,
  ),
);
Finder get hitButton => find.byWidgetPredicate(
  (widget) => widget is KitButton && widget.label.startsWith('Hit widgets '),
);

Future<void> tapButton(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final rect = tester.getRect(finder);
  final view = tester.getRect(find.byType(WidgetInfoInspector));
  final visible = rect.intersect(view);
  await tester.tapAt(visible.isEmpty ? rect.center : visible.center);
  await tester.pumpAndSettle();
}

class BrokenDiagnostics extends StatelessWidget {
  const BrokenDiagnostics({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(width: 50, height: 20);
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    throw StateError('diagnostics unavailable');
  }
}

class TestPreferences extends MemoryManaPreferences {
  TestPreferences(super.values);
  bool fail = false;
  @override
  Future<void> write(String key, Object? value) async {
    if (fail) throw StateError('storage unavailable');
    await super.write(key, value);
  }
}

Future<ManaController> openInspector(
  WidgetTester tester, {
  Widget? child,
  MemoryManaPreferences? preferences,
  Size size = const Size(390, 800),
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final runtime = ManaController(
    plugins: [ManaWidgetInfoInspector()],
    preferences: preferences ?? MemoryManaPreferences(),
  );
  await tester.pumpWidget(
    testHost(
      Builder(
        builder: (context) => Localizations.override(
          context: context,
          locale: locale,
          child: ManaWidget.builder(
            controller: runtime,
            child: child ?? const SizedBox.expand(),
          ),
        ),
      ),
      scale: scale,
      direction: direction,
    ),
  );
  await tester.pumpAndSettle();
  await runtime.activatePlugin('mana_widget_info_inspector');
  await tester.pumpAndSettle();
  return runtime;
}

Widget target({VoidCallback? onTap, Widget? child}) => Stack(
  children: [
    Positioned(
      left: 20,
      top: 40,
      width: 140,
      height: 80,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          key: const ValueKey('inspector-target'),
          padding: const EdgeInsets.all(8),
          color: const Color(0xFF2864A0),
          child: child ?? const Text('Inspect me'),
        ),
      ),
    ),
  ],
);

Future<void> closeInspector(WidgetTester tester, ManaController runtime) async {
  await tester.pumpWidget(const SizedBox());
  await runtime.close();
  await tester.pump();
}

void main() {
  testWidgets(
    'pick and interact modes preserve selection and pass app gestures',
    (tester) async {
      var taps = 0;
      var drags = 0;
      final runtime = await openInspector(
        tester,
        child: GestureDetector(
          onVerticalDragUpdate: (_) => drags++,
          child: target(onTap: () => taps++),
        ),
      );
      expect(tester.getBottomLeft(panel).dy, 800);
      await tester.tapAt(const Offset(30, 50));
      await tester.pumpAndSettle();
      expect(taps, 0);
      expect(find.textContaining('Container').first, findsOneWidget);
      expect(hitButton, findsOneWidget);
      await tapButton(tester, button('Interact with app'));
      await tester.tapAt(const Offset(30, 50));
      await tester.dragFrom(const Offset(80, 100), const Offset(0, 100));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(drags, greaterThan(0));
      final selectedName = tester
          .widget<Text>(find.byKey(const ValueKey('inspector-selection-label')))
          .data;
      runtime.toggleFullscreen();
      await tester.pumpAndSettle();
      await tapButton(tester, button('Collapse inspector'));
      expect(runtime.state.windowMode, ManaWindowMode.normal);
      final collapsedHeight = tester.getSize(panel).height;
      expect(collapsedHeight, lessThan(200));
      expect(tester.getBottomLeft(panel).dy, 800);
      expect(button('Pick widget'), findsOneWidget);
      expect(find.text(selectedName!), findsOneWidget);
      tester.view.physicalSize = const Size(390, 900);
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(panel).dy, 900);
      await tapButton(tester, button('Expand inspector'));
      expect(tester.getSize(panel).height, greaterThan(collapsedHeight));
      await tapButton(tester, button('Pick widget'));
      await tester.tapAt(const Offset(30, 50));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
      await closeInspector(tester, runtime);
    },
  );

  for (final (size, scale, locale) in [
    (const Size(390, 800), 1.0, const Locale('en')),
    (const Size(360, 640), 1.15, const Locale('zh')),
  ]) {
    testWidgets('detail drags never move the header at $size / $locale', (
      tester,
    ) async {
      final runtime = await openInspector(
        tester,
        child: target(),
        size: size,
        scale: scale,
        locale: locale,
      );
      expect(tester.getSize(panel).height, closeTo(size.height * .78, .1));
      await tester.tapAt(const Offset(30, 50));
      await tester.pumpAndSettle();
      final chinese = locale.languageCode == 'zh';
      final controls = [
        button(chinese ? '点选组件' : 'Pick widget'),
        button(chinese ? '操作应用' : 'Interact with app'),
        button(chinese ? '选择父级' : 'Select parent'),
        find.text(chinese ? '布局' : 'Layout'),
        find.text(chinese ? '属性' : 'Properties'),
        find.text(chinese ? '原始诊断' : 'Raw diagnostics'),
      ];
      for (final control in controls) {
        expect(control.hitTestable(), findsOneWidget);
      }
      final viewport = find.byKey(const ValueKey('inspector-scroll'));
      final vertical = find.descendant(
        of: viewport,
        matching: find.byWidgetPredicate(
          (widget) => widget is Scrollable && widget.axis == Axis.vertical,
        ),
      );
      expect(vertical, findsOneWidget);
      final bounds = tester.getRect(
        find.byKey(const ValueKey('inspector-controls')),
      );
      expect(bounds.bottom, lessThan(tester.getBottomLeft(panel).dy - 180));
      await tester.tap(find.text(chinese ? '原始诊断' : 'Raw diagnostics'));
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(vertical);
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      final header = find.byKey(const ValueKey('inspector-header-scroll'));
      final headerPosition = tester
          .state<ScrollableState>(
            find.descendant(
              of: header,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Scrollable && widget.axis == Axis.vertical,
              ),
            ),
          )
          .position;
      expect(headerPosition.maxScrollExtent, 0);
      final headerOffset = headerPosition.pixels;
      final detailRect = tester.getRect(viewport);
      await tester.dragFrom(detailRect.center, const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, greaterThan(0));
      for (var i = 0; i < 3; i++) {
        await tester.dragFrom(detailRect.center, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      await tester.dragFrom(detailRect.center, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(headerPosition.pixels, headerOffset);
      expect(
        tester.getRect(find.byKey(const ValueKey('inspector-controls'))),
        bounds,
      );
      for (final control in controls.take(3)) {
        expect(control.hitTestable(), findsOneWidget);
      }
      expect(
        find.text(chinese ? '原始诊断' : 'Raw diagnostics').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await closeInspector(tester, runtime);
    });
  }

  for (final (size, scale) in [
    (const Size(180, 240), 3.0),
    (const Size(360, 640), 1.5),
  ]) {
    testWidgets(
      'overflowing header scrolls independently from details at $size / $scale',
      (tester) async {
        final runtime = await openInspector(
          tester,
          child: target(),
          size: size,
          scale: scale,
          direction: TextDirection.rtl,
        );
        runtime.minimizeWindow();
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(30, 50));
        await tester.pumpAndSettle();
        runtime.restoreWindow();
        await tester.pumpAndSettle();
        final header = find.byKey(const ValueKey('inspector-header-scroll'));
        final details = find.byKey(const ValueKey('inspector-scroll'));
        Finder vertical(Finder parent) => find.descendant(
          of: parent,
          matching: find.byWidgetPredicate(
            (widget) => widget is Scrollable && widget.axis == Axis.vertical,
          ),
        );
        final headerPosition = tester
            .state<ScrollableState>(vertical(header))
            .position;
        final detailPosition = tester
            .state<ScrollableState>(vertical(details))
            .position;
        expect(headerPosition.maxScrollExtent, greaterThan(0));
        await tester.ensureVisible(find.text('Properties'));
        await tester.pumpAndSettle();
        // Reveal the controls using only their own scroll surface.
        headerPosition.jumpTo(headerPosition.maxScrollExtent);
        await tester.pumpAndSettle();
        final offset = headerPosition.pixels;
        final bounds = tester.getRect(
          find.byKey(const ValueKey('inspector-controls')),
        );
        final detailsRect = tester.getRect(details);
        await tester.dragFrom(detailsRect.center, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(detailPosition.pixels, greaterThan(0));
        await tester.dragFrom(detailsRect.center, const Offset(0, 2000));
        await tester.pumpAndSettle();
        expect(headerPosition.pixels, offset);
        expect(
          tester.getRect(find.byKey(const ValueKey('inspector-controls'))),
          bounds,
        );
        final detailOffset = detailPosition.pixels;
        await tester.dragFrom(
          tester.getRect(header).center,
          const Offset(0, 1000),
        );
        await tester.pumpAndSettle();
        expect(headerPosition.pixels, lessThan(offset));
        expect(detailPosition.pixels, detailOffset);
        expect(tester.takeException(), isNull);
        await closeInspector(tester, runtime);
      },
    );
  }

  testWidgets(
    'candidates and parents stay inside the host and details copy correctly',
    (tester) async {
      final runtime = await openInspector(tester, child: target());
      await tester.tapAt(const Offset(30, 50));
      await tester.pumpAndSettle();
      await tapButton(tester, hitButton);
      final candidates = find.descendant(
        of: find.byKey(const ValueKey('inspector-candidates')),
        matching: find.byType(KitButton),
      );
      expect(candidates.evaluate().length, greaterThan(1));
      expect(find.textContaining('ManaScope'), findsNothing);
      expect(find.textContaining('WidgetsApp'), findsNothing);
      await tapButton(tester, candidates.first);
      await tapButton(tester, button('Select parent'));
      await tapButton(tester, hitButton);
      final selected = tester
          .widgetList<KitButton>(candidates)
          .where((item) => item.selected);
      expect(selected, hasLength(1));
      await tapButton(tester, candidates.first);
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tapButton(tester, button('Copy'));
      expect(clipboard, contains('Size:'));
      expect(clipboard, contains('Constraints:'));
      await tapButton(tester, find.text('Properties'));
      expect(find.byType(EditableText), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '[');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapButton(tester, find.text('Raw diagnostics'));
      await tapButton(tester, button('Copy').last);
      expect(clipboard, contains('RenderObject'));
      await closeInspector(tester, runtime);
    },
  );

  testWidgets(
    'selection geometry updates and removed widgets are reported safely',
    (tester) async {
      late StateSetter rebuild;
      var width = 100.0;
      var shown = true;
      final runtime = await openInspector(
        tester,
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Stack(
              children: [
                if (shown)
                  Positioned(
                    left: 20,
                    top: 40,
                    width: width,
                    height: 60,
                    child: const ColoredBox(
                      key: ValueKey('dynamic-target'),
                      color: Color(0xFF2864A0),
                    ),
                  ),
              ],
            );
          },
        ),
      );
      await tester.tapAt(const Offset(30, 50));
      await tester.pumpAndSettle();
      expect(find.text('100 × 60'), findsOneWidget);
      rebuild(() => width = 150);
      await tester.pumpAndSettle();
      expect(find.text('150 × 60'), findsOneWidget);
      rebuild(() => shown = false);
      await tester.pumpAndSettle();
      expect(find.textContaining('has left the page'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await closeInspector(tester, runtime);
    },
  );

  testWidgets(
    'display settings persist and layout flags are restored on close',
    (tester) async {
      final originalLayout = debugPaintSizeEnabled;
      final preferences = TestPreferences({});
      final runtime = await openInspector(
        tester,
        child: target(),
        preferences: preferences,
      );
      await tester.tap(settings);
      await tester.pumpAndSettle();
      await tapButton(tester, find.text('Show selected widget size'));
      await tapButton(tester, find.text('Show framework widgets'));
      await tapButton(tester, find.text('Layout Bounds'));
      expect(debugPaintSizeEnabled, !originalLayout);
      expect(preferences.read('mana_inspector_show_size'), isFalse);
      expect(preferences.read('mana_inspector_show_framework'), isTrue);
      preferences.fail = true;
      await tapButton(tester, find.text('Show selected widget size'));
      expect(find.textContaining('storage unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await closeInspector(tester, runtime);
      expect(debugPaintSizeEnabled, originalLayout);
    },
  );

  testWidgets(
    'framework filtering updates candidates and persisted settings reopen',
    (tester) async {
      final preferences = MemoryManaPreferences();
      final runtime = await openInspector(
        tester,
        child: target(),
        preferences: preferences,
      );
      await tester.tapAt(const Offset(30, 50));
      await tester.pumpAndSettle();
      await tapButton(tester, hitButton);
      final candidates = find.descendant(
        of: find.byKey(const ValueKey('inspector-candidates')),
        matching: find.byType(KitButton),
      );
      final count = candidates.evaluate().length;
      await tester.tap(settings);
      await tester.pumpAndSettle();
      await tapButton(tester, find.text('Show framework widgets'));
      await tapButton(tester, find.text('Show selected widget size'));
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(candidates.evaluate().length, greaterThanOrEqualTo(count));
      expect(find.textContaining('ManaScope'), findsNothing);
      await runtime.closePlugin();
      await tester.pumpAndSettle();
      await runtime.activatePlugin('mana_widget_info_inspector');
      await tester.pumpAndSettle();
      await tester.tap(settings);
      await tester.pumpAndSettle();
      final toggles = tester.widgetList<KitToggle>(find.byType(KitToggle));
      expect(
        toggles
            .singleWhere(
              (toggle) => toggle.label == 'Show selected widget size',
            )
            .value,
        isFalse,
      );
      expect(
        toggles
            .singleWhere((toggle) => toggle.label == 'Show framework widgets')
            .value,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await closeInspector(tester, runtime);
    },
  );

  testWidgets(
    'snapshots expose layout and diagnostic properties independently',
    (tester) async {
      final root = GlobalKey();
      final targetKey = GlobalKey();
      await tester.pumpWidget(
        testHost(
          RepaintBoundary(
            key: root,
            child: Center(
              child: SizedBox(key: targetKey, width: 120, height: 30),
            ),
          ),
        ),
      );
      final element = targetKey.currentContext! as Element;
      final renderRoot = root.currentContext!.findRenderObject()!;
      final snapshot = InspectorSnapshot.capture(element, renderRoot);
      expect(snapshot.geometry?.size, const Size(120, 30));
      expect(
        snapshot.properties.map((property) => property.name),
        contains('width'),
      );
      expect(
        snapshot.properties.map((property) => property.value),
        contains('120.0'),
      );
      expect(snapshot.diagnostics, contains('RenderObject'));
      expect(snapshot.diagnosticsError, isNull);
      await tester.pumpWidget(const SizedBox());
      expect(snapshot.geometry?.size, const Size(120, 30));
    },
  );

  testWidgets('application diagnostic errors preserve the layout snapshot', (
    tester,
  ) async {
    final root = GlobalKey();
    final targetKey = GlobalKey();
    await tester.pumpWidget(
      testHost(
        RepaintBoundary(
          key: root,
          child: Center(child: BrokenDiagnostics(key: targetKey)),
        ),
      ),
    );
    final snapshot = InspectorSnapshot.capture(
      targetKey.currentContext! as Element,
      root.currentContext!.findRenderObject()!,
    );
    expect(snapshot.diagnosticsError, contains('diagnostics unavailable'));
    expect(snapshot.geometry?.size, const Size(50, 20));
    expect(snapshot.diagnostics, contains('RenderObject'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('desktop panel drags and resizing retains the selection', (
    tester,
  ) async {
    final runtime = await openInspector(
      tester,
      child: target(),
      size: const Size(1024, 768),
    );
    runtime.minimizeWindow();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(30, 50));
    await tester.pumpAndSettle();
    runtime.restoreWindow();
    await tester.pumpAndSettle();
    final name = tester
        .widget<Text>(find.byKey(const ValueKey('inspector-selection-label')))
        .data;
    final before = tester.getTopLeft(panel);
    await tester.dragFrom(
      Offset(tester.getCenter(panel).dx, before.dy + 20),
      const Offset(45, 30),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(panel).dx, greaterThan(before.dx));
    tester.view.physicalSize = const Size(390, 800);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('inspector-selection-label')))
          .data,
      name,
    );
    expect(tester.getBottomLeft(panel).dy, 800);
    expect(tester.takeException(), isNull);
    await closeInspector(tester, runtime);
  });

  for (final (size, scale, direction) in [
    (const Size(180, 240), 3.0, TextDirection.rtl),
    (const Size(1024, 768), 1.0, TextDirection.ltr),
  ]) {
    testWidgets('selected inspector fits $size at text scale $scale', (
      tester,
    ) async {
      final runtime = await openInspector(
        tester,
        size: size,
        scale: scale,
        direction: direction,
        child: target(),
      );
      runtime.minimizeWindow();
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(30, 50));
      await tester.pumpAndSettle();
      runtime.restoreWindow();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final tab in ['Layout', 'Properties', 'Raw diagnostics']) {
        await tapButton(tester, find.text(tab));
        expect(tester.takeException(), isNull);
      }
      await tester.tap(settings);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Show framework widgets'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await closeInspector(tester, runtime);
    });
  }
}
