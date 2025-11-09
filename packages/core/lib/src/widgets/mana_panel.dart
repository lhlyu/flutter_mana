import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

/// A widget that displays a grid of available Mana plugins, allowing users to select and trigger them.
///
/// 一个显示可用 Mana 插件网格的小部件，允许用户选择并触发它们。
class ManaPanel extends StatelessWidget {
  /// Creates a [ManaPanel].
  ///
  /// 创建一个 [ManaPanel]。
  const ManaPanel({super.key});

  /// The standard size for plugin icons within the panel.
  ///
  /// 面板中插件图标的标准尺寸。
  static const double iconSize = 40;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Access the ManaState from the context to manage plugin activation.
        // 从上下文中获取 ManaState 以管理插件激活。
        final manaState = ManaScope.of(context);

        // Get the ManaPluginManager instance to access registered plugins.
        // 获取 ManaPluginManager 实例以访问已注册的插件。
        final mm = ManaPluginManager.instance;

        // Calculate the number of columns for the grid based on available width.
        // 根据可用宽度计算网格的列数。
        final crossAxisCount = (constraints.maxWidth * 0.56 / iconSize).floor();

        return GridView.count(
          crossAxisCount: crossAxisCount,
          padding: const EdgeInsets.all(8),
          crossAxisSpacing: 0,
          mainAxisSpacing: 4,
          childAspectRatio: 0.9,
          children:
              mm.pluginsMap.entries.map((entry) {
                final plugin = entry.value;

                return InkWell(
                  onTap:
                      plugin.isSupported
                          ? () {
                            // Set the tapped plugin as the active one.
                            // 将点击的插件设置为活动插件。
                            manaState.activePluginName.value = plugin.name;

                            manaState.activePluginPanelVisible.value = true;

                            // Hide the plugin management panel after a plugin is selected.
                            // 选择插件后隐藏插件管理面板。
                            manaState.pluginManagementPanelVisible.value = false;

                            // Trigger the main logic of the plugin.
                            // 触发插件的主要逻辑。
                            plugin.onTrigger();
                          }
                          : null,
                  // Build the visual representation of the plugin item.
                  // 构建插件项的可视化表示。
                  child: _buildPluginItem(plugin, manaState.activePluginName.value == plugin.name),
                );
              }).toList(),
        );
      },
    );
  }

  /// Builds a single visual item for a plugin in the grid.
  ///
  /// 为网格中的插件构建单个可视化项。
  ///
  /// [plugin]: The [ManaPluggable] instance to display.
  /// [plugin]: 要显示的 [ManaPluggable] 实例。
  /// [active]: A boolean indicating if this plugin is currently active.
  /// [active]: 指示此插件当前是否活动的布尔值。
  Widget _buildPluginItem(ManaPluggable plugin, bool active) {
    var style = const TextStyle(fontSize: 10);
    final isSupported = plugin.isSupported;

    if (active) {
      style = const TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold);
    }

    // 图标 Widget
    Widget icon = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: iconSize,
        height: iconSize,
        child: Image(image: plugin.iconImageProvider, width: iconSize, height: iconSize, fit: BoxFit.cover),
      ),
    );

    // 不支持时加禁用遮罩
    if (!isSupported) {
      icon = Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.do_disturb_alt_rounded, color: Colors.red, size: iconSize),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 4,
      children: [
        icon,
        Text(
          plugin.getLocalizedDisplayName(manaLocale),
          style: style,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
