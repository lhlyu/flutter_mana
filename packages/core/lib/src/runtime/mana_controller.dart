import 'dart:async';

import 'package:flutter/widgets.dart';

import '../storage/mana_preferences.dart';
import '../storage/mana_store.dart';
import 'mana_pluggable.dart';
import 'mana_error.dart';
import 'mana_plugin_manager.dart';
import 'mana_state.dart';

typedef ManaErrorHandler = void Function(Object error, StackTrace stack);

final class _WindowRegistration {
  final bool hasBarrier;
  final bool Function() dismissSettings;
  const _WindowRegistration(this.hasBarrier, this.dismissSettings);
}

/// Owns the registered plugins and preferences.
final class ManaController extends ChangeNotifier {
  final ManaPreferences preferences;
  final ManaErrorHandler? onError;
  final GlobalKey rootKey = GlobalKey(debugLabel: 'Mana host');
  late final ManaPluginManager _plugins;
  ManaPluginRegistry get plugins => _plugins;
  final _windows = <String, _WindowRegistration>{};
  ManaState _state = const ManaState();
  ManaState get state => _state;
  bool _ready = false;
  bool get isReady => _ready;
  bool _closed = false;
  bool get isClosed => _closed;
  Object? _initializationError;
  Object? get initializationError => _initializationError;
  Object? _host;
  Future<void>? _initialization;
  Future<void>? _closing;
  Future<void>? _sessionWork;
  Future<void>? _saving;
  bool _savePending = false;
  int _generation = 0;
  ManaWindowMode _restoreMode = .normal;

  ManaController({
    Iterable<ManaPluggable> plugins = const [],
    ManaPreferences? preferences,
    this.onError,
  }) : preferences = preferences ?? ManaStore() {
    _plugins = ManaPluginManager(onError: _reportError)..registerAll(plugins);
    _plugins.addListener(_registryChanged);
  }

  void _reportError(Object error, StackTrace stack) =>
      reportManaError(error, stack, onError);

  void attach(Object host) {
    if (_closed) throw StateError('ManaController is closed.');
    if (_host != null && !identical(_host, host)) {
      throw StateError('A controller can only attach to one host.');
    }
    _host = host;
  }

  void detach(Object host) {
    if (identical(_host, host)) _host = null;
  }

  Future<void> initialize() {
    if (_closed) return Future.error(StateError('ManaController is closed.'));
    return _initialization ??= _initialize();
  }

  Future<void> retryInitialization() {
    if (_initializationError != null && !_closed) {
      _initialization = null;
      _initializationError = null;
    }
    return initialize();
  }

  Future<void> _initialize() async {
    try {
      final settings = await preferences.load();
      if (_closed) return;
      _state = _state.copyWith(settings: settings);
      _ready = true;
      notifyListeners();
      unawaited(_plugins.initialize());
    } catch (error, stack) {
      _initializationError = error;
      _reportError(error, stack);
      if (!_closed) notifyListeners();
      rethrow;
    }
  }

  void _registryChanged() {
    if (_closed) return;
    if (_state.activePluginId case final id? when _plugins[id] == null) {
      _generation++;
      _state = _state.copyWith(clearActivePlugin: true, windowMode: .normal);
    }
    notifyListeners();
  }

  Future<void> initializePlugins() async {
    await initialize();
    if (!_closed) await _plugins.initialize();
  }

  Future<void> retryPluginInitialization(String id) =>
      _plugins.retryInitialization(id);

  void registerPlugin(ManaPluggable plugin) => _plugins.register(plugin);

  Future<void> unregisterPlugin(String id) async {
    if (_closed) throw StateError('ManaController is closed.');
    _generation++;
    if (_state.activePluginId == id) {
      await closePlugin();
    } else {
      await _sessionWork;
    }
    await _plugins.unregister(id);
  }

  Future<bool> activatePlugin(String id) {
    if (_closed) return Future.value(false);
    final generation = ++_generation;
    final result = (_sessionWork ?? Future.value()).then(
      (_) => _activate(id, generation),
    );
    _sessionWork = result.then((_) {});
    return result;
  }

  Future<bool> _activate(String id, int generation) async {
    ManaPluggable? started;
    bool cancelled() => _closed || generation != _generation;
    try {
      if (cancelled()) return false;
      await initialize();
      final entry = _plugins[id];
      if (cancelled() ||
          entry == null ||
          entry.status == .unsupported ||
          entry.status == .failed) {
        return false;
      }
      try {
        await _plugins.ensureReady(id);
      } catch (_) {
        if (_plugins[id]?.status == .failed || cancelled()) return false;
        rethrow;
      }
      if (cancelled()) return false;
      if (_state.activePluginId == id) {
        if (_state.windowMode == .minimized) restoreWindow();
        closePluginPanel();
        return true;
      }
      final previousId = _state.activePluginId;
      final previous = previousId == null ? null : _plugins[previousId]?.plugin;
      _update(_state.copyWith(clearActivePlugin: true, windowMode: .normal));
      if (previous != null) await _deactivate(previous);
      if (cancelled()) return false;
      final plugin = _plugins[id]!.plugin;
      started = plugin;
      await Future<void>.sync(plugin.onTrigger);
      if (cancelled() || plugin.presentation == .action) {
        await _deactivate(plugin);
        started = null;
        if (cancelled()) return false;
      }
      _restoreMode = .normal;
      _update(
        _state.copyWith(
          activePluginId: plugin.presentation == .action ? null : id,
          clearActivePlugin: plugin.presentation == .action,
          windowMode: .normal,
          pluginPanelVisible: false,
        ),
      );
      return true;
    } catch (error, stack) {
      if (started != null) await _deactivate(started);
      _reportError(error, stack);
      return false;
    }
  }

  Future<void> _deactivate(ManaPluggable plugin) async {
    try {
      await Future<void>.sync(plugin.deactivate);
    } catch (error, stack) {
      _reportError(error, stack);
    }
  }

  /// Preserves sessions and capture when hidden; visibility is not persisted.
  void toggleOverlay({bool? visible}) {
    if (_closed) return;
    final next = visible ?? !_state.overlayVisible;
    if (next == _state.overlayVisible) return;
    _update(_state.copyWith(overlayVisible: next));
  }

  void openPluginPanel() => _update(_state.copyWith(pluginPanelVisible: true));
  void closePluginPanel() =>
      _update(_state.copyWith(pluginPanelVisible: false));
  void togglePluginPanel() =>
      _update(_state.copyWith(pluginPanelVisible: !_state.pluginPanelVisible));

  void minimizeWindow() {
    if (_state.activePluginId == null || _state.windowMode == .minimized) {
      return;
    }
    _restoreMode = _state.windowMode;
    _update(_state.copyWith(windowMode: .minimized));
  }

  void restoreWindow() {
    if (_state.activePluginId != null) {
      _update(_state.copyWith(windowMode: _restoreMode));
    }
  }

  void toggleFullscreen() {
    if (_state.activePluginId == null) return;
    _update(
      _state.copyWith(
        windowMode: _state.windowMode == .fullscreen ? .normal : .fullscreen,
      ),
    );
  }

  Future<void> closePlugin() {
    if (_closed) return Future.value();
    _generation++;
    final id = _state.activePluginId;
    _update(_state.copyWith(clearActivePlugin: true, windowMode: .normal));
    if (id == null) return _sessionWork ?? Future.value();
    return _sessionWork = (_sessionWork ?? Future.value()).then((_) async {
      final plugin = _plugins[id]?.plugin;
      if (plugin == null) return;
      try {
        await Future<void>.sync(plugin.deactivate);
      } catch (error, stack) {
        _reportError(error, stack);
      }
    });
  }

  VoidCallback registerWindow(
    String id, {
    required bool hasBarrier,
    required bool Function() dismissSettings,
  }) {
    final entry = _WindowRegistration(hasBarrier, dismissSettings);
    _windows[id] = entry;
    return () {
      if (identical(_windows[id], entry)) _windows.remove(id);
    };
  }

  bool get canHandleBack {
    if (_closed || !_state.overlayVisible) return false;
    if (_state.pluginPanelVisible) return true;
    final id = _state.activePluginId;
    return id != null &&
        (_state.windowVisible ||
            _plugins[id]?.plugin.presentation == .overlay ||
            (_windows[id]?.hasBarrier ?? false));
  }

  bool handleBack() {
    if (_closed || !_state.overlayVisible) return false;
    if (_state.pluginPanelVisible) {
      if (!(_windows[ManaPluginManager.name]?.dismissSettings() ?? false)) {
        closePluginPanel();
      }
      return true;
    }
    final id = _state.activePluginId;
    if (id == null) return false;
    final window = _windows[id];
    if (window?.dismissSettings() ?? false) return true;
    if (_plugins[id]?.plugin.presentation == .overlay ||
        (_state.windowMode == .minimized && (window?.hasBarrier ?? false))) {
      unawaited(closePlugin());
      return true;
    }
    if (_state.windowVisible) {
      minimizeWindow();
      return true;
    }
    return false;
  }

  void updateSettings({
    double? buttonSize,
    double? buttonOpacity,
    Offset? buttonPosition,
  }) {
    if (!_ready || _closed) return;
    if ((buttonSize != null && !buttonSize.isFinite) ||
        (buttonOpacity != null && !buttonOpacity.isFinite) ||
        (buttonPosition != null &&
            (!buttonPosition.dx.isFinite || !buttonPosition.dy.isFinite))) {
      return;
    }
    final current = _state.settings;
    final next = current.copyWith(
      buttonSize: buttonSize?.clamp(30, 100),
      buttonOpacity: buttonOpacity?.clamp(0.1, 1),
      buttonPosition: buttonPosition,
    );
    if (next.buttonSize == current.buttonSize &&
        next.buttonOpacity == current.buttonOpacity &&
        next.buttonPosition == current.buttonPosition) {
      return;
    }
    _update(_state.copyWith(settings: next));
    _savePending = true;
    _saving ??= _saveSettings();
  }

  Future<void> _saveSettings() async {
    await Future<void>.delayed(.zero);
    try {
      while (_savePending) {
        _savePending = false;
        try {
          await preferences.save(_state.settings);
        } catch (error, stack) {
          _reportError(error, stack);
        }
      }
    } finally {
      _saving = null;
    }
  }

  Future<void> flushSettings() async => await _saving;

  void _update(ManaState state) {
    if (_closed ||
        (state.activePluginId == _state.activePluginId &&
            state.windowMode == _state.windowMode &&
            state.pluginPanelVisible == _state.pluginPanelVisible &&
            state.overlayVisible == _state.overlayVisible &&
            state.settings == _state.settings)) {
      return;
    }
    _state = state;
    notifyListeners();
  }

  Future<void> close() {
    if (!_closed) dispose();
    return _closing!;
  }

  @override
  void dispose() {
    if (_closed) return;
    final active = _state.activePluginId;
    _closed = true;
    _generation++;
    _plugins.removeListener(_registryChanged);
    super.dispose();
    _closing = _shutdown(active);
  }

  Future<void> _shutdown(String? active) async {
    try {
      try {
        await _initialization;
      } catch (_) {
        /* Already reported. */
      }
      await _sessionWork;
      final entry = active == null ? null : _plugins[active];
      if (entry != null) {
        try {
          await Future<void>.sync(entry.plugin.deactivate);
        } catch (error, stack) {
          _reportError(error, stack);
        }
      }
      await _plugins.close();
      await flushSettings();
      await preferences.close();
    } catch (error, stack) {
      _reportError(error, stack);
    } finally {
      _windows.clear();
    }
  }
}
