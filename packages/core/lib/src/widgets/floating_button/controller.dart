import 'package:flutter/cupertino.dart';
import 'package:flutter_mana/flutter_mana.dart';

// 左右最小留边
const double _minMarginH = 10;
// 上下最小留边
const double _minMarginV = 60;
// 底部附加安全距离
const double _bottomSafe = 100;

class FloatingButtonController extends ChangeNotifier {
  FloatingButtonController(BuildContext context) {
    _init(context);
  }

  late ManaState _state;
  late Size _windowSize;
  late double _buttonSize;

  ValueNotifier<Offset> offset = ValueNotifier(Offset.zero);

  ManaState get state => _state;

  // 初始化：读窗口大小、按钮尺寸、历史位置
  void _init(BuildContext context) {
    _state = ManaScope.of(context);
    _windowSize = MediaQuery.sizeOf(context);

    // 监听尺寸/透明度变化
    _state.floatingButtonSize.addListener(_onMetricsChanged);
    _buttonSize = _state.floatingButtonSize.value;

    _restorePosition();
  }

  void updateContext(BuildContext context) {
    _state = ManaScope.of(context);
    _windowSize = MediaQuery.sizeOf(context);
    _restorePosition();
  }

  void _onMetricsChanged() {
    _buttonSize = _state.floatingButtonSize.value;
    _clampAndUpdate();
  }

  Future<void> _restorePosition() async {
    final (x, y) = ManaStore.instance.getFloatActionButtonPosition();
    final maxX = _windowSize.width - _buttonSize;
    final maxY = _windowSize.height - _buttonSize;

    offset.value =
        (x > 0 && y > 0 && x < _windowSize.width && y < _windowSize.height)
            ? Offset(x, y)
            : Offset(maxX - _minMarginH, maxY - _bottomSafe);
    _clampAndUpdate();
  }

  // 边界吸附
  void _clampAndUpdate() {
    final maxX = _windowSize.width - _buttonSize;
    final maxY = _windowSize.height - _buttonSize;

    double x = offset.value.dx + _buttonSize / 2 < _windowSize.width / 2 ? _minMarginH : maxX - _minMarginH;

    double y = offset.value.dy.clamp(_minMarginV, maxY - _minMarginV);

    offset.value = Offset(x, y);
  }

  // 拖拽
  void handleDragUpdate(DragUpdateDetails d) {
    offset.value = Offset(d.globalPosition.dx - _buttonSize / 2, d.globalPosition.dy - _buttonSize / 2);
  }

  void handleDragEnd(DragEndDetails _) {
    _clampAndUpdate();
    ManaStore.instance.setFloatActionButtonPosition(offset.value.dx, offset.value.dy);
  }

  // 点击
  void onTap() {
    // 让软键盘隐藏、复制选中取消
    if (manaRootKey.currentContext != null) {
      FocusScope.of(manaRootKey.currentContext!).unfocus();
    }

    // 如果插件激活 且 浮动窗口主体不可见
    if (_state.activePluginName.value.isNotEmpty && !_state.floatWindowMainVisible.value) {
      _state.floatWindowMainVisible.value = true;
      _state.activePluginPanelVisible.value = true;
      // 如果处于全屏状态，则隐藏浮动按钮
      if (_state.floatWindowMainFullscreen.value) {
        _state.floatingButtonVisible.value = false;
      }
    } else {
      _state.pluginManagementPanelVisible.value = !_state.pluginManagementPanelVisible.value;
    }
  }

  @override
  void dispose() {
    _state.floatingButtonSize.removeListener(_onMetricsChanged);
    super.dispose();
  }
}
