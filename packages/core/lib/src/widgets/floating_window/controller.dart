import 'package:flutter/cupertino.dart';
import 'package:flutter_mana/flutter_mana.dart';

class FloatingWindowController extends ChangeNotifier {
  FloatingWindowController(
    BuildContext context, {
    String name = '',
    PositionType position = PositionType.normal,
    Offset? initialPosition,
    double? initialWidth,
    double? initialHeight,
  }) {
    _name = name;
    _position = position;
    _initialPosition = initialPosition;
    _initialWidth = initialWidth;
    _initialHeight = initialHeight;
    _init(context);
  }

  late ManaState _manaState;

  ManaState get manaState => _manaState;

  String _name = '';
  Size _screenSize = Size.zero;

  Size get screenSize => _screenSize;

  Size _windowSize = Size.zero;

  Size get windowSize => _windowSize;

  PositionType _position = PositionType.normal;
  Offset? _initialPosition;
  double? _initialWidth;
  double? _initialHeight;

  /// 浮动窗口位置
  final offset = ValueNotifier(Offset.zero);

  /// 全屏
  final fullscreen = ValueNotifier(false);

  /// 关闭
  final closing = ValueNotifier(false);

  /// 展示设置
  final showSetting = ValueNotifier(false);

  void _init(BuildContext context) {
    _manaState = ManaScope.of(context);
    _calculateInitialPosition(context);
  }

  void update(BuildContext context) {
    _calculateInitialPosition(context);
  }

  @override
  void dispose() {
    offset.dispose();
    fullscreen.dispose();
    closing.dispose();
    showSetting.dispose();
    super.dispose();
  }

  Size _getWindowActualSize() {
    double width = _initialWidth ?? 0;
    if (_initialWidth == null) {
      width = (_screenSize.width * 0.6).clamp(300, 600);
    } else if (_initialWidth == double.infinity) {
      width = _screenSize.width;
    }
    if (width > _screenSize.width) {
      width = _screenSize.width;
    }

    double height = _initialHeight ?? 0;
    if (_initialHeight == null) {
      height = _screenSize.height * 0.6;
    } else if (_initialHeight == double.infinity) {
      height = _screenSize.height;
    } else if (_initialHeight != null && _initialHeight! > 0 && _initialHeight! < 1) {
      height = _screenSize.height * _initialHeight!;
    }
    if (height > _screenSize.height) {
      height = _screenSize.height;
    }

    return Size(width, height);
  }

  void _calculateInitialPosition(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    _windowSize = _getWindowActualSize();

    final dx = _initialPosition?.dx ?? (_screenSize.width - _windowSize.width) / 2;
    double dy = 0;

    switch (_position) {
      case PositionType.normal:
        dy = _initialPosition?.dy ?? (_screenSize.height - _windowSize.height) / 2;

      case PositionType.top:
        dy = 100;

      case PositionType.bottom:
        dy = _screenSize.height - _windowSize.height;
    }

    offset.value = Offset(dx, dy);
  }

  void onPanUpdate(DragUpdateDetails details) {
    final dx = (offset.value.dx + details.delta.dx).clamp(0.0, screenSize.width - windowSize.width);
    final dy = (offset.value.dy + details.delta.dy).clamp(0.0, screenSize.height - windowSize.height);
    offset.value = Offset(dx, dy);
  }

  void onToggleSetting() {
    showSetting.value = !showSetting.value;
  }

  void onFullscreen() {
    fullscreen.value = !fullscreen.value;
    if (_name != ManaPluginManager.name) {
      _manaState.floatingButtonVisible.value = !fullscreen.value;
    }
    _manaState.floatWindowMainFullscreen.value = fullscreen.value;
  }

  void onMinimize(VoidCallback? callback) {
    callback?.call();
    if (_name == ManaPluginManager.name) {
      _manaState.pluginManagementPanelVisible.value = false;
    } else {
      _manaState.floatWindowMainVisible.value = false;
    }
    _manaState.floatingButtonVisible.value = true;
  }

  void onClose(VoidCallback? callback) async {
    if (closing.value) {
      return;
    }
    closing.value = true;
    callback?.call();
    if (_name == ManaPluginManager.name) {
      _manaState.pluginManagementPanelVisible.value = false;
    }
    _manaState.activePluginName.value = '';
    _manaState.floatingButtonVisible.value = true;
  }
}
