import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana/src/widgets/floating_button/index.dart';
import 'package:flutter_mana/src/widgets/floating_window/window_controls.dart';
import 'package:flutter_mana/src/widgets/mana_button.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/helpers.dart';

class _TopWindow extends TestPlugin {
  _TopWindow({this.width = 200, this.height = 100});
  final double width;
  final double height;

  @override
  Widget buildWidget(BuildContext context) => ManaFloatingWindow(
    name: name,
    initialPosition: Offset.zero,
    initialWidth: width,
    initialHeight: height,
    content: const Text('Window content'),
    setting: const Text('Settings content'),
  );
}

class _EditableWindow extends TestPlugin {
  final text = TextEditingController(text: 'content');
  final focus = FocusNode();
  @override
  Widget buildWidget(BuildContext context) => ManaFloatingWindow(
    name: name,
    showBarrier: false,
    content: Column(
      children: [
        EditableText(
          controller: text,
          focusNode: focus,
          style: const TextStyle(color: Color(0xFF000000)),
          cursorColor: const Color(0xFF000000),
          backgroundCursorColor: const Color(0xFF000000),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 100,
            itemBuilder: (_, i) => SizedBox(height: 30, child: Text('row $i')),
          ),
        ),
      ],
    ),
    setting: const Text('Settings only'),
  );
}

void main() {
  testWidgets(
    'settings exclude hidden content focus and primary scroll inheritance without losing state',
    (tester) async {
      final plugin = _EditableWindow();
      final runtime = ManaController(
        plugins: [plugin],
        preferences: MemoryManaPreferences(),
      );
      final outer = ScrollController();
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFFFFFFFF),
          builder: (context, _) => PrimaryScrollController(
            controller: outer,
            child: ManaWidget.builder(
              controller: runtime,
              child: ListView.builder(
                primary: true,
                itemCount: 100,
                itemBuilder: (_, i) =>
                    SizedBox(height: 50, child: Text('host $i')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await runtime.activatePlugin(plugin.name);
      await tester.pumpAndSettle();
      final field = find.byType(EditableText);
      await tester.enterText(field, 'kept query');
      await tester.pumpAndSettle();
      expect(plugin.focus.hasFocus, isTrue);
      expect(outer.positions, hasLength(1));
      final list = find.descendant(
        of: find.byType(ManaFloatingWindow),
        matching: find.byType(ListView),
      );
      final listPosition = tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)),
          )
          .position;
      listPosition.jumpTo(60);
      await tester.pumpAndSettle();
      final settings = find.byWidgetPredicate(
        (widget) => widget is ManaButton && widget.tooltip == 'Settings',
      );
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(plugin.focus.hasFocus, isFalse);
      expect(field, findsNothing);
      expect(find.text('Settings only'), findsOneWidget);
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(field, findsOneWidget);
      expect(plugin.text.text, 'kept query');
      expect(listPosition.pixels, 60);
      expect(outer.offset, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
      plugin.text.dispose();
      plugin.focus.dispose();
      outer.dispose();
    },
  );
  testWidgets('external button position changes reach the screen and storage', (
    tester,
  ) async {
    final runtime = ManaController(preferences: MemoryManaPreferences());
    try {
      await tester.pumpWidget(
        ManaWidget(controller: runtime, child: const Text('Host')),
      );
      await tester.pumpAndSettle();
      runtime.updateSettings(buttonPosition: const Offset(10, 200));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byType(FloatingButton)),
        const Offset(10, 200),
      );
      runtime.updateSettings(buttonOpacity: .5);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byType(FloatingButton)),
        const Offset(10, 200),
      );
      expect(runtime.preferences.read('mana_floating_button_x'), 10);
      expect(runtime.preferences.read('mana_floating_button_y'), 200);
      runtime.updateSettings(buttonPosition: const Offset(10000, 10000));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(FloatingButton));
      expect(rect.right, lessThanOrEqualTo(800));
      expect(rect.bottom, lessThanOrEqualTo(600));
    } finally {
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    }
  });

  testWidgets(
    'window drag, inset changes and fullscreen keep controls in the safe area',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(
        left: 20,
        top: 44,
        right: 16,
        bottom: 34,
      );
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final plugin = _TopWindow();
      final runtime = ManaController(
        plugins: [plugin],
        preferences: MemoryManaPreferences(),
      );
      try {
        await tester.pumpWidget(
          ManaWidget(controller: runtime, child: const Text('Host')),
        );
        await tester.pumpAndSettle();
        await runtime.activatePlugin(plugin.name);
        await tester.pumpAndSettle();
        final controls = find.byType(WindowControls);
        expect(tester.getTopLeft(controls), const Offset(20, 44));
        tester
            .widget<WindowControls>(controls)
            .onPanUpdate(
              DragUpdateDetails(
                globalPosition: Offset.zero,
                delta: const Offset(10000, 10000),
              ),
            );
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(controls), const Offset(584, 466));
        tester
            .widget<WindowControls>(controls)
            .onPanUpdate(
              DragUpdateDetails(
                globalPosition: Offset.zero,
                delta: const Offset(-10000, -10000),
              ),
            );
        await tester.pumpAndSettle();
        tester.view.padding = const FakeViewPadding(
          left: 20,
          top: 60,
          right: 16,
          bottom: 34,
        );
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(controls), const Offset(20, 60));
        runtime.toggleFullscreen();
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(controls), const Offset(20, 60));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await runtime.close();
      }
    },
  );

  testWidgets('fractional insets keep full-size windows within valid bounds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.25;
    tester.view.padding = const FakeViewPadding(
      left: 44,
      top: 44,
      right: 44,
      bottom: 44,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final runtime = ManaController(
      plugins: [_TopWindow(width: double.infinity, height: double.infinity)],
      preferences: MemoryManaPreferences(),
    );
    try {
      await tester.pumpWidget(
        ManaWidget(controller: runtime, child: const Text('Host')),
      );
      await tester.pumpAndSettle();
      await runtime.activatePlugin('test_plugin');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final origin = tester.getTopLeft(find.byType(WindowControls));
      expect(origin.dx, closeTo(35.2, 1e-8));
      expect(origin.dy, closeTo(35.2, 1e-8));
    } finally {
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    }
  });

  testWidgets(
    'embedded hosts below the status bar do not receive duplicate insets',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final plugin = _TopWindow();
      final runtime = ManaController(
        plugins: [plugin],
        preferences: MemoryManaPreferences(),
      );
      try {
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFFFFFFFF),
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(top: 100),
              child: ManaWidget.builder(
                controller: runtime,
                child: const Text('Host'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await runtime.activatePlugin(plugin.name);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byType(WindowControls)).dy, 100);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await runtime.close();
      }
    },
  );

  testWidgets(
    'all control tooltips follow locale changes and fullscreen state',
    (tester) async {
      final runtime = ManaController(
        plugins: [_TopWindow()],
        preferences: MemoryManaPreferences(),
      );
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      Finder tooltip(String value) => find.byWidgetPredicate(
        (widget) => widget is ManaButton && widget.tooltip == value,
      );
      try {
        tester.platformDispatcher.localesTestValue = [const Locale('en')];
        await tester.pumpWidget(
          ManaWidget(controller: runtime, child: const Text('Host')),
        );
        await tester.pumpAndSettle();
        await runtime.activatePlugin('test_plugin');
        await tester.pumpAndSettle();
        for (final label in ['Fullscreen', 'Minimize', 'Settings', 'Close']) {
          expect(tooltip(label), findsOneWidget);
        }
        runtime.toggleFullscreen();
        await tester.pumpAndSettle();
        expect(tooltip('Exit fullscreen'), findsOneWidget);
        tester.platformDispatcher.localesTestValue = [const Locale('zh')];
        await tester.pumpAndSettle();
        for (final label in ['退出全屏', '最小化', '设置', '关闭']) {
          expect(tooltip(label), findsOneWidget);
        }
        tester.platformDispatcher.localesTestValue = [const Locale('ar')];
        await tester.pumpAndSettle();
        expect(tooltip('Exit fullscreen'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await runtime.close();
      }
    },
  );
}
