import 'dart:math' as math;

import 'package:example/demo_session.dart';
import 'package:example/main.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  void exampleTest(
    String name,
    Future<void> Function(WidgetTester, DemoSession) body, {
    Size size = const Size(1100, 1000),
    bool pauseAnimation = true,
  }) {
    testWidgets(name, (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = DemoSession(preferences: MemoryManaPreferences());
      try {
        await tester.pumpWidget(ExampleApp(session: session));
        if (pauseAnimation) {
          // A repeating demo animation never settles. Pause it for tests that
          // exercise unrelated controls; the default-on behavior is tested below.
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged!(
            false,
          );
          await tester.pumpAndSettle();
        }
        await body(tester, session);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await session.close();
        session.dispose();
      }
    });
  }

  Finder floatingButton() => find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == 'Mana',
  );

  Future<void> openTool(WidgetTester tester, String id) async {
    await tester.tap(floatingButton());
    await tester.pumpAndSettle();
    final tool = find.byKey(ValueKey(id));
    await tester.ensureVisible(tool);
    await tester.tap(tool);
    await tester.pumpAndSettle();
  }

  exampleTest('the floating panel is the only tool entry point', (
    tester,
    session,
  ) async {
    expect(session.controller.plugins.entries.length, 16);
    expect(find.text('Open Mana'), findsNothing);
    for (final entry in session.controller.plugins.entries) {
      expect(find.byKey(Key(entry.plugin.name)), findsNothing);
    }
    await tester.tap(floatingButton());
    await tester.pumpAndSettle();
    for (final entry in session.controller.plugins.entries) {
      expect(find.byKey(Key(entry.plugin.name)), findsOneWidget);
    }
    final grid = find.byKey(const Key('mana_grid'));
    await tester.ensureVisible(grid);
    await tester.tap(grid);
    await tester.pumpAndSettle();
    expect(session.controller.state.activePluginId, 'mana_grid');
    expect(find.text('Show Numbers'), findsOneWidget);
  });

  exampleTest('debug overlay toggles from the host page and preserves state', (
    tester,
    session,
  ) async {
    final input = find.byKey(const Key('sample-input'));
    await tester.enterText(input, 'Keep this input');
    final toggle = find.byKey(const Key('toggle-overlay'));
    expect(find.text('Hide debug overlay'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(session.controller.state.overlayVisible, isFalse);
    expect(floatingButton(), findsNothing);
    expect(find.text('Show debug overlay'), findsOneWidget);
    expect(find.text('Keep this input'), findsOneWidget);

    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();
    expect(find.text('显示调试层'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(session.controller.state.overlayVisible, isTrue);
    expect(floatingButton(), findsOneWidget);
    expect(find.text('隐藏调试层'), findsOneWidget);

    await openTool(tester, 'mana_grid');
    session.controller.minimizeWindow();
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(floatingButton(), findsNothing);
    expect(find.byKey(const Key('mana_grid')), findsNothing);
    expect(session.controller.state.activePluginId, 'mana_grid');
    expect(session.controller.state.windowMode, ManaWindowMode.minimized);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(session.controller.state.activePluginId, 'mana_grid');
    expect(session.controller.state.windowMode, ManaWindowMode.minimized);
    session.controller.restoreWindow();
    await tester.pumpAndSettle();
    expect(find.text('显示坐标'), findsOneWidget);
    expect(find.text('Keep this input'), findsOneWidget);

    session.controller.toggleOverlay(visible: false);
    await tester.pumpAndSettle();
    expect(find.text('显示调试层'), findsOneWidget);
    expect(find.text('显示坐标'), findsNothing);
    expect(session.controller.handleBack(), isFalse);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('显示坐标'), findsOneWidget);
  }, size: const Size(390, 844));

  exampleTest('pages share collectors and returning preserves home input', (
    tester,
    session,
  ) async {
    await tester.enterText(
      find.byKey(const Key('sample-input')),
      'Home state survives',
    );
    await tester.tap(find.byKey(const Key('request-GET')));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(session.requests.data.length, 1);

    await tester.tap(find.byKey(const Key('open-secondary-page')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('secondary-page')), findsOneWidget);
    expect(floatingButton(), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('secondary-input')),
      'Secondary state',
    );
    await tester.tap(find.byKey(const Key('secondary-counter')));
    await tester.pumpAndSettle();
    expect(find.text('Count: 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('secondary-request-POST')));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('secondary-generate-logs')));
    await tester.pumpAndSettle();
    expect(session.requests.data.length, 2);
    expect(session.logs.data, isNotEmpty);

    await tester.tap(find.byKey(const Key('back-to-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('secondary-page')), findsNothing);
    expect(find.text('Home state survives'), findsOneWidget);
    expect(session.requests.data.length, 2);
    expect(session.logs.data, isNotEmpty);

    // Re-entering creates a fresh host page, not a new debugging session.
    await tester.tap(find.byKey(const Key('open-secondary-page')));
    await tester.pumpAndSettle();
    expect(find.text('Count: 0'), findsOneWidget);
    expect(find.text('Secondary state'), findsNothing);
    expect(session.requests.data.length, 2);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Home state survives'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, size: const Size(390, 844));

  exampleTest('active tools survive navigation and consume back first', (
    tester,
    session,
  ) async {
    await openTool(tester, 'mana_log_viewer');
    session.controller.minimizeWindow();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-secondary-page')));
    await tester.pumpAndSettle();
    expect(session.controller.state.activePluginId, 'mana_log_viewer');
    expect(session.controller.state.windowMode, ManaWindowMode.minimized);

    session.controller.restoreWindow();
    await tester.pumpAndSettle();
    expect(session.controller.state.windowVisible, isTrue);
    // System back must act on the current route's debug history entry.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('secondary-page')), findsOneWidget);
    expect(session.controller.state.windowMode, ManaWindowMode.minimized);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('secondary-page')), findsNothing);
    expect(session.controller.state.activePluginId, 'mana_log_viewer');
    session.controller.restoreWindow();
    await tester.pumpAndSettle();
    expect(session.controller.state.windowVisible, isTrue);
    expect(tester.takeException(), isNull);
  });

  exampleTest('hidden debug overlay can be restored on the secondary page', (
    tester,
    session,
  ) async {
    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('切换主题'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggle-overlay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-secondary-page')));
    await tester.pumpAndSettle();
    expect(find.text('mana / 副页'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byKey(const Key('secondary-input'))))
          .brightness,
      Brightness.dark,
    );
    expect(floatingButton(), findsNothing);
    await tester.tap(find.byKey(const Key('secondary-request-GET')));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(session.requests.data.length, 1);
    await tester.tap(find.byKey(const Key('secondary-toggle-overlay')));
    await tester.pumpAndSettle();
    expect(floatingButton(), findsOneWidget);
    await tester.tap(find.byKey(const Key('back-to-home')));
    await tester.pumpAndSettle();
    expect(find.text('mana / 主页'), findsOneWidget);
    expect(session.controller.state.overlayVisible, isTrue);
    expect(session.requests.data.length, 1);
    expect(tester.takeException(), isNull);
  });

  exampleTest(
    'language switches the app and an already open kit without resetting it',
    (tester, session) async {
      await openTool(tester, 'mana_grid');
      expect(find.text('Show Numbers'), findsOneWidget);
      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();
      expect(find.text('生成日志'), findsOneWidget);
      expect(find.text('显示坐标'), findsOneWidget);
      expect(session.controller.state.activePluginId, 'mana_grid');
      expect(
        Localizations.localeOf(tester.element(find.byType(Scaffold))),
        const Locale('zh'),
      );
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.text('Generate logs'), findsOneWidget);
      expect(find.text('Show Numbers'), findsOneWidget);
      expect(session.controller.state.activePluginId, 'mana_grid');
    },
  );

  exampleTest(
    'animation starts enabled and its switch has contrast in both themes',
    (tester, session) async {
      final toggle = find.byType(SwitchListTile);
      final rotation = find.byWidgetPredicate(
        (widget) =>
            widget is RotationTransition && widget.turns is AnimationController,
      );
      final controller =
          tester.widget<RotationTransition>(rotation).turns
              as AnimationController;
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      expect(controller.isAnimating, isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      final before = controller.value;
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.value, greaterThan(before));

      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(controller.isAnimating, isFalse);
      final stopped = controller.value;
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.value, stopped);

      for (final brightness in [Brightness.light, Brightness.dark]) {
        if (brightness == Brightness.dark) {
          await tester.tap(find.byTooltip('Toggle theme'));
          await tester.pumpAndSettle();
        }
        final control = tester.widget<Switch>(find.byType(Switch));
        expect(Theme.of(tester.element(toggle)).brightness, brightness);
        for (final states in [
          <WidgetState>{},
          {WidgetState.selected},
        ]) {
          final thumb = control.thumbColor!.resolve(states)!.computeLuminance();
          final track = control.trackColor!.resolve(states)!.computeLuminance();
          final contrast =
              (math.max(thumb, track) + .05) / (math.min(thumb, track) + .05);
          expect(
            contrast,
            greaterThanOrEqualTo(3),
            reason: '$brightness $states',
          );
        }
      }

      await tester.tap(toggle);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      expect(controller.isAnimating, isTrue);
    },
    pauseAnimation: false,
  );

  exampleTest('request, input, animation and theme work on mobile', (
    tester,
    session,
  ) async {
    final request = find.byKey(const Key('request-GET'));
    await tester.ensureVisible(request);
    await tester.tap(request);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(session.requests.data.single.statusCode, 200);
    final input = find.byKey(const Key('sample-input'));
    await tester.ensureVisible(input);
    await tester.enterText(input, 'Hello / 你好');
    final toggle = find.byType(SwitchListTile);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Toggle theme'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(input)).brightness, Brightness.dark);
    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();
    expect(find.text('Hello / 你好'), findsOneWidget);
    expect(find.text('输入示例'), findsOneWidget);
    expect(session.requests.data.length, 1);
  }, size: const Size(390, 844));

  exampleTest('sample dialog confirms, cancels and dismisses', (
    tester,
    session,
  ) async {
    final open = find.byKey(const Key('open-dialog'));
    final dialog = find.byKey(const Key('sample-dialog'));
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(dialog, findsOneWidget);
    await tester.tap(find.byKey(const Key('dialog-cancel')));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(find.text('Dialog confirmed.'), findsNothing);

    await tester.tap(open);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 100));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(find.text('Dialog confirmed.'), findsNothing);

    await tester.tap(open);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(find.text('Dialog confirmed.'), findsOneWidget);
    expect(session.controller.state.activePluginId, isNull);
    expect(tester.takeException(), isNull);
  });

  exampleTest('dropdown selection survives locale and theme changes', (
    tester,
    session,
  ) async {
    final dropdown = find.byKey(const Key('sample-dropdown'));
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compact').last);
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<String>>(dropdown).value, 'compact');

    await tester.tap(find.byTooltip('Toggle theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<String>>(dropdown).value, 'compact');
    expect(Theme.of(tester.element(dropdown)).brightness, Brightness.dark);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('舒适').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<DropdownButton<String>>(dropdown).value,
      'comfortable',
    );

    final open = find.byKey(const Key('open-dialog'));
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.text('弹窗示例'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('已确认弹窗。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, size: const Size(390, 844));

  exampleTest(
    'preferences open with platform-decoded lists and seeded samples',
    (tester, session) async {
      SharedPreferences.setMockInitialValues({
        'example.languages': <Object?>['English', '中文'],
      });
      await openTool(tester, 'mana_shared_preferences_viewer');
      expect(find.text('example.languages'), findsOneWidget);
      expect(find.text('List<String>: ["English","中文"]'), findsOneWidget);
      expect(find.textContaining('Invalid argument'), findsNothing);
      await session.controller.closePlugin();
      await tester.pumpAndSettle();
      final seed = find.text('Seed preferences');
      await tester.ensureVisible(seed);
      await tester.tap(seed);
      await tester.pumpAndSettle();
      expect(session.controller.state.activePluginId, isNull);
      expect(session.controller.state.pluginPanelVisible, isFalse);
      await openTool(tester, 'mana_shared_preferences_viewer');
      for (final key in ['name', 'count', 'scale', 'enabled', 'languages']) {
        expect(find.text('example.$key'), findsOneWidget);
      }
      expect(
        session.controller.state.activePluginId,
        'mana_shared_preferences_viewer',
      );
      expect(tester.takeException(), isNull);
    },
  );

  exampleTest('generating data does not open or replace debugging tools', (
    tester,
    session,
  ) async {
    await openTool(tester, 'mana_grid');
    session.controller.minimizeWindow();
    await tester.pumpAndSettle();
    final logs = find.text('Generate logs');
    await tester.ensureVisible(logs);
    await tester.tap(logs);
    await tester.pumpAndSettle();
    expect(session.logs.data, isNotEmpty);
    expect(session.controller.state.activePluginId, 'mana_grid');
    expect(session.controller.state.windowMode, ManaWindowMode.minimized);
    final seed = find.text('Seed preferences');
    await tester.tap(seed);
    await tester.pumpAndSettle();
    expect(session.controller.state.activePluginId, 'mana_grid');
    expect(session.controller.state.pluginPanelVisible, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('example.name'), 'Flutter Mana');
  });

  exampleTest('small screen and large text fit in both languages', (
    tester,
    session,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();
    final dropdown = find.byKey(const Key('sample-dropdown'));
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('紧凑').last);
    await tester.pumpAndSettle();
    final open = find.byKey(const Key('open-dialog'));
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.text('弹窗示例'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dialog-cancel')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }, size: const Size(360, 780));
}
