import 'package:flutter/foundation.dart';

import '../storage/mana_settings.dart';

enum ManaWindowMode { normal, minimized, fullscreen }

@immutable
final class ManaState {
  final String? activePluginId;
  final ManaWindowMode windowMode;
  final bool pluginPanelVisible;
  final bool overlayVisible;
  final ManaSettings settings;

  const ManaState({
    this.activePluginId,
    this.windowMode = .normal,
    this.pluginPanelVisible = false,
    this.overlayVisible = true,
    this.settings = const ManaSettings(),
  });

  bool get windowVisible => activePluginId != null && windowMode != .minimized;
  bool get floatingButtonVisible =>
      windowMode != .fullscreen || pluginPanelVisible;

  ManaState copyWith({
    String? activePluginId,
    bool clearActivePlugin = false,
    ManaWindowMode? windowMode,
    bool? pluginPanelVisible,
    bool? overlayVisible,
    ManaSettings? settings,
  }) => ManaState(
    activePluginId: clearActivePlugin
        ? null
        : activePluginId ?? this.activePluginId,
    windowMode: windowMode ?? this.windowMode,
    pluginPanelVisible: pluginPanelVisible ?? this.pluginPanelVisible,
    overlayVisible: overlayVisible ?? this.overlayVisible,
    settings: settings ?? this.settings,
  );
}
