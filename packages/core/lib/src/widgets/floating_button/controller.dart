import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../runtime/mana_controller.dart';
import '../../runtime/mana_scope.dart';

class FloatingButtonController {
  FloatingButtonController(BuildContext context)
    : runtime = ManaScope.read(context),
      _windowSize = MediaQuery.sizeOf(context) {
    _lastButtonSize = _buttonSize;
    runtime.addListener(_settingsChanged);
    offset.value =
        runtime.state.settings.buttonPosition ??
        Offset(
          _windowSize.width - _buttonSize - 10,
          _windowSize.height - _buttonSize - 100,
        );
    _clampAndUpdate();
  }

  final ManaController runtime;
  Size _windowSize;
  late double _lastButtonSize;
  final offset = ValueNotifier(Offset.zero);
  double get _buttonSize => runtime.state.settings.buttonSize;

  void updateContext(BuildContext context) {
    _windowSize = MediaQuery.sizeOf(context);
    _clampAndUpdate();
  }

  void _settingsChanged() {
    if (_buttonSize == _lastButtonSize) return;
    _lastButtonSize = _buttonSize;
    _clampAndUpdate();
  }

  void _clampAndUpdate() {
    final maxX = math.max(0.0, _windowSize.width - _buttonSize);
    final maxY = math.max(0.0, _windowSize.height - _buttonSize);
    final marginH = math.min(10.0, maxX / 2);
    final marginV = math.min(60.0, maxY / 2);
    final x = offset.value.dx + _buttonSize / 2 < _windowSize.width / 2
        ? marginH
        : maxX - marginH;
    offset.value = Offset(x, offset.value.dy.clamp(marginV, maxY - marginV));
  }

  void handleDragUpdate(DragUpdateDetails details) =>
      offset.value += details.delta;

  void handleDragEnd(DragEndDetails _) {
    _clampAndUpdate();
    runtime.updateSettings(buttonPosition: offset.value);
  }

  void onTap() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (runtime.state.activePluginId != null &&
        runtime.state.windowMode == .minimized) {
      runtime.restoreWindow();
    } else {
      runtime.togglePluginPanel();
    }
  }

  void dispose() {
    runtime.removeListener(_settingsChanged);
    offset.dispose();
  }
}
