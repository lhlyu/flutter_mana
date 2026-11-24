import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../runtime/mana_controller.dart';
import '../../runtime/mana_plugin_manager.dart';
import '../../runtime/mana_scope.dart';
import 'enum.dart';

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
    _resize(context);
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
  EdgeInsets _safePadding = .zero;
  EdgeInsets get safePadding => _safePadding;
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

  void update(BuildContext context, {double? height}) {
    final previousHeight = _windowSize.height;
    final previousScreenSize = _screenSize;
    _resize(context, height: height);
    final anchorBottom =
        height != null &&
        position == .bottom &&
        (previousHeight != _windowSize.height ||
            previousScreenSize != _screenSize);
    offset.value = _clamp(
      anchorBottom
          ? Offset(offset.value.dx, _screenSize.height - _windowSize.height)
          : offset.value,
    );
  }

  void _resize(BuildContext context, {double? height}) {
    final media = MediaQuery.of(context);
    final size = media.size;
    var padding = media.padding;
    final root = runtime.rootKey.currentContext?.findRenderObject();
    if (root is RenderBox && root.attached && root.hasSize) {
      final origin = root.localToGlobal(Offset.zero);
      final view = View.of(context);
      final viewport = view.physicalSize / view.devicePixelRatio;
      padding = EdgeInsets.fromLTRB(
        math.max(0, padding.left - origin.dx),
        math.max(0, padding.top - origin.dy),
        math.max(0, padding.right - (viewport.width - origin.dx - size.width)),
        math.max(
          0,
          padding.bottom - (viewport.height - origin.dy - size.height),
        ),
      );
    }
    _screenSize = size;
    _safePadding = EdgeInsets.fromLTRB(
      padding.left.clamp(0, size.width),
      padding.top.clamp(0, size.height),
      padding.right.clamp(0, math.max(0, size.width - padding.left)),
      padding.bottom.clamp(0, math.max(0, size.height - padding.top)),
    );
    final available = Size(
      math.max(0, size.width - _safePadding.horizontal),
      math.max(0, size.height - _safePadding.vertical),
    );
    final width = initialWidth ?? (size.width * 0.6).clamp(300, 600);
    final resolvedHeight = switch (height ?? initialHeight) {
      null => size.height * 0.6,
      final value when value > 0 && value < 1 => size.height * value,
      final value => value,
    };
    _windowSize = Size(
      width.clamp(0, available.width),
      resolvedHeight.clamp(0, available.height),
    );
  }

  Offset _clamp(Offset value) => Offset(
    value.dx.clamp(
      _safePadding.left,
      math.max(
        _safePadding.left,
        _screenSize.width - _safePadding.right - _windowSize.width,
      ),
    ),
    value.dy.clamp(
      _safePadding.top,
      math.max(
        _safePadding.top,
        _screenSize.height - _safePadding.bottom - _windowSize.height,
      ),
    ),
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
