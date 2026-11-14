import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../runtime/mana_controller.dart';
import '../../runtime/mana_plugin_manager.dart';
import '../../runtime/mana_scope.dart';
import 'enum.dart';

/// Window-local geometry only. Runtime session transitions belong to ManaController.
class FloatingWindowController {
  FloatingWindowController(
    BuildContext context, {
    required this.name,
    this.position = .normal,
    Offset? initialPosition,
    this.initialWidth,
    this.initialHeight,
    bool hasBarrier = false,
  }) : runtime = ManaScope.read(context) {
    _resize(MediaQuery.sizeOf(context));
    final x =
        initialPosition?.dx ?? (_screenSize.width - _windowSize.width) / 2;
    final y = switch (position) {
      .normal =>
        initialPosition?.dy ?? (_screenSize.height - _windowSize.height) / 2,
      .top => 100.0,
      .bottom => _screenSize.height - _windowSize.height,
    };
    offset.value = _clamp(Offset(x, y));
    _unregister = runtime.registerWindow(
      name,
      hasBarrier: hasBarrier,
      dismissSettings: _dismissSettings,
    );
  }

  final ManaController runtime;
  final String name;
  final PositionType position;
  final double? initialWidth;
  final double? initialHeight;
  late final VoidCallback _unregister;
  Size _screenSize = .zero;
  Size _windowSize = .zero;
  bool _closing = false;

  Size get screenSize => _screenSize;
  Size get windowSize => _windowSize;
  bool get isManager => name == ManaPluginManager.name;
  bool get isFullscreen =>
      isManager ? fullscreen.value : runtime.state.windowMode == .fullscreen;
  bool get isVisible => isManager
      ? runtime.state.pluginPanelVisible
      : runtime.state.windowVisible;

  final offset = ValueNotifier(Offset.zero);
  final fullscreen = ValueNotifier(false);
  final showSetting = ValueNotifier(false);

  bool _dismissSettings() {
    if (!showSetting.value) return false;
    showSetting.value = false;
    return true;
  }

  void update(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size == _screenSize) return;
    _resize(size);
    offset.value = _clamp(offset.value);
  }

  void _resize(Size size) {
    _screenSize = size;
    final width = initialWidth ?? (size.width * 0.6).clamp(300, 600);
    final height = switch (initialHeight) {
      null => size.height * 0.6,
      final value when value > 0 && value < 1 => size.height * value,
      final value => value,
    };
    _windowSize = Size(
      width.clamp(0, size.width),
      height.clamp(0, size.height),
    );
  }

  Offset _clamp(Offset value) => Offset(
    value.dx.clamp(0, _screenSize.width - _windowSize.width),
    value.dy.clamp(0, _screenSize.height - _windowSize.height),
  );

  void onPanUpdate(DragUpdateDetails details) =>
      offset.value = _clamp(offset.value + details.delta);
  void onToggleSetting() => showSetting.value = !showSetting.value;

  void onFullscreen() {
    if (isManager) {
      fullscreen.value = !fullscreen.value;
    } else {
      runtime.toggleFullscreen();
    }
  }

  void onMinimize(VoidCallback? callback) {
    callback?.call();
    if (isManager) {
      runtime.closePluginPanel();
    } else {
      runtime.minimizeWindow();
    }
  }

  void onClose(VoidCallback? callback) {
    if (_closing) return;
    _closing = true;
    callback?.call();
    if (isManager) {
      runtime.closePluginPanel();
    } else {
      unawaited(runtime.closePlugin());
    }
  }

  void dispose() {
    _unregister();
    offset.dispose();
    fullscreen.dispose();
    showSetting.dispose();
  }
}
