import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'floating_button/index.dart';
import 'mana_panel.dart';
import 'mana_setting_panel.dart';
import 'nil.dart';

/// A widget that manages and displays various Mana components as an overlay.
/// This includes the active plugin's widget, the plugin management panel, and the float action button.
///
/// 一个管理和显示各种 Mana 组件作为浮层的小部件。
/// 这包括活动插件的部件、插件管理面板和浮动操作按钮。
class ManaOverlay extends StatefulWidget {
  /// Creates a [ManaOverlay].
  ///
  /// 创建一个 [ManaOverlay]。
  const ManaOverlay({super.key});

  @override
  State<ManaOverlay> createState() => _ManaOverlayState();
}

class _ManaOverlayState extends State<ManaOverlay> with WidgetsBindingObserver {
  /// The state object for Mana, which must be preserved using a StatefulWidget.
  ///
  /// Mana 的状态对象，必须使用 StatefulWidget 进行状态保存。
  final ManaState _manaState = ManaStore.instance.getManaState();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  Future<bool> didPopRoute() async {
    if ((await manaNavigatorKey.currentState?.maybePop()) ?? false) {
      return true;
    }
    if (_manaState.pluginManagementPanelVisible.value) {
      _manaState.pluginManagementPanelVisible.value = false;
      return true;
    }
    if (_manaState.floatWindowMainVisible.value) {
      _manaState.floatWindowMainVisible.value = false;
      _manaState.floatingButtonVisible.value = true;
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manaState.dispose();
    super.dispose();
  }

  /// Builds the stack of overlay widgets.
  ///
  /// 构建覆盖层小部件的堆栈。
  Widget _buildStack() {
    return Builder(
      builder: (BuildContext context) {
        // Access the ManaState from the context.
        // 从上下文中获取 ManaState。
        final manaState = ManaScope.of(context);

        return Stack(
          alignment: Alignment.center,
          children: [
            ValueListenableBuilder(
              valueListenable: manaState.activePluginName,
              builder: (context, value, _) {
                final currentActivatedPluginWidget =
                    ManaPluginManager.instance.pluginsMap[manaState.activePluginName.value]?.buildWidget(context);
                return currentActivatedPluginWidget ?? nilPosition;
              },
            ),
            ValueListenableBuilder(
              valueListenable: manaState.pluginManagementPanelVisible,
              builder: (context, value, _) {
                return value
                    ? ManaFloatingWindow(
                        name: ManaPluginManager.name,
                        content: ManaPanel(),
                        setting: ManaSettingPanel(),
                      )
                    : nilPosition;
              },
            ),
            ValueListenableBuilder(
              valueListenable: manaState.floatingButtonVisible,
              builder: (context, value, _) {
                return value ? const FloatingButton() : nilPosition;
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ManaScope(
      state: _manaState,
      child: _buildStack(),
    );
  }
}
