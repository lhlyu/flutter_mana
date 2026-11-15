import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:flutter_mana_kits/src/plugins/mana_align_ruler/widgets/align_ruler_barrier.dart';
import 'package:flutter_mana_kits/src/plugins/mana_color_sucker/widgets/screen_pixel_grabber.dart';
import 'package:flutter_mana_kits/src/plugins/mana_grid/widgets/grid_barrier.dart';
import 'package:flutter_mana_kits/src/plugins/mana_touch_indicator/widgets/touch_indicator_barrier.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/host.dart';

void main() {
  testWidgets(
    'pixel sampling accounts for embedded origin and pixel ratio, rejects outside points',
    (tester) async {
      final key = GlobalKey();
      const color = Color(0xFF336699);
      await tester.pumpWidget(
        testHost(
          Stack(
            children: [
              Positioned(
                left: 100,
                top: 80,
                width: 60,
                height: 60,
                child: RepaintBoundary(
                  key: key,
                  child: const ColoredBox(color: color),
                ),
              ),
            ],
          ),
        ),
      );
      final grabber = ScreenPixelGrabber(repaintBoundaryKey: key);
      await tester.runAsync(() => grabber.captureImage(pixelRatio: 2));
      expect(grabber.getColorAt(tester.getCenter(find.byKey(key))), color);
      expect(grabber.getColorAt(const Offset(50, 50)), isNull);
      grabber.dispose();
      expect(grabber.getColorAt(tester.getCenter(find.byKey(key))), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'touch overlay observes host events without stealing taps and uses local coordinates',
    (tester) async {
      final runtime = ManaController(
        plugins: [ManaTouchIndicator()],
        preferences: MemoryManaPreferences(),
      );
      var taps = 0;
      await tester.pumpWidget(
        testHost(
          Stack(
            children: [
              Positioned(
                left: 100,
                top: 80,
                width: 300,
                height: 250,
                child: ManaWidget.builder(
                  controller: runtime,
                  child: GestureDetector(
                    behavior: .opaque,
                    onTap: () => taps++,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await runtime.activatePlugin('mana_touch_indicator');
      await tester.pumpAndSettle();
      final point = tester.getCenter(find.byKey(runtime.rootKey));
      final gesture = await tester.startGesture(point);
      await tester.pump();
      final dot = find.descendant(
        of: find.byType(TouchIndicatorBarrier),
        matching: find.byType(Positioned),
      );
      expect(dot, findsOneWidget);
      expect(tester.getCenter(dot), point);
      await gesture.up();
      await tester.pump();
      expect(taps, 1);
      await tester.pump(const Duration(milliseconds: 201));
      expect(dot, findsNothing);
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    },
  );

  testWidgets('ruler snap coordinates remain local to an embedded host', (
    tester,
  ) async {
    final runtime = ManaController(
      plugins: [ManaAlignRuler()],
      preferences: MemoryManaPreferences(),
    );
    await tester.pumpWidget(
      testHost(
        Stack(
          children: [
            Positioned(
              left: 100,
              top: 80,
              width: 300,
              height: 250,
              child: ManaWidget.builder(
                controller: runtime,
                child: const Stack(
                  children: [
                    Positioned(
                      left: 50,
                      top: 50,
                      width: 100,
                      height: 100,
                      child: ColoredBox(color: Color(0xFF336699)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await runtime.activatePlugin('mana_align_ruler');
    await tester.pumpAndSettle();
    tester.widget<KitToggle>(find.byType(KitToggle)).onChanged!(true);
    runtime.minimizeWindow();
    await tester.pumpAndSettle();
    final circle = find.descendant(
      of: find.byType(AlignRulerBarrier),
      matching: find.byType(GestureDetector),
    );
    await tester.drag(circle, const Offset(-10, -5));
    await tester.pumpAndSettle();
    final position = tester
        .widget<AlignRulerBarrier>(find.byType(AlignRulerBarrier))
        .position;
    expect(position.dx, closeTo(150, 1));
    expect(position.dy, closeTo(120, 1));
    await tester.pumpWidget(const SizedBox());
    await runtime.close();
  });

  testWidgets(
    'widget inspector fills its host and selects behind the overlay',
    (tester) async {
      final runtime = ManaController(
        plugins: [ManaWidgetInfoInspector()],
        preferences: MemoryManaPreferences(),
      );
      var taps = 0;
      await tester.pumpWidget(
        testHost(
          ManaWidget.builder(
            controller: runtime,
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  top: 20,
                  width: 80,
                  height: 60,
                  child: GestureDetector(
                    onTap: () => taps++,
                    child: const ColoredBox(
                      key: Key('inspect-target'),
                      color: Color(0xFF336699),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await runtime.activatePlugin('mana_widget_info_inspector');
      await tester.pumpAndSettle();
      expect(find.text('Widget').hitTestable(), findsOneWidget);
      runtime.minimizeWindow();
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('inspect-target'))),
      );
      await tester.pumpAndSettle();
      expect(taps, 0, reason: 'The inspector must intercept taps on the host.');
      runtime.restoreWindow();
      await tester.pumpAndSettle();
      expect(find.textContaining('ColoredBox').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    },
  );

  for (final gap in [0.0, -1.0, double.nan, double.infinity]) {
    testWidgets('grid painting rejects unsafe spacing $gap', (tester) async {
      await tester.pumpWidget(
        testHost(GridBarrier(gap: gap, showNumbers: true)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'small embedded panels support RTL, large text and malformed grid preferences',
    (tester) async {
      tester.view.physicalSize = const Size(240, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final plugin in [
        ManaGrid(),
        ManaLogViewer(),
        ManaDioInspector(),
        ManaSharedPreferencesViewer(),
        ManaAlignRuler(),
        ManaScreenInfo(),
        ManaVisualHelper(),
      ]) {
        final runtime = ManaController(
          plugins: [plugin],
          preferences: MemoryManaPreferences({
            'mana_grid_gap': double.nan,
            'mana_grid_show_numbers': 'wrong',
          }),
        );
        await tester.pumpWidget(
          testHost(
            ManaWidget.builder(controller: runtime, child: const Text('Host')),
            direction: .rtl,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        await runtime.activatePlugin(plugin.name);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: plugin.name);
        await tester.pumpWidget(const SizedBox());
        await runtime.close();
      }
    },
  );

  testWidgets('keyboard resizes a bottom kit above the obscured region', (
    tester,
  ) async {
    final runtime = ManaController(
      plugins: [ManaDioInspector()],
      preferences: MemoryManaPreferences(),
    );
    await tester.pumpWidget(
      ManaWidget(controller: runtime, child: const Text('Host')),
    );
    await tester.pumpAndSettle();
    await runtime.activatePlugin('mana_dio_inspector');
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    final tabs = find.byType(KitTabs<String?>);
    expect(tester.getBottomLeft(tabs).dy, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await tester.pumpWidget(const SizedBox());
    await runtime.close();
  });
}
