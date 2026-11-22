import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana/src/widgets/floating_button/index.dart';
import 'package:flutter_mana/src/widgets/floating_window/window_controls.dart';
import 'package:flutter_mana/src/widgets/mana_button.dart';
import 'package:flutter_mana/src/widgets/mana_icon.dart';
import 'package:flutter_mana/src/widgets/mana_overlay.dart';
import 'package:flutter_mana/src/widgets/mana_panel.dart';
import 'package:flutter_mana/src/widgets/mana_slider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/helpers.dart';

void main() {
  late ManaController runtime;
  setUp(() => runtime = ManaController(preferences: MemoryManaPreferences()));
  tearDown(() async {
    if (!runtime.isClosed) await runtime.close();
  });

  void testRuntimeWidgets(String description, WidgetTesterCallback body) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await runtime.close();
      }
    });
  }

  testRuntimeWidgets(
    'disabled entry leaves the child untouched and does not initialize',
    (tester) async {
      final plugin = TestPlugin();
      runtime.registerPlugin(plugin);
      const child = SizedBox(key: ValueKey('host'));
      await tester.pumpWidget(
        ManaWidget(controller: runtime, enable: false, child: child),
      );
      expect(find.byKey(const ValueKey('host')), findsOneWidget);
      expect(find.byType(WidgetsApp), findsNothing);
      expect(plugin.initializationCount, 0);
    },
  );

  testRuntimeWidgets(
    'entry initializes once across rebuilds and enable changes',
    (tester) async {
      final plugin = TestPlugin();
      runtime.registerPlugin(plugin);
      await tester.pumpWidget(
        ManaWidget(controller: runtime, child: Text('Host')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Host'), findsOneWidget);
      expect(find.byType(ManaOverlay), findsOneWidget);
      expect(plugin.initializationCount, 1);
      expect(runtime.rootKey.currentWidget, isA<RepaintBoundary>());

      await tester.pumpWidget(
        ManaWidget(controller: runtime, child: Text('Updated host')),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        ManaWidget(controller: runtime, enable: false, child: SizedBox()),
      );
      await tester.pumpWidget(
        ManaWidget(controller: runtime, child: Text('Enabled again')),
      );
      await tester.pumpAndSettle();
      expect(plugin.initializationCount, 1);
      expect(find.byType(ManaOverlay), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testRuntimeWidgets(
    'floating panel, settings, persistence and plugin activation need no Material',
    (tester) async {
      final plugin = TestPlugin();
      runtime.registerPlugin(plugin);
      await tester.pumpWidget(
        ManaWidget(controller: runtime, child: Text('Host')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingButton));
      await tester.pumpAndSettle();
      expect(find.byType(ManaPanel), findsOneWidget);

      Finder control(String label) => find.byWidgetPredicate(
        (widget) => widget is ManaButton && widget.tooltip == label,
      );
      await tester.tap(control('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(ManaSlider), findsNWidgets(2));
      final slider = find.byType(ManaSlider).first;
      await tester.tapAt(tester.getTopRight(slider) + const Offset(-10, 20));
      await tester.pumpAndSettle();
      expect(runtime.preferences.read('mana_floating_button_size'), 100);

      await tester.tap(control('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test plugin'));
      await tester.pumpAndSettle();
      expect(plugin.triggerCount, 1);
      expect(find.text('Plugin content'), findsOneWidget);

      expect(runtime.handleBack(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Plugin content'), findsNothing);
      expect(find.byType(FloatingButton), findsOneWidget);
      expect(find.text('Host'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testRuntimeWidgets('sliders support drag, keyboard, endpoints and RTL', (
    tester,
  ) async {
    var value = 50.0;
    var rtl = false;
    late StateSetter rebuild;
    await tester.pumpWidget(
      testApp(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: SizedBox(
                width: 200,
                child: ManaSlider(
                  value: value,
                  min: 30,
                  max: 100,
                  divisions: 7,
                  formatValue: (value) => '${value.toInt()}px',
                  semanticLabel: 'Size',
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
            );
          },
        ),
      ),
    );
    final slider = find.byType(ManaSlider);
    final rect = tester.getRect(slider);
    await tester.tapAt(Offset(rect.right - 10, rect.center.dy));
    await tester.pump();
    expect(value, 100);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(value, 90);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(value, 30);
    await tester.dragFrom(
      Offset(rect.left + 10, rect.center.dy),
      const Offset(180, 0),
    );
    await tester.pump();
    expect(value, 100);

    rebuild(() => rtl = true);
    await tester.pump();
    await tester.tapAt(Offset(rect.right - 10, rect.center.dy));
    await tester.pump();
    expect(value, 30);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(value, 40);
    expect(tester.takeException(), isNull);
  });

  testRuntimeWidgets(
    'window controls support keyboard and expose action labels',
    (tester) async {
      var fullscreenCount = 0;
      await tester.pumpWidget(
        testApp(
          WindowControls(
            drag: true,
            isFullscreen: false,
            showSettingButton: true,
            onPanUpdate: (_) {},
            onToggleSetting: () {},
            onFullscreen: () => fullscreenCount++,
            onMinimize: () {},
            onClose: () {},
          ),
        ),
      );
      final fullscreen = find.byWidgetPredicate(
        (widget) => widget is ManaButton && widget.tooltip == 'Fullscreen',
      );
      final detector = tester.widget<FocusableActionDetector>(
        find.descendant(
          of: fullscreen,
          matching: find.byType(FocusableActionDetector),
        ),
      );
      // Use tab navigation rather than requiring a Material focus traversal group.
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(detector.enabled, isTrue);
      expect(fullscreenCount, 1);
    },
  );

  testRuntimeWidgets(
    'check button awaits completion, preserves state, resets and disposes safely',
    (tester) async {
      final completer = Completer<void>();
      var calls = 0;
      Widget button() => testApp(
        CheckIconButton(
          initialIcon: const IconData(0x41),
          onPressed: () {
            calls++;
            return completer.future;
          },
        ),
      );
      await tester.pumpWidget(button());
      await tester.tap(find.byType(CheckIconButton));
      await tester.tap(find.byType(CheckIconButton));
      await tester.pump();
      expect(calls, 1);
      expect(find.byType(ManaIcon), findsNothing);
      completer.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ManaIcon), findsOneWidget);
      await tester.pumpWidget(button());
      expect(find.byType(ManaIcon), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(ManaIcon), findsNothing);
      await tester.tap(find.byType(CheckIconButton));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    },
  );

  testRuntimeWidgets('tooltips use the widgets-layer overlay on mouse hover', (
    tester,
  ) async {
    await tester.pumpWidget(
      ManaWidget(controller: runtime, child: Text('Host')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingButton));
    await tester.pumpAndSettle();
    final settings = find.byWidgetPredicate(
      (widget) => widget is ManaButton && widget.tooltip == 'Settings',
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(settings));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testRuntimeWidgets(
    'enabling an initially disabled entry initializes the plugins',
    (tester) async {
      final plugin = TestPlugin();
      runtime.registerPlugin(plugin);
      await tester.pumpWidget(
        ManaWidget(controller: runtime, enable: false, child: SizedBox()),
      );
      expect(plugin.initializationCount, 0);
      await tester.pumpWidget(
        ManaWidget(controller: runtime, child: SizedBox()),
      );
      await tester.pumpAndSettle();
      expect(plugin.initializationCount, 1);
      expect(find.byType(ManaOverlay), findsOneWidget);
    },
  );

  testRuntimeWidgets(
    'disposing while an async button action is pending is safe',
    (tester) async {
      final completer = Completer<void>();
      await tester.pumpWidget(
        testApp(
          CheckIconButton(
            initialIcon: const IconData(0x41),
            onPressed: () => completer.future,
          ),
        ),
      );
      await tester.tap(find.byType(CheckIconButton));
      await tester.pumpWidget(const SizedBox());
      completer.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testRuntimeWidgets('check button is disabled without a callback', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(const CheckIconButton(initialIcon: IconData(0x41))),
    );
    expect(
      tester.widget<ManaButton>(find.byType(ManaButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(CheckIconButton));
    await tester.pump();
    expect(find.byType(ManaIcon), findsNothing);
  });
}
