import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'controller.dart';
import 'icon.dart';

class FloatingButton extends StatefulWidget {
  const FloatingButton({super.key});

  @override
  State<FloatingButton> createState() => _FloatingButtonState();
}

class _FloatingButtonState extends State<FloatingButton> {
  late final FloatingButtonController _controller;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      _controller.updateContext(context);
      return;
    }
    _controller = FloatingButtonController(context);
    _initialized = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _controller.offset,
      builder: (context, pos, _) {
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: GestureDetector(
            onTap: _controller.onTap,
            onPanUpdate: _controller.handleDragUpdate,
            onPanEnd: _controller.handleDragEnd,
            child: ValueListenableBuilder(
              valueListenable: _controller.state.floatingButtonOpacity,
              builder: (context, opacity, _) {
                return Opacity(
                  opacity: opacity,
                  child: ValueListenableBuilder(
                    valueListenable: _controller.state.floatingButtonSize,
                    builder: (context, size, _) {
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular((size / 7).truncateToDouble()),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              offset: Offset(0, 0),
                              blurRadius: 2,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all((size / 6).truncateToDouble()),
                            child: ValueListenableBuilder<String>(
                              valueListenable: _controller.state.activePluginName,
                              builder: (context, name, _) {
                                final icon = ManaPluginManager.instance.pluginsMap[name]?.iconImageProvider;
                                return Image(image: icon ?? iconImage);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
