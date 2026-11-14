import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana/src/widgets/floating_button/controller.dart';
import 'package:flutter_mana/src/widgets/floating_button/index.dart';
import 'package:flutter_mana/src/widgets/floating_window/controller.dart';
import 'package:flutter_mana/src/widgets/mana_button.dart';
import 'package:flutter_mana/src/widgets/mana_i18n.dart';
import 'package:flutter_mana/src/widgets/mana_panel.dart';
import 'package:flutter_mana/src/widgets/mana_slider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/helpers.dart';

class _Translations with ManaI18n {}

Finder control(String label) => find.byWidgetPredicate(
  (widget) => widget is ManaButton && widget.tooltip == label,
);

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

  Future<void> mount(
    WidgetTester tester, [
    Widget child = const Text('Host'),
  ]) async {
    await tester.pumpWidget(ManaWidget(controller: runtime, child: child));
    await tester.pumpAndSettle();
  }

  testRuntimeWidgets(
    'custom barrier survives minimization until the next back action',
    (tester) async {
      final plugin = TestPlugin(
        barrier: const IgnorePointer(
          child: SizedBox.expand(key: ValueKey('barrier')),
        ),
      );
      runtime.registerPlugin(plugin);
      await mount(tester);
      await runtime.activatePlugin(plugin.name);
      await tester.pumpAndSettle();
      await tester.tap(control('最小化'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('barrier')), findsOneWidget);
      expect(runtime.handleBack(), isTrue);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('barrier')), findsNothing);
      expect(runtime.state.activePluginId, isNull);
    },
  );

  testRuntimeWidgets('closing management does not close the active plugin', (
    tester,
  ) async {
    final plugin = TestPlugin();
    runtime.registerPlugin(plugin);
    await mount(tester);
    await runtime.activatePlugin(plugin.name);
    runtime.openPluginPanel();
    await tester.pumpAndSettle();
    await tester.tap(control('关闭').last);
    await tester.pumpAndSettle();
    expect(runtime.state.pluginPanelVisible, isFalse);
    expect(runtime.state.activePluginId, plugin.name);
    expect(find.text('Plugin content'), findsOneWidget);
  });

  testRuntimeWidgets('locale changes rebuild open settings and preserve RTL', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await mount(tester);
    runtime.openPluginPanel();
    await tester.pumpAndSettle();
    await tester.tap(control('设置'));
    await tester.pumpAndSettle();
    expect(find.text('Float Button Size'), findsOneWidget);
    tester.platformDispatcher.localesTestValue = [const Locale('zh')];
    await tester.pumpAndSettle();
    expect(find.text('浮动按钮大小'), findsOneWidget);
    tester.platformDispatcher.localesTestValue = [const Locale('ar')];
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(ManaSlider).first)),
      TextDirection.rtl,
    );
  });

  testRuntimeWidgets(
    'resizing clamps instead of recentering a dragged window',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FloatingWindowController? geometry;
      await tester.pumpWidget(
        testApp(
          ManaScope(
            controller: runtime,
            child: Builder(
              builder: (context) {
                if (geometry case final current?) {
                  current.update(context);
                } else {
                  geometry = FloatingWindowController(
                    context,
                    name: 'test',
                    initialWidth: 200,
                    initialHeight: 100,
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      geometry!.offset.value = const Offset(20, 30);
      tester.view.physicalSize = const Size(700, 500);
      await tester.pumpAndSettle();
      expect(geometry!.offset.value, const Offset(20, 30));
      geometry!.dispose();
    },
  );

  testRuntimeWidgets('slider announces consistent units', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        testApp(
          SizedBox(
            width: 200,
            child: ManaSlider(
              value: 0.5,
              min: 0.1,
              max: 1,
              divisions: 9,
              formatValue: (value) => '${(value * 100).round()}%',
              semanticLabel: 'Opacity',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.byType(ManaSlider))
          .getSemanticsData();
      expect(data.value, '50%');
      expect(data.increasedValue, '60%');
      expect(data.decreasedValue, '40%');
    } finally {
      semantics.dispose();
    }
  });

  testRuntimeWidgets(
    'scrolling vertically across a slider does not change its value',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        testApp(
          SizedBox(
            width: 200,
            height: 120,
            child: ListView(
              children: [
                ManaSlider(
                  value: 0,
                  min: 0,
                  max: 100,
                  divisions: 10,
                  formatValue: (value) => '$value',
                  semanticLabel: 'Value',
                  onChanged: (_) => calls++,
                ),
                const SizedBox(height: 1000),
              ],
            ),
          ),
        ),
      );
      await tester.drag(find.byType(ManaSlider), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(calls, 0);
    },
  );

  testRuntimeWidgets('plugin grid accommodates narrow width and large text', (
    tester,
  ) async {
    runtime.registerPlugin(TestPlugin());
    await runtime.initialize();
    await runtime.initializePlugins();
    await tester.pumpWidget(
      testApp(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3)),
          child: ManaScope(
            controller: runtime,
            child: const SizedBox(width: 60, height: 240, child: ManaPanel()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test plugin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('translations are explicit and have no cached global locale', () {
    final translations = _Translations();
    expect(
      translations.t('float_button_size', locale: const Locale('en')),
      'Float Button Size',
    );
    expect(
      translations.t('float_button_size', locale: const Locale('zh')),
      '浮动按钮大小',
    );
  });

  test('default storage normalizes invalid values without exposing its backing store', () async {
    SharedPreferences.setMockInitialValues({
      'mana_floating_button_size': double.nan,
      'mana_floating_button_opacity': 4.0,
      'mana_floating_button_x': double.infinity,
      'mana_floating_button_y': 'invalid',
    });
    final adapter = ManaStore();
    final settings = await adapter.load();
    expect(settings.buttonSize, 50);
    expect(settings.buttonOpacity, 1);
    expect(settings.buttonPosition, isNull);
    await adapter.write('plugin.setting', true);
    expect(adapter.read('plugin.setting'), isTrue);
    await adapter.close();
  });

  testRuntimeWidgets(
    'small viewport supports both the floating button and management toolbar',
    (tester) async {
      tester.view.physicalSize = const Size(100, 100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester);
      await tester.tap(find.byType(FloatingButton));
      await tester.pumpAndSettle();
      expect(find.byType(ManaPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testRuntimeWidgets('floating geometry releases its owned offset notifier', (
    tester,
  ) async {
    FloatingButtonController? geometry;
    await tester.pumpWidget(
      testApp(
        ManaScope(
          controller: runtime,
          child: Builder(
            builder: (context) {
              geometry = FloatingButtonController(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    geometry!.dispose();
    expect(() => geometry!.offset.addListener(() {}), throwsFlutterError);
  });

  testRuntimeWidgets(
    'minimized default window releases host pointer and back handling',
    (tester) async {
      var hostTaps = 0;
      final plugin = TestPlugin();
      runtime.registerPlugin(plugin);
      await mount(
        tester,
        GestureDetector(
          behavior: .opaque,
          onTap: () => hostTaps++,
          child: const SizedBox.expand(child: Text('Host')),
        ),
      );
      await runtime.activatePlugin(plugin.name);
      await tester.pumpAndSettle();
      await tester.tap(control('最小化'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(400, 300));
      expect(hostTaps, 1);
      expect(runtime.canHandleBack, isFalse);
      expect(runtime.handleBack(), isFalse);
    },
  );

  testRuntimeWidgets(
    'slider suppresses repeated calls for the current division',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        testApp(
          SizedBox(
            width: 200,
            child: ManaSlider(
              value: 50,
              min: 0,
              max: 100,
              divisions: 10,
              formatValue: (value) => '$value%',
              semanticLabel: 'Value',
              onChanged: (_) => calls++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ManaSlider));
      await tester.pump();
      expect(calls, 0);
    },
  );

  testRuntimeWidgets(
    'pending actions disable the button and report recoverable errors',
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
      await tester.pump();
      expect(
        tester.widget<ManaButton>(find.byType(ManaButton)).onPressed,
        isNull,
      );
      completer.completeError(StateError('copy failed'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isA<StateError>());
      expect(
        tester.widget<ManaButton>(find.byType(ManaButton)).onPressed,
        isNotNull,
      );
    },
  );
}
