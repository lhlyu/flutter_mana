import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';
import '../preferences_repository.dart';
import '../preference_entry.dart';
import 'preference_editor.dart';
import 'preference_tile.dart';

class SharedPreferencesViewerContent extends StatefulWidget {
  const SharedPreferencesViewerContent({super.key, this.repository});
  final PreferencesRepository? repository;
  @override
  State<SharedPreferencesViewerContent> createState() =>
      _SharedPreferencesViewerContentState();
}

class _SharedPreferencesViewerContentState
    extends State<SharedPreferencesViewerContent> {
  late PreferencesRepository _repository =
      widget.repository ?? PreferencesRepository();
  final _query = TextEditingController();
  int _revision = 0;
  bool _filter = false;
  bool _editing = false;
  bool _confirmClear = false;
  PreferenceEntry? _selected;

  @override
  void didUpdateWidget(SharedPreferencesViewerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository == widget.repository) return;
    _repository = widget.repository ?? PreferencesRepository();
    _selected = null;
    _editing = false;
    _confirmClear = false;
    _revision++;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return PreferenceEditor(
        entry: _selected,
        onClose: () => setState(() {
          _editing = false;
          _revision++;
        }),
        onSave: (next) => _repository.save(_selected, next),
      );
    }
    return KitScaffold(
      header: _filter
          ? KitField(
              controller: _query,
              hintText: kitText(context, 'common.search'),
              onChanged: (_) => setState(() {}),
            )
          : null,
      body: KitAsync<List<PreferenceEntry>>(
        key: ValueKey(_revision),
        load: _repository.load,
        builder: (context, entries) {
          final query = _filter ? _query.text.toLowerCase() : '';
          final items = entries
              .where((entry) => entry.key.toLowerCase().contains(query))
              .toList();
          if (items.isEmpty) {
            return KitMessage(kitText(context, 'common.empty'));
          }
          return ListView.separated(
            padding: .zero,
            itemCount: items.length,
            itemBuilder: (context, i) => PreferenceTile(
              entry: items[i],
              onTap: () => setState(() {
                _selected = items[i];
                _editing = true;
              }),
              onDelete: () async {
                await _repository.remove(items[i].key);
                if (mounted) setState(() => _revision++);
              },
            ),
            separatorBuilder: (_, _) => const KitDivider(),
          );
        },
      ),
      footer: Column(
        mainAxisSize: .min,
        children: [
          if (_confirmClear)
            KitToolbar(
              children: [
                KitButton(
                  label: kitText(context, 'common.confirm_clear'),
                  onPressed: () async {
                    await _repository.clear();
                    if (mounted) {
                      setState(() {
                        _confirmClear = false;
                        _revision++;
                      });
                    }
                  },
                ),
                KitButton(
                  label: kitText(context, 'common.cancel'),
                  onPressed: () => setState(() => _confirmClear = false),
                ),
              ],
            ),
          KitToolbar(
            children: [
              KitButton(
                label: kitText(context, 'common.clear'),
                icon: .clear,
                iconOnly: true,
                onPressed: () => setState(() => _confirmClear = true),
              ),
              KitButton(
                label: kitText(context, 'common.add'),
                icon: .add,
                iconOnly: true,
                onPressed: () => setState(() {
                  _selected = null;
                  _editing = true;
                }),
              ),
              KitButton(
                label: kitText(context, 'common.refresh'),
                icon: .refresh,
                iconOnly: true,
                onPressed: () => setState(() => _revision++),
              ),
              KitButton(
                label: kitText(context, 'common.search'),
                icon: .filter,
                iconOnly: true,
                selected: _filter,
                onPressed: () => setState(() => _filter = !_filter),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
