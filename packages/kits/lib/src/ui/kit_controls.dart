import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana_widgets.dart';

import '../i18n/kit_localizations.dart';
import 'kit_style.dart';
import 'kit_button.dart';
import 'kit_icons.dart';
import 'kit_selection.dart';

class KitCopyButton extends StatelessWidget {
  const KitCopyButton(this.text, {super.key, this.label});
  final String text;
  final String? label;
  @override
  Widget build(BuildContext context) => KitButton(
    label: label ?? kitText(context, 'common.copy'),
    icon: .copy,
    iconOnly: true,
    onPressed: () => Clipboard.setData(ClipboardData(text: text)),
  );
}

class KitToolbar extends StatelessWidget {
  const KitToolbar({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: KitStyle.surface,
      border: Border(top: BorderSide(color: KitStyle.border)),
    ),
    child: SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: .spaceEvenly,
        crossAxisAlignment: .center,
        children: children,
      ),
    ),
  );
}

class KitTabs<T> extends StatelessWidget {
  const KitTabs({
    super.key,
    required this.values,
    required this.value,
    required this.onChanged,
    this.label,
  });
  final List<T> values;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T)? label;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: .horizontal,
    child: Row(
      children: [
        for (final item in values)
          KitButton(
            label: label?.call(item) ?? '$item',
            selected: item == value,
            onPressed: () => onChanged(item),
          ),
      ],
    ),
  );
}

class KitToggle extends StatelessWidget {
  const KitToggle({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    child: ManaButton(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      child: Row(
        spacing: 10,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? KitStyle.accent : KitStyle.surface,
              border: Border.all(
                color: value ? KitStyle.accent : KitStyle.muted,
              ),
              borderRadius: .circular(4),
            ),
            child: value
                ? const Center(
                    child: KitGlyph(.check, size: 16, color: KitStyle.surface),
                  )
                : null,
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: KitStyle.text),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Raw editable input with a Widgets-only selection toolbar.
class KitField extends StatefulWidget {
  const KitField({
    super.key,
    required this.controller,
    required this.label,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
  });
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final bool readOnly;
  @override
  State<KitField> createState() => _KitFieldState();
}

class _KitFieldState extends State<KitField> {
  final _focus = FocusNode();
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .all(8),
    child: Column(
      crossAxisAlignment: .stretch,
      spacing: 4,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 12, color: KitStyle.muted),
        ),
        Container(
          padding: const .all(10),
          decoration: BoxDecoration(
            color: KitStyle.subtle,
            border: Border.all(color: KitStyle.border),
            borderRadius: .circular(4),
          ),
          child: Semantics(
            textField: true,
            label: widget.label,
            child: EditableText(
              controller: widget.controller,
              focusNode: _focus,
              style: DefaultTextStyle.of(context).style
                  .merge(ManaStyle.textStyle),
              cursorColor: KitStyle.accent,
              backgroundCursorColor: KitStyle.muted,
              maxLines: widget.maxLines,
              readOnly: widget.readOnly,
              selectionColor: KitStyle.accent.withValues(alpha: .2),
              selectionControls: kitSelectionControls,
              contextMenuBuilder: (context, state) => KitSelectionMenu(
                anchors: state.contextMenuAnchors,
                items: state.contextMenuButtonItems,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ),
      ],
    ),
  );
}
