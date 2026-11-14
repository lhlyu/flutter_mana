import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana_widgets.dart';

import '../i18n/kit_localizations.dart';
import 'kit_style.dart';
import 'kit_icons.dart';

/// Handles an action once at a time and exposes recoverable failures inline.
class KitButton extends StatefulWidget {
  const KitButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.selected = false,
    this.iconOnly = false,
  });
  final String label;
  final KitIcon? icon;
  final FutureOr<void> Function()? onPressed;
  final bool selected;
  final bool iconOnly;
  @override
  State<KitButton> createState() => _KitButtonState();
}

class _KitButtonState extends State<KitButton> {
  bool _busy = false;
  Object? _error;
  Future<void> _run() async {
    if (_busy || widget.onPressed == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onPressed!();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      Semantics(
        label: widget.iconOnly ? widget.label : null,
        selected: widget.selected,
        child: ManaButton(
          tooltip: widget.label,
          onPressed: _busy || widget.onPressed == null ? null : _run,
          decoration: BoxDecoration(
            color: widget.selected
                ? KitStyle.accent.withValues(alpha: 0.12)
                : null,
            borderRadius: .circular(4),
          ),
          child: Row(
            mainAxisSize: .min,
            spacing: 6,
            children: [
              if (widget.icon case final icon?)
                KitGlyph(icon, color: widget.selected ? KitStyle.accent : null),
              if (!widget.iconOnly)
                Flexible(
                  child: Text(
                    _busy ? kitText(context, 'common.working') : widget.label,
                    style: const TextStyle(fontSize: 13, color: KitStyle.text),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (_error case final error?)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            '$error',
            style: const TextStyle(fontSize: 11, color: KitStyle.danger),
          ),
        ),
    ],
  );
}
