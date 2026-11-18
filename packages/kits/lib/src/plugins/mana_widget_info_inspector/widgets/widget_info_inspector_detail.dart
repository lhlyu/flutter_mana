import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';

/// Snapshots diagnostics once so detached elements are never accessed by the UI.
class InfoPage extends StatefulWidget {
  const InfoPage({super.key, required this.elements, required this.onClose});
  final List<Element> elements;
  final VoidCallback onClose;
  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final _search = TextEditingController();
  late final _entries = [
    for (final element in widget.elements)
      if (element.mounted)
        (
          name: element.widget.toStringShort(),
          text: element.widget.toDiagnosticsNode().toStringDeep(),
        ),
  ];
  ({String name, String text})? _selected;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selected case final entry?) {
      return KitDetail(
        title: entry.name,
        onClose: () => setState(() => _selected = null),
        actions: [KitCopyButton(entry.text)],
        child: SingleChildScrollView(child: KitCode(entry.text)),
      );
    }
    final query = _search.text.toLowerCase();
    final entries = _entries
        .where((item) => item.name.toLowerCase().contains(query))
        .toList();
    return KitDetail(
      title: '${kitText(context, 'common.details')} (${_entries.length})',
      onClose: widget.onClose,
      child: KitScaffold(
        header: KitField(
          controller: _search,
          hintText: kitText(context, 'common.search'),
          onChanged: (_) => setState(() {}),
        ),
        body: entries.isEmpty
            ? KitMessage(kitText(context, 'common.empty'))
            : ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, i) => ManaButton(
                  onPressed: () => setState(() => _selected = entries[i]),
                  child: Align(
                    alignment: .centerLeft,
                    child: Text(
                      entries[i].name,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
