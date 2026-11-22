import 'dart:async';

import 'package:flutter/widgets.dart';

import 'mana_button.dart';
import 'mana_icon.dart';
import 'mana_style.dart';

/// 操作成功后显示确认图标，持续 [resetDuration]。
class CheckIconButton extends StatefulWidget {
  final IconData initialIcon;

  final IconData? changedIcon;
  final Color? iconColor;
  final double? size;
  final EdgeInsetsGeometry padding;
  final BoxConstraints constraints;
  final BoxDecoration? decoration;
  final Duration resetDuration;
  final FutureOr<void> Function()? onPressed;

  const CheckIconButton({
    super.key,
    required this.initialIcon,
    this.changedIcon,
    this.iconColor,
    this.size,
    this.padding = const .all(8),
    this.constraints = const BoxConstraints(minWidth: 40, minHeight: 40),
    this.decoration,
    this.resetDuration = const Duration(seconds: 2),
    this.onPressed,
  });

  @override
  State<CheckIconButton> createState() => _CheckIconButtonState();
}

enum _CheckStatus { idle, pending, checked }

class _CheckIconButtonState extends State<CheckIconButton> {
  Timer? _resetTimer;
  _CheckStatus _status = .idle;

  Future<void> _press() async {
    final onPressed = widget.onPressed;
    if (_status != .idle || onPressed == null) return;
    setState(() => _status = .pending);
    try {
      await onPressed();
      if (!mounted) return;
      setState(() => _status = .checked);
      _resetTimer = Timer(widget.resetDuration, () {
        if (mounted) setState(() => _status = .idle);
      });
    } catch (error, stack) {
      if (mounted) setState(() => _status = .idle);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'flutter_mana',
          context: ErrorDescription(
            'while performing a CheckIconButton action',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final color = widget.iconColor ?? theme.color ?? ManaStyle.text;
    final size = widget.size ?? theme.size ?? 24;
    final checked = _status == .checked;
    final changedIcon = widget.changedIcon;
    return ManaButton(
      onPressed: widget.onPressed != null && _status == .idle
          ? () => unawaited(_press())
          : null,
      padding: widget.padding,
      constraints: widget.constraints,
      decoration: widget.decoration,
      child: checked && changedIcon == null
          ? ManaIcon(.check, size: size, color: color)
          : Icon(
              checked ? changedIcon : widget.initialIcon,
              size: size,
              color: color,
            ),
    );
  }
}
