import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../widgets/mana_overlay.dart';
import 'mana_plugin_manager.dart';
import 'mana_store.dart';

/// A global key used to access the root node of the ManaWidget.
///
/// 全局 Key，用于获取 ManaWidget 的根节点。
final GlobalKey manaRootKey = GlobalKey();

Locale manaLocale = Locale('en');

/// Provides the entry point and basic structure for the Mana plugin system.
///
/// 提供了 Mana 插件体系的入口和基础结构。
class ManaWidget extends StatelessWidget {
  /// The child widget of ManaWidget.
  ///
  /// ManaWidget 的子组件。
  final Widget child;

  /// Controls whether ManaWidget is enabled.
  /// If `false`, Mana-related components will not be displayed.
  ///
  /// 控制 ManaWidget 是否启用。
  /// 如果为 `false`，则不显示 Mana 相关的组件。
  final bool enable;

  /// Constructor for creating a ManaWidget instance.
  ///
  /// 构造函数，用于创建 ManaWidget 实例。
  const ManaWidget({super.key, required this.child, this.enable = true});

  /// Initializes the Mana store.
  ///
  /// 初始化 Mana 存储。
  Future<void> _initialize() async {
    await ManaStore.instance.init();
    await ManaPluginManager.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    /// If `enable` is `false`, return the child widget directly without loading Mana-related features.
    ///
    /// 如果 `enable` 为 `false`，则直接返回子组件，不加载 Mana 相关功能。
    if (!enable) {
      return child;
    }

    // Get the platform dispatcher to access locale information for internationalization.
    // 获取平台调度器以访问国际化所需的区域设置信息。
    final platformDispatcher = View.of(context).platformDispatcher;
    // Get the first preferred locale for displaying localized plugin names.
    // 获取第一个首选区域设置，用于显示本地化的插件名称。
    manaLocale = platformDispatcher.locales.first;

    /// 在经过多种方案尝试后，只有在这嵌套一层MaterialApp是侵入性最小、功能完善最好的方案，其他方案多多少少有瑕疵。
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('zh', 'CN')],
      home: Stack(
        children: [
          /// Wraps the child widget with RepaintBoundary and assigns `manaRootKey` to it.
          ///
          /// 使用 RepaintBoundary 包裹子组件，并为其分配 `manaRootKey`。
          RepaintBoundary(key: manaRootKey, child: child),

          /// Uses FutureBuilder to display ManaOverlay after the Mana store is initialized.
          ///
          /// 使用 FutureBuilder 在 Mana 存储初始化完成后显示 ManaOverlay。
          FutureBuilder<void>(
            future: _initialize(),
            builder: (context, snapshot) {
              /// If initialization is not complete, return a shrink-wrapped box to avoid displaying content during loading.
              ///
              /// 如果初始化未完成，则返回一个空盒子，避免在加载时显示内容。
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox.shrink();
              }

              /// After initialization is complete, display the ManaOverlay.
              ///
              /// 初始化完成后，显示 ManaOverlay。
              return const Material(
                type: MaterialType.transparency,
                child: ManaOverlay(),
              );
            },
          ),
        ],
      ),
    );
  }
}
