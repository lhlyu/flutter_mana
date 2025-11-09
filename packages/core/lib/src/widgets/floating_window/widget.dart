import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import '../nil.dart';
import 'controller.dart';
import 'window_controls.dart';

@immutable
class FloatingWindow extends StatefulWidget {
  /// 名称
  final String name;

  /// 内容区域
  final Widget? content;

  /// 遮罩层
  final Widget? barrier;

  /// 设置页组件
  final Widget? setting;

  /// 初始宽度
  final double? initialWidth;

  /// 初始高度
  final double? initialHeight;

  /// 初始位置类型
  final PositionType position;

  /// 自定义初始坐标
  final Offset? initialPosition;

  /// 是否展示控制栏
  final bool showControls;

  /// 是否显示遮罩
  final bool showBarrier;

  /// 主体隐藏时是否保留主体的子树，默认是true - 保留
  final bool maintainContent;

  /// 是否允许拖拽
  final bool drag;

  /// 关闭回调
  final VoidCallback? onClose;

  /// 最小化回调
  final VoidCallback? onMinimize;

  const FloatingWindow({
    super.key,
    required this.name,
    this.content,
    this.barrier,
    this.setting,
    this.initialWidth,
    this.initialHeight,
    this.position = PositionType.normal,
    this.initialPosition,
    this.showControls = true,
    this.showBarrier = true,
    this.maintainContent = true,
    this.drag = true,
    this.onClose,
    this.onMinimize,
  });

  @override
  State<FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<FloatingWindow> {
  late final FloatingWindowController _controller;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      _controller.update(context);
      return;
    }
    _controller = FloatingWindowController(
      context,
      name: widget.name,
      position: widget.position,
      initialPosition: widget.initialPosition,
      initialWidth: widget.initialWidth,
      initialHeight: widget.initialHeight,
    );
    _initialized = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 构建barrier
  Widget _buildBarrier() {
    return widget.barrier ??
        GestureDetector(
          onTap: () => _controller.onMinimize(widget.showBarrier, widget.onMinimize),
          behavior: HitTestBehavior.opaque,
          child: Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
        );
  }

  Widget _buildContent(Size screenSize, Size windowSize, bool fullscreen) {
    final radius =
        (fullscreen || widget.initialHeight == double.infinity) ? BorderRadius.zero : BorderRadius.circular(8);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 16, spreadRadius: 0, offset: const Offset(0, 0)),
        ],
      ),
      child: SafeArea(
        left: fullscreen,
        top: fullscreen || widget.initialHeight == double.infinity,
        right: fullscreen,
        bottom: fullscreen || widget.position == PositionType.bottom,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showControls)
              WindowControls(
                drag: widget.drag,
                isFullscreen: fullscreen,
                showSettingButton: widget.setting != null,
                onPanUpdate: _controller.onPanUpdate,
                onToggleSetting: _controller.onToggleSetting,
                onFullscreen: _controller.onFullscreen,
                onMinimize: () => _controller.onMinimize(widget.showBarrier, widget.onMinimize),
                onClose: () => _controller.onClose(widget.onClose),
              ),
            Expanded(
              child: Stack(
                children: [
                  widget.content ?? SizedBox(),
                  Positioned.fill(
                    child: ValueListenableBuilder(
                      valueListenable: _controller.showSetting,
                      builder: (context, showSetting, _) {
                        if (showSetting && widget.setting != null) {
                          return ColoredBox(color: Colors.white, child: widget.setting ?? SizedBox.shrink());
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 拦截返回
      onPopInvokedWithResult: (bool didPop, void result) {
        if (!didPop) {
          if (_controller.manaState.activePluginName.value == widget.name &&
              _controller.manaState.pluginManagementPanelVisible.value) {
            return;
          }

          if (_controller.manaState.pluginManagementPanelVisible.value) {
            _controller.manaState.pluginManagementPanelVisible.value = false;
            return;
          }

          if (widget.content == null) {
            _controller.manaState.activePluginName.value = '';
            _controller.manaState.activePluginPanelVisible.value = false;
            _controller.manaState.floatingButtonVisible.value = true;
            return;
          }

          if (!_controller.manaState.floatWindowMainVisible.value || !widget.showBarrier) {
            _controller.manaState.activePluginPanelVisible.value = false;
            if (widget.showBarrier) {
              return;
            }
          }
          _controller.manaState.floatWindowMainVisible.value = false;
          _controller.manaState.floatingButtonVisible.value = true;
        }
      },
      child: Stack(
        children: [
          if (widget.showBarrier) _buildBarrier(),
          if (widget.content != null)
            AnimatedBuilder(
              animation: Listenable.merge([
                _controller.manaState.floatWindowMainVisible,
                _controller.fullscreen,
                _controller.offset,
              ]), // 合并多个 ValueListenable
              builder: (context, _) {
                final visible = _controller.manaState.floatWindowMainVisible.value;
                final fullscreen = _controller.fullscreen.value;
                final offset = _controller.offset.value;
                final double currentLeft = fullscreen ? 0 : offset.dx;
                final double currentTop = fullscreen ? 0 : offset.dy;
                final double currentWidth = fullscreen ? _controller.screenSize.width : _controller.windowSize.width;
                final double currentHeight = fullscreen ? _controller.screenSize.height : _controller.windowSize.height;
                return Positioned(
                  left: currentLeft,
                  top: currentTop,
                  width: currentWidth,
                  height: currentHeight,
                  child: Visibility(
                    visible: visible,
                    replacement: nil,
                    maintainState: widget.maintainContent,
                    maintainAnimation: widget.maintainContent,
                    child: _buildContent(_controller.screenSize, _controller.windowSize, fullscreen),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
