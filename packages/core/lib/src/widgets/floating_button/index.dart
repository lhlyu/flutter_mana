import 'package:flutter/widgets.dart';

import '../../runtime/mana_scope.dart';
import '../mana_style.dart';
import 'controller.dart';
import 'icon.dart';

class FloatingButton extends StatefulWidget {
  const FloatingButton({super.key});

  @override
  State<FloatingButton> createState() => _FloatingButtonState();
}

class _FloatingButtonState extends State<FloatingButton> {
  FloatingButtonController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller case final controller?) {
      controller.updateContext(context);
    } else {
      _controller = FloatingButtonController(context);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runtime = ManaScope.of(context);
    final settings = runtime.state.settings;
    final id = runtime.state.activePluginId;
    final plugin = id == null ? null : runtime.plugins[id]?.plugin;
    final controller = _controller!;
    final padding = (settings.buttonSize / 6).truncateToDouble();
    final iconSize = settings.buttonSize - padding * 2;
    return ValueListenableBuilder(
      valueListenable: controller.offset,
      builder: (context, position, _) => Positioned(
        left: position.dx,
        top: position.dy,
        child: Semantics(
          button: true,
          label: 'Mana',
          child: GestureDetector(
            onTap: controller.onTap,
            onPanUpdate: controller.handleDragUpdate,
            onPanEnd: controller.handleDragEnd,
            child: Opacity(
              opacity: settings.buttonOpacity,
              child: Container(
                width: settings.buttonSize,
                height: settings.buttonSize,
                padding: .all(padding),
                decoration: BoxDecoration(
                  color: ManaStyle.surface,
                  borderRadius: .circular(
                    (settings.buttonSize / 7).truncateToDouble(),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: ManaStyle.shadow,
                      blurRadius: 2,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child:
                    plugin?.buildIcon(context, size: iconSize) ??
                    Image(image: iconImage, width: iconSize, height: iconSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
