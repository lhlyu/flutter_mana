import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../mana_button.dart';
import '../mana_icon.dart';
import '../mana_style.dart';

@immutable
class WindowControls extends StatefulWidget {
  /// 是否启用拖动把手
  final bool drag;

  /// 当前是否处于全屏状态
  final bool isFullscreen;

  /// 是否显示设置按钮
  final bool showSettingButton;

  /// 拖动中位移回调
  final GestureDragUpdateCallback onPanUpdate;

  /// 设置按钮点击回调
  final VoidCallback onToggleSetting;

  /// 全屏 / 退出全屏 回调
  final VoidCallback onFullscreen;

  /// 最小化回调
  final VoidCallback onMinimize;

  /// 关闭窗口回调
  final VoidCallback onClose;

  const WindowControls({
    super.key,
    required this.drag,
    required this.isFullscreen,
    required this.showSettingButton,
    required this.onPanUpdate,
    required this.onToggleSetting,
    required this.onFullscreen,
    required this.onMinimize,
    required this.onClose,
  });

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> {
  bool _isHandlePressed = false;

  Widget _buildIconButton({
    required ManaSymbol icon,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    return ManaButton(
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onPressed,
      child: ManaIcon(icon),
    );
  }

  Widget _buildHandle() => GestureDetector(
    onPanStart: (_) => setState(() => _isHandlePressed = true),
    onPanEnd: (_) => setState(() => _isHandlePressed = false),
    onPanCancel: () => setState(() => _isHandlePressed = false),
    onPanUpdate: widget.onPanUpdate,
    child: Container(
      color: ManaStyle.transparent,
      alignment: .center,
      child: _DragHandle(isPressed: _isHandlePressed),
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    padding: const .symmetric(horizontal: 8),
    color: ManaStyle.surface,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final showHandle =
            widget.drag && !widget.isFullscreen && constraints.maxWidth >= 184;
        // 极窄窗口允许横向滚动控制栏，而不是让按钮溢出。
        return SingleChildScrollView(
          scrollDirection: .horizontal,
          child: SizedBox(
            width: math.max(128, constraints.maxWidth),
            child: Row(
              children: [
                _buildIconButton(
                  icon: widget.isFullscreen ? .exitFullscreen : .fullscreen,
                  tooltip: widget.isFullscreen ? '退出全屏' : '全屏',
                  onPressed: widget.onFullscreen,
                ),
                _buildIconButton(
                  icon: .minimize,
                  tooltip: '最小化',
                  onPressed: widget.onMinimize,
                ),
                Expanded(
                  child: showHandle ? _buildHandle() : const SizedBox.shrink(),
                ),
                Visibility(
                  visible: widget.showSettingButton,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: _buildIconButton(
                    icon: .settings,
                    tooltip: '设置',
                    onPressed: widget.onToggleSetting,
                  ),
                ),
                _buildIconButton(
                  icon: .close,
                  tooltip: '关闭',
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// 拖动把手视觉
class _DragHandle extends StatelessWidget {
  final bool isPressed;

  const _DragHandle({required this.isPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: isPressed ? 6 : 4,
      width: isPressed ? 60 : 50,
      decoration: BoxDecoration(
        color: isPressed ? ManaStyle.accent : ManaStyle.border,
        borderRadius: .circular(isPressed ? 3 : 2),
      ),
    );
  }
}
