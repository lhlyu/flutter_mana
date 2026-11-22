import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../mana_button.dart';
import '../mana_icon.dart';
import '../mana_i18n.dart';
import '../mana_style.dart';

@immutable
class WindowControls extends StatefulWidget {
  final bool drag;
  final bool isFullscreen;
  final bool showSettingButton;
  final GestureDragUpdateCallback onPanUpdate;
  final VoidCallback onToggleSetting;
  final VoidCallback onFullscreen;
  final VoidCallback onMinimize;
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

class _WindowControlsState extends State<WindowControls> with ManaI18n {
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
        return SingleChildScrollView(
          scrollDirection: .horizontal,
          child: SizedBox(
            width: math.max(128, constraints.maxWidth),
            child: Row(
              children: [
                _buildIconButton(
                  icon: widget.isFullscreen ? .exitFullscreen : .fullscreen,
                  tooltip: t(
                    widget.isFullscreen
                        ? 'window_exit_fullscreen'
                        : 'window_fullscreen',
                    locale: Localizations.localeOf(context),
                  ),
                  onPressed: widget.onFullscreen,
                ),
                _buildIconButton(
                  icon: .minimize,
                  tooltip: t(
                    'window_minimize',
                    locale: Localizations.localeOf(context),
                  ),
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
                    tooltip: t(
                      'window_settings',
                      locale: Localizations.localeOf(context),
                    ),
                    onPressed: widget.onToggleSetting,
                  ),
                ),
                _buildIconButton(
                  icon: .close,
                  tooltip: t(
                    'window_close',
                    locale: Localizations.localeOf(context),
                  ),
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
