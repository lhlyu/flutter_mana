import 'dart:async';

import 'package:flutter/foundation.dart';

import 'mana_pluggable.dart';
import 'mana_error.dart';

enum ManaPluginStatus { pending, initializing, ready, unsupported, failed }

@immutable
final class ManaPluginInfo {
  final ManaPluggable plugin;
  final ManaPluginStatus status;
  final Object? error;
  final StackTrace? stackTrace;

  const ManaPluginInfo(this.plugin, this.status, {this.error, this.stackTrace});
}

/// Observable read-only view. Runtime mutations go through ManaController.
abstract interface class ManaPluginRegistry implements Listenable {
  List<ManaPluginInfo> get entries;
  Map<String, ManaPluggable> get pluginsMap;
  ManaPluginInfo? operator [](String id);
}

class _PluginEntry {
  final ManaPluggable plugin;
  ManaPluginStatus status;
  Object? error;
  StackTrace? stack;
  Future<void>? initialization;

  _PluginEntry(this.plugin)
    : status = plugin.isSupported ? .pending : .unsupported;

  ManaPluginInfo get info =>
      ManaPluginInfo(plugin, status, error: error, stackTrace: stack);
}

/// Instance-owned, observable registry. A plugin failure does not fail its peers.
final class ManaPluginManager extends ChangeNotifier
    implements ManaPluginRegistry {
  static const name = 'mana_plugin_manager';
  final void Function(Object error, StackTrace stack)? onError;
  final _entries = <String, _PluginEntry>{};
  bool _started = false;
  bool _closed = false;
  Future<void>? _closing;

  ManaPluginManager({this.onError});

  @override
  List<ManaPluginInfo> get entries =>
      List.unmodifiable(_entries.values.map((entry) => entry.info));
  @override
  Map<String, ManaPluggable> get pluginsMap => Map.unmodifiable({
    for (final entry in _entries.entries) entry.key: entry.value.plugin,
  });
  @override
  ManaPluginInfo? operator [](String id) => _entries[id]?.info;

  void register(ManaPluggable plugin) {
    if (_closed) throw StateError('Registry is closed.');
    final id = plugin.name;
    if (id.trim().isEmpty || id == name) {
      throw ArgumentError.value(id, 'plugin.name');
    }
    if (_entries.containsKey(id)) throw StateError('Duplicate plugin: $id');
    final entry = _PluginEntry(plugin);
    _entries[id] = entry;
    notifyListeners();
    if (_started) unawaited(_initializeEntry(entry));
  }

  void registerAll(Iterable<ManaPluggable> plugins) {
    for (final plugin in plugins) {
      register(plugin);
    }
  }

  Future<void> initialize() async {
    if (_closed) throw StateError('Registry is closed.');
    _started = true;
    await Future.wait(_entries.values.toList().map(_initializeEntry));
  }

  Future<void> ensureReady(String id) async {
    final entry = _entries[id] ?? (throw StateError('Unknown plugin: $id'));
    await _initializeEntry(entry);
    if (_closed || !identical(_entries[id], entry) || entry.status != .ready) {
      throw StateError('Plugin is not available: $id (${entry.status.name})');
    }
  }

  Future<void> retryInitialization(String id) async {
    if (_closed) throw StateError('Registry is closed.');
    final entry = _entries[id] ?? (throw StateError('Unknown plugin: $id'));
    if (entry.status == .failed) {
      entry.initialization = null;
      entry.error = null;
      entry.stack = null;
      entry.status = .pending;
    }
    await ensureReady(id);
  }

  Future<void> _initializeEntry(_PluginEntry entry) {
    if (entry.status == .unsupported) return Future.value();
    return entry.initialization ??= Future.microtask(
      () => _runInitialization(entry),
    );
  }

  Future<void> _runInitialization(_PluginEntry entry) async {
    entry.status = .initializing;
    if (!_closed) notifyListeners();
    try {
      await Future<void>.sync(entry.plugin.initialize);
      entry.status = .ready;
    } catch (error, stack) {
      entry.status = .failed;
      entry.error = error;
      entry.stack = stack;
      reportManaError(error, stack, onError);
    }
    if (!_closed && identical(_entries[entry.plugin.name], entry)) {
      notifyListeners();
    }
  }

  Future<void> unregister(String id) async {
    if (_closed) throw StateError('Registry is closed.');
    final entry = _entries.remove(id);
    if (entry == null) return;
    notifyListeners();
    await _disposeEntry(entry);
  }

  Future<void> _disposeEntry(_PluginEntry entry) async {
    await entry.initialization;
    try {
      await Future<void>.sync(entry.plugin.dispose);
    } catch (error, stack) {
      reportManaError(error, stack, onError);
    }
  }

  Future<void> close() {
    if (!_closed) dispose();
    return _closing!;
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    final entries = _entries.values.toList();
    _entries.clear();
    super.dispose();
    _closing = Future.wait(entries.map(_disposeEntry)).then((_) {});
  }
}
