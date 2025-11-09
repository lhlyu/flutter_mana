import 'package:flutter/material.dart';

// ignore_for_file: constant_identifier_names

abstract final class _Icons {
  static const fullscreen = Icons.fullscreen;
  static const fullscreen_exit = Icons.fullscreen_exit;
  static const minimize = Icons.remove;
  static const settings = Icons.settings;
  static const close = Icons.close;
}

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

  /// 统一 IconButton 构造
  Widget _buildIconButton({required IconData icon, required VoidCallback? onPressed, String? tooltip}) {
    return IconButton(
      icon: Icon(icon, size: 16),
      color: Colors.black54,
      tooltip: tooltip,
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                _buildIconButton(
                  icon: widget.isFullscreen ? _Icons.fullscreen_exit : _Icons.fullscreen,
                  tooltip: widget.isFullscreen ? '退出全屏' : '全屏',
                  onPressed: widget.onFullscreen,
                ),
                _buildIconButton(icon: _Icons.minimize, tooltip: '最小化', onPressed: widget.onMinimize),
              ],
            ),
          ),
          if (widget.drag && !widget.isFullscreen)
            Expanded(
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _isHandlePressed = true;
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _isHandlePressed = false;
                  });
                },
                onPanUpdate: (details) {
                  if (!_isHandlePressed) {
                    return;
                  }
                  widget.onPanUpdate(details);
                },
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: _DragHandle(isPressed: _isHandlePressed),
                ),
              ),
            ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Visibility(
                  visible: widget.showSettingButton,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: _buildIconButton(icon: _Icons.settings, tooltip: '设置', onPressed: widget.onToggleSetting),
                ),
                _buildIconButton(icon: _Icons.close, tooltip: '关闭', onPressed: widget.onClose),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
        color: isPressed ? Theme.of(context).primaryColor : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(isPressed ? 3 : 2),
      ),
    );
  }
}
