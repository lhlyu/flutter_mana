import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/helpers.dart';

class _RecordingPreferences extends MemoryManaPreferences {
  int saves = 0;
  bool closed = false;
  @override
  Future<void> save(ManaSettings settings) async {
    saves++;
    await super.save(settings);
  }

  @override
  Future<void> close() async => closed = true;
}

class _FailOncePreferences extends MemoryManaPreferences {
  int attempts = 0;
  @override
  Future<ManaSettings> load() async {
    if (attempts++ == 0) throw StateError('Storage unavailable');
    return super.load();
  }
}

void main() {
  test('a throwing registry error handler cannot skip peer initialization or disposal', () async {
    final reports = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reports.add;
    addTearDown(() => FlutterError.onError = previous);
    final registry = ManaPluginManager(
      onError: (_, _) => throw StateError('Handler failed'),
    );
    final failed = TestPlugin(
      name: 'failed',
      initializeAction: () => throw StateError('Initialization failed'),
      disposeAction: () => throw StateError('Disposal failed'),
    );
    final good = TestPlugin(name: 'good');
    registry.registerAll([failed, good]);
    await registry.initialize();
    expect(registry[good.name]!.status, ManaPluginStatus.ready);
    await registry.close();
    expect(failed.disposeCount, 1);
    expect(good.disposeCount, 1);
    expect(reports, hasLength(2));
  });

  test(
    'a throwing runtime error handler cannot poison the session queue',
    () async {
      final reports = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = reports.add;
      addTearDown(() => FlutterError.onError = previous);
      final failed = TestPlugin(
        name: 'failed',
        triggerAction: () => throw StateError('Trigger failed'),
      );
      final good = TestPlugin(name: 'good');
      final runtime = ManaController(
        preferences: MemoryManaPreferences(),
        plugins: [failed, good],
        onError: (_, _) => throw StateError('Handler failed'),
      );
      expect(await runtime.activatePlugin(failed.name), isFalse);
      expect(await runtime.activatePlugin(good.name), isTrue);
      await runtime.close();
      expect(good.disposeCount, 1);
      expect(reports, hasLength(1));
    },
  );

  test(
    'unregister waits for a pending trigger before disposing its plugin',
    () async {
      final gate = Completer<void>();
      final plugin = TestPlugin(triggerAction: () => gate.future);
      final runtime = ManaController(
        preferences: MemoryManaPreferences(),
        plugins: [plugin],
      );
      final activation = runtime.activatePlugin(plugin.name);
      while (plugin.triggerCount == 0) {
        await Future<void>.delayed(.zero);
      }
      final removal = runtime.unregisterPlugin(plugin.name);
      expect(plugin.disposeCount, 0);
      gate.complete();
      expect(await activation, isFalse);
      await removal;
      expect(plugin.deactivateCount, 1);
      expect(plugin.disposeCount, 1);
      expect(runtime.state.activePluginId, isNull);
      await runtime.close();
    },
  );

  test(
    'runtime initialization can be retried after a storage failure',
    () async {
      final preferences = _FailOncePreferences();
      final runtime = ManaController(
        preferences: preferences,
        onError: (_, _) {},
      );
      await expectLater(runtime.initialize(), throwsStateError);
      expect(runtime.initializationError, isA<StateError>());
      await runtime.retryInitialization();
      expect(runtime.isReady, isTrue);
      expect(runtime.initializationError, isNull);
      await runtime.close();
    },
  );

  test('a failed plugin initialization can be retried independently', () async {
    var attempts = 0;
    final registry = ManaPluginManager(onError: (_, _) {});
    final plugin = TestPlugin(
      initializeAction: () {
        if (attempts++ == 0) throw StateError('Temporary failure');
      },
    );
    registry.register(plugin);
    await registry.initialize();
    expect(registry[plugin.name]!.status, ManaPluginStatus.failed);
    await registry.retryInitialization(plugin.name);
    expect(plugin.initializationCount, 2);
    expect(registry[plugin.name]!.status, ManaPluginStatus.ready);
    await registry.close();
  });

  test('registry rejects invalid IDs and duplicates and exposes read-only collections', () async {
    final registry = ManaPluginManager();
    addTearDown(registry.close);
    final plugin = TestPlugin();
    registry.register(plugin);
    expect(() => registry.register(TestPlugin()), throwsStateError);
    expect(() => registry.register(TestPlugin(name: '')), throwsArgumentError);
    expect(
      () => registry.register(TestPlugin(name: ManaPluginManager.name)),
      throwsArgumentError,
    );
    expect(() => registry.pluginsMap.clear(), throwsUnsupportedError);
    expect(() => registry.entries.clear(), throwsUnsupportedError);
  });

  test(
    'initialization runs once, isolates failures and skips unsupported plugins',
    () async {
      final errors = <Object>[];
      final registry = ManaPluginManager(
        onError: (error, _) => errors.add(error),
      );
      addTearDown(registry.close);
      final good = TestPlugin(name: 'good');
      final failed = TestPlugin(
        name: 'failed',
        initializeAction: () => throw StateError('init failed'),
      );
      final unsupported = TestPlugin(name: 'unsupported', isSupported: false);
      registry.registerAll([good, failed, unsupported]);
      await Future.wait([registry.initialize(), registry.initialize()]);
      expect(good.initializationCount, 1);
      expect(registry['good']!.status, ManaPluginStatus.ready);
      expect(registry['failed']!.status, ManaPluginStatus.failed);
      expect(registry['failed']!.stackTrace, isNotNull);
      expect(registry['unsupported']!.status, ManaPluginStatus.unsupported);
      expect(unsupported.initializationCount, 0);
      expect(errors, hasLength(1));
    },
  );

  test(
    'a plugin registered after startup is initialized and observable',
    () async {
      final registry = ManaPluginManager();
      addTearDown(registry.close);
      await registry.initialize();
      var notifications = 0;
      registry.addListener(() => notifications++);
      final plugin = TestPlugin();
      registry.register(plugin);
      await registry.ensureReady(plugin.name);
      expect(plugin.initializationCount, 1);
      expect(notifications, greaterThanOrEqualTo(2));
    },
  );

  test(
    'shutdown waits for initialization and releases resources once',
    () async {
      final gate = Completer<void>();
      final plugin = TestPlugin(initializeAction: () => gate.future);
      final registry = ManaPluginManager()..register(plugin);
      final initialized = registry.initialize();
      await Future<void>.delayed(.zero);
      var done = false;
      final closing = registry.close().then((_) => done = true);
      expect(done, isFalse);
      gate.complete();
      await initialized;
      await closing;
      await registry.close();
      expect(plugin.disposeCount, 1);
    },
  );

  test('controllers have isolated state, roots and registries', () async {
    final first = ManaController(preferences: MemoryManaPreferences());
    final second = ManaController(preferences: MemoryManaPreferences());
    addTearDown(first.close);
    addTearDown(second.close);
    first.registerPlugin(TestPlugin());
    first.openPluginPanel();
    expect(second.plugins.entries, isEmpty);
    expect(second.state.pluginPanelVisible, isFalse);
    expect(identical(first.rootKey, second.rootKey), isFalse);
    final owner = Object();
    first.attach(owner);
    expect(() => first.attach(Object()), throwsStateError);
    first.detach(owner);
    first.attach(Object());
  });

  test('debug shell readiness does not wait for a slow plugin', () async {
    final gate = Completer<void>();
    final plugin = TestPlugin(initializeAction: () => gate.future);
    final runtime = ManaController(
      plugins: [plugin],
      preferences: MemoryManaPreferences(),
    );
    await runtime.initialize();
    expect(runtime.isReady, isTrue);
    expect(runtime.plugins[plugin.name]!.status, isNot(ManaPluginStatus.ready));
    gate.complete();
    await runtime.close();
  });

  test(
    'session commands retain fullscreen on restore and clean up on close',
    () async {
      final plugin = TestPlugin();
      final runtime = ManaController(
        plugins: [plugin],
        preferences: MemoryManaPreferences(),
      );
      addTearDown(runtime.close);
      expect(await runtime.activatePlugin(plugin.name), isTrue);
      runtime.toggleFullscreen();
      expect(runtime.state.windowMode, ManaWindowMode.fullscreen);
      expect(runtime.state.floatingButtonVisible, isFalse);
      runtime.minimizeWindow();
      expect(runtime.state.windowVisible, isFalse);
      runtime.restoreWindow();
      expect(runtime.state.windowMode, ManaWindowMode.fullscreen);
      await runtime.closePlugin();
      expect(runtime.state.activePluginId, isNull);
      expect(runtime.state.floatingButtonVisible, isTrue);
      expect(plugin.deactivateCount, 1);
    },
  );

  test(
    'reopening an active plugin does not start its resources twice',
    () async {
      final plugin = TestPlugin();
      final runtime = ManaController(
        plugins: [plugin],
        preferences: MemoryManaPreferences(),
      );
      addTearDown(runtime.close);
      await runtime.activatePlugin(plugin.name);
      await runtime.activatePlugin(plugin.name);
      expect(plugin.triggerCount, 1);
    },
  );

  test(
    'latest activation wins while previous initialization is pending',
    () async {
      final gate = Completer<void>();
      final first = TestPlugin(
        name: 'first',
        initializeAction: () => gate.future,
      );
      final second = TestPlugin(name: 'second');
      final runtime = ManaController(
        plugins: [first, second],
        preferences: MemoryManaPreferences(),
      );
      addTearDown(runtime.close);
      final pending = runtime.activatePlugin(first.name);
      final latest = runtime.activatePlugin(second.name);
      gate.complete();
      expect(await pending, isFalse);
      expect(await latest, isTrue);
      expect(runtime.state.activePluginId, second.name);
      expect(first.triggerCount, 0);
    },
  );

  test('closing during activation prevents late publication and releases the session', () async {
    final gate = Completer<void>();
    final plugin = TestPlugin(triggerAction: () => gate.future);
    final runtime = ManaController(
      plugins: [plugin],
      preferences: MemoryManaPreferences(),
    );
    final activation = runtime.activatePlugin(plugin.name);
    await Future<void>.delayed(.zero);
    final closing = runtime.close();
    gate.complete();
    expect(await activation, isFalse);
    await closing;
    expect(plugin.deactivateCount, 1);
    expect(plugin.disposeCount, 1);
  });

  test(
    'failed activation leaves no deactivated previous plugin selected',
    () async {
      final good = TestPlugin(name: 'good');
      final failed = TestPlugin(
        name: 'failed',
        triggerAction: () => throw StateError('trigger failed'),
      );
      final errors = <Object>[];
      final runtime = ManaController(
        plugins: [good, failed],
        preferences: MemoryManaPreferences(),
        onError: (error, _) => errors.add(error),
      );
      addTearDown(runtime.close);
      await runtime.activatePlugin(good.name);
      expect(await runtime.activatePlugin(failed.name), isFalse);
      expect(runtime.state.activePluginId, isNull);
      expect(failed.deactivateCount, 1);
      expect(errors, hasLength(1));
    },
  );

  test('action-only plugins require no UI or active window', () async {
    final action = TestPlugin(presentation: .action);
    final runtime = ManaController(
      plugins: [action],
      preferences: MemoryManaPreferences(),
    );
    addTearDown(runtime.close);
    expect(await runtime.activatePlugin(action.name), isTrue);
    expect(action.triggerCount, 1);
    expect(runtime.state.activePluginId, isNull);
    expect(runtime.handleBack(), isFalse);
  });

  test('unregistering an active plugin deactivates and disposes it', () async {
    final plugin = TestPlugin();
    final runtime = ManaController(
      plugins: [plugin],
      preferences: MemoryManaPreferences(),
    );
    addTearDown(runtime.close);
    await runtime.activatePlugin(plugin.name);
    await runtime.unregisterPlugin(plugin.name);
    expect(runtime.state.activePluginId, isNull);
    expect(runtime.plugins.entries, isEmpty);
    expect(plugin.deactivateCount, 1);
    expect(plugin.disposeCount, 1);
  });

  test('settings normalize invalid storage, clamp commands and coalesce persistence', () async {
    final storage = _RecordingPreferences();
    final runtime = ManaController(preferences: storage);
    await runtime.initialize();
    runtime.updateSettings(buttonSize: 200);
    runtime.updateSettings(buttonSize: 100);
    runtime.updateSettings(buttonOpacity: -1);
    runtime.updateSettings(buttonSize: double.nan);
    runtime.updateSettings(buttonPosition: const Offset(0, 20));
    await runtime.flushSettings();
    expect(storage.saves, 1);
    expect(runtime.state.settings.buttonSize, 100);
    expect(runtime.state.settings.buttonOpacity, 0.1);
    expect(storage.read('mana_floating_button_x'), 0);
    await runtime.close();
    expect(storage.closed, isTrue);
    final settings = ManaSettings.fromMap({
      'mana_floating_button_size': double.nan,
      'mana_floating_button_opacity': 9.0,
      'mana_floating_button_x': double.infinity,
    });
    expect(settings.buttonSize, 50);
    expect(settings.buttonOpacity, 1);
    expect(settings.buttonPosition, isNull);
  });
}
