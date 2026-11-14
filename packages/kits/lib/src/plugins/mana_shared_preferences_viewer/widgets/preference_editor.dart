import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';
import '../preference_entry.dart';

class PreferenceEditor extends StatefulWidget {
  const PreferenceEditor({
    super.key,
    this.entry,
    required this.onClose,
    required this.onSave,
  });
  final PreferenceEntry? entry;
  final VoidCallback onClose;
  final Future<void> Function(PreferenceEntry) onSave;
  @override
  State<PreferenceEditor> createState() => _PreferenceEditorState();
}

class _PreferenceEditorState extends State<PreferenceEditor> {
  late final _key = TextEditingController(text: widget.entry?.key);
  late final _value = TextEditingController(text: widget.entry?.value);
  late PreferenceKind _kind = widget.entry?.kind ?? .string;
  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitDetail(
    title: kitText(context, 'common.details'),
    onClose: widget.onClose,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          KitTabs(
            values: PreferenceKind.values,
            value: _kind,
            label: (kind) => kind.label,
            onChanged: (kind) => setState(() => _kind = kind),
          ),
          KitField(
            controller: _key,
            label: kitText(context, 'shared_preferences_viewer.key'),
          ),
          KitField(
            controller: _value,
            label: kitText(context, 'shared_preferences_viewer.value'),
            maxLines: 5,
          ),
          KitToolbar(
            children: [
              KitButton(
                label: kitText(context, 'common.save'),
                icon: .check,
                onPressed: () async {
                  await widget.onSave(
                    PreferenceEntry(_key.text, _value.text, _kind),
                  );
                  if (mounted) widget.onClose();
                },
              ),
              KitButton(
                label: kitText(context, 'common.cancel'),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
