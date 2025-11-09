import 'dart:collection';

import 'package:flutter/cupertino.dart';

import 'mana_pluggable.dart';

/// Manages the registration and access of Mana pluggable components.
/// This class follows the Singleton pattern to ensure a single instance throughout the application.
///
/// 管理 Mana 可插拔组件的注册和访问。
/// 此类遵循单例模式，以确保在整个应用程序中只有一个实例。
class ManaPluginManager {
  /// The unique name for this manager.
  ///
  /// 此管理器的唯一名称。
  static const String name = 'mana_plugin_manager';

  /// The single instance of [ManaPluginManager].
  ///
  /// [ManaPluginManager] 的单一实例。
  static ManaPluginManager? _instance;

  /// Returns an unmodifiable map of registered plugins, keyed by their names.
  ///
  /// 返回一个以插件名称为键的、不可修改的已注册插件映射。
  LinkedHashMap<String, ManaPluggable> get pluginsMap => _pluginsMap;

  /// The internal map storing registered plugins.
  ///
  /// 存储已注册插件的内部映射。
  final LinkedHashMap<String, ManaPluggable> _pluginsMap =
      LinkedHashMap<String, ManaPluggable>();

  /// Provides the singleton instance of [ManaPluginManager].
  /// If the instance does not exist, it will be created.
  ///
  /// 提供 [ManaPluginManager] 的单例实例。
  /// 如果实例不存在，则会创建它。
  static ManaPluginManager get instance {
    _instance ??= ManaPluginManager._();
    return _instance!;
  }

  /// Private constructor to enforce the Singleton pattern.
  ///
  /// 私有构造函数，用于强制执行单例模式。
  ManaPluginManager._();

  /// Registers a single [ManaPluggable] plugin.
  /// The plugin will be registered using its `name` property as the key.
  /// Plugins with an empty name will not be registered.
  ///
  /// 注册一个 [ManaPluggable] 插件。
  /// 插件将使用其 `name` 属性作为键进行注册。
  /// 名称为空的插件将不会被注册。
  void register(ManaPluggable plugin) {
    if (plugin.name.isEmpty) {
      return;
    }

    _pluginsMap[plugin.name] = plugin;
  }

  /// Registers a list of [ManaPluggable] plugins.
  /// Iterates through the list and calls `register` for each plugin.
  ///
  /// 注册一个 [ManaPluggable] 插件列表。
  /// 遍历列表并为每个插件调用 `register` 方法。
  void registerAll(List<ManaPluggable> plugins) {
    for (final plugin in plugins) {
      register(plugin);
    }
  }

  Future<void> initialize() async {
    final List<Future<void>> initializationFutures = [];

    pluginsMap.forEach((name, plugin) {
      initializationFutures.add(plugin.initialize());
    });

    try {
      await Future.wait(initializationFutures);
    } catch (e) {
      debugPrint('Plugin initialization failed: $e');
    }
  }
}
