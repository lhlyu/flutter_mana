import 'package:flutter/widgets.dart';

import '../../runtime/mana_scope.dart';
import 'enum.dart';

import '../mana_style.dart';
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
  FloatingWindowController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller case final controller?) {
      controller.update(context);
    } else {
      _controller = FloatingWindowController(
        context,
        name: widget.name,
        position: widget.position,
        initialPosition: widget.initialPosition,
        initialWidth: widget.initialWidth,
        initialHeight: widget.initialHeight,
        hasBarrier: widget.barrier != null || widget.content == null,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _content(FloatingWindowController controller) {
    final fullscreen = controller.isFullscreen;
    return Container(
      clipBehavior: .antiAlias,
      decoration: BoxDecoration(
        color: ManaStyle.surface,
        borderRadius: fullscreen || widget.initialHeight == double.infinity
            ? .zero
            : .circular(8),
        boxShadow: const [BoxShadow(color: ManaStyle.shadow, blurRadius: 16)],
      ),
      child: SafeArea(
        left: fullscreen,
        top: fullscreen || widget.initialHeight == double.infinity,
        right: fullscreen,
        bottom: fullscreen || widget.position == .bottom,
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              if (widget.showControls)
                SizedBox(
                  height: constraints.maxHeight.clamp(0, 40),
                  child: WindowControls(
                    drag: widget.drag,
                    isFullscreen: fullscreen,
                    showSettingButton: widget.setting != null,
                    onPanUpdate: controller.onPanUpdate,
                    onToggleSetting: controller.onToggleSetting,
                    onFullscreen: controller.onFullscreen,
                    onMinimize: () => controller.onMinimize(widget.onMinimize),
                    onClose: () => controller.onClose(widget.onClose),
                  ),
                ),
              Expanded(
                child: Stack(
                  fit: .expand,
                  children: [
                    widget.content ?? const SizedBox.shrink(),
                    if (controller.showSetting.value && widget.setting != null)
                      ColoredBox(
                        color: ManaStyle.surface,
                        child: widget.setting!,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ManaScope.of(context);
    final controller = _controller!;
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.offset,
        controller.fullscreen,
        controller.showSetting,
      ]),
      builder: (context, _) {
        final fullscreen = controller.isFullscreen;
        final visible = controller.isVisible;
        return Stack(
          children: [
            if (widget.showBarrier && (visible || widget.barrier != null))
              widget.barrier ??
                  GestureDetector(
                    behavior: .opaque,
                    onTap: () => controller.onMinimize(widget.onMinimize),
                    child: const SizedBox.expand(),
                  ),
            if (widget.content != null)
              Positioned(
                left: fullscreen ? 0 : controller.offset.value.dx,
                top: fullscreen ? 0 : controller.offset.value.dy,
                width: fullscreen
                    ? controller.screenSize.width
                    : controller.windowSize.width,
                height: fullscreen
                    ? controller.screenSize.height
                    : controller.windowSize.height,
                child: Visibility(
                  visible: visible,
                  maintainState: widget.maintainContent,
                  maintainAnimation: widget.maintainContent,
                  child: _content(controller),
                ),
              ),
          ],
        );
      },
    );
  }
}
