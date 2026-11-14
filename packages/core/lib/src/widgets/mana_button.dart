import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mana_style.dart';

/// A keyboard- and accessibility-aware button without a Material ancestor.
class ManaButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  final BoxConstraints constraints;
  final BoxDecoration? decoration;

  const ManaButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
    this.padding = const .all(8),
    this.constraints = const BoxConstraints(minWidth: 40, minHeight: 40),
    this.decoration,
  });

  @override
  State<ManaButton> createState() => _ManaButtonState();
}

class _ManaButtonState extends State<ManaButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final button = Semantics(
      button: true,
      enabled: enabled,
      tooltip: widget.tooltip,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: .opaque,
          excludeFromSemantics: true,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: Container(
            constraints: widget.constraints,
            decoration: widget.decoration,
            foregroundDecoration: BoxDecoration(
              color: enabled && (_hovered || _focused || _pressed)
                  ? ManaStyle.accent.withValues(alpha: _pressed ? 0.16 : 0.08)
                  : ManaStyle.transparent,
              shape: widget.decoration?.shape ?? .rectangle,
              borderRadius: widget.decoration?.shape == .circle
                  ? null
                  : widget.decoration?.borderRadius ?? .circular(4),
            ),
            padding: widget.padding,
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Opacity(opacity: enabled ? 1 : 0.4, child: widget.child),
            ),
          ),
        ),
      ),
    );
    final tooltip = widget.tooltip;
    if (tooltip == null || Overlay.maybeOf(context) == null) return button;
    return RawTooltip(
      semanticsTooltip: null, // Already supplied by the button's Semantics.
      hoverDelay: const Duration(milliseconds: 500),
      ignorePointer: true,
      tooltipBuilder: (context, animation) => FadeTransition(
        opacity: animation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const .symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ManaStyle.text,
            borderRadius: .circular(4),
          ),
          child: Text(
            tooltip,
            style: ManaStyle.textStyle.copyWith(
              color: ManaStyle.surface,
              fontSize: 12,
            ),
          ),
        ),
      ),
      child: button,
    );
  }
}
