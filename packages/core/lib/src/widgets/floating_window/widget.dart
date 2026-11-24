import 'package:flutter/widgets.dart';

import '../../runtime/mana_scope.dart';
import 'enum.dart';

import '../mana_style.dart';
import 'controller.dart';
import 'window_controls.dart';

@immutable
class FloatingWindow extends StatefulWidget {
  final String name;
  final Widget? content;
  final Widget? barrier;
  final Widget? setting;
  final double? initialWidth;
  final double? initialHeight;

  /// Optional live height, used by panels that can collapse without losing state.
  final double? height;
  final PositionType position;
  final Offset? initialPosition;
  final bool showControls;
  final bool showBarrier;
  final bool maintainContent;
  final bool drag;
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;

  const FloatingWindow({
    super.key,
    required this.name,
    this.content,
    this.barrier,
    this.setting,
    this.initialWidth,
    this.initialHeight,
    this.height,
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
      controller.update(context, height: widget.height);
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
      if (widget.height != null) {
        _controller!.update(context, height: widget.height);
      }
    }
  }

  @override
  void didUpdateWidget(FloatingWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.height != widget.height) {
      _controller?.update(context, height: widget.height);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _content(FloatingWindowController controller) {
    final fullscreen = controller.isFullscreen;
    final showingSettings =
        controller.showSetting.value && widget.setting != null;
    return Container(
      clipBehavior: .antiAlias,
      decoration: BoxDecoration(
        color: ManaStyle.surface,
        borderRadius: fullscreen || widget.initialHeight == double.infinity
            ? .zero
            : .circular(8),
        boxShadow: const [BoxShadow(color: ManaStyle.shadow, blurRadius: 16)],
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        child: Padding(
          padding: fullscreen ? controller.safePadding : EdgeInsets.zero,
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
                      onMinimize: () =>
                          controller.onMinimize(widget.onMinimize),
                      onClose: () => controller.onClose(widget.onClose),
                    ),
                  ),
                Expanded(
                  child: PrimaryScrollController.none(
                    child: Stack(
                      fit: .expand,
                      children: [
                        Offstage(
                          offstage: showingSettings,
                          child: TickerMode(
                            enabled: !showingSettings,
                            child: ExcludeFocus(
                              excluding: showingSettings,
                              child: widget.content ?? const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        if (showingSettings)
                          ColoredBox(
                            color: ManaStyle.surface,
                            child: widget.setting!,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
        controller.fullscreen,
        controller.showSetting,
      ]),
      builder: (context, _) {
        final fullscreen = controller.isFullscreen;
        final visible = controller.isVisible;
        return ValueListenableBuilder<Offset>(
          valueListenable: controller.offset,
          child: widget.content == null
              ? null
              : Visibility(
                  visible: visible,
                  maintainState: widget.maintainContent,
                  child: ExcludeFocus(
                    excluding: !visible,
                    child: _content(controller),
                  ),
                ),
          builder: (context, offset, content) => Stack(
            children: [
              if (widget.showBarrier && (visible || widget.barrier != null))
                widget.barrier ??
                    GestureDetector(
                      behavior: .opaque,
                      onTap: () => controller.onMinimize(widget.onMinimize),
                      child: const SizedBox.expand(),
                    ),
              if (content != null)
                Positioned(
                  left: fullscreen ? 0 : offset.dx,
                  top: fullscreen ? 0 : offset.dy,
                  width: fullscreen
                      ? controller.screenSize.width
                      : controller.windowSize.width,
                  height: fullscreen
                      ? controller.screenSize.height
                      : controller.windowSize.height,
                  child: content,
                ),
            ],
          ),
        );
      },
    );
  }
}
