import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:vm_service/vm_service.dart';

import '../../../ui/kit_ui.dart';
import '../code/code_widget.dart';
import '../utils/code_display_service.dart';

class ShowCodeContent extends StatefulWidget {
  const ShowCodeContent({super.key, this.service});
  final CodeDisplayService? service;
  @override
  State<ShowCodeContent> createState() => _ShowCodeContentState();
}

class _ShowCodeContentState extends State<ShowCodeContent> {
  late CodeDisplayService _service = widget.service ?? CodeDisplayService();
  final _query = TextEditingController();
  ScriptRef? _selected;
  @override
  void didUpdateWidget(ShowCodeContent old) {
    super.didUpdateWidget(old);
    if (old.service == widget.service) return;
    if (old.service == null) unawaited(_service.close());
    _service = widget.service ?? CodeDisplayService();
    _selected = null;
  }

  @override
  void dispose() {
    _query.dispose();
    if (widget.service == null) unawaited(_service.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selected case final script?) {
      return KitDetail(
        title: script.uri ?? '',
        onClose: () => setState(() => _selected = null),
        child: KitAsync<String>(
          key: ValueKey(script.id),
          load: () => _service.source(script),
          builder: (context, source) => Column(
            children: [
              Align(alignment: .centerRight, child: KitCopyButton(source)),
              Expanded(child: CodeWidget(code: source)),
            ],
          ),
        ),
      );
    }
    return KitAsync<List<ScriptRef>>(
      key: ObjectKey(_service),
      load: _service.scripts,
      builder: (context, scripts) {
        final query = _query.text.toLowerCase();
        final items = scripts
            .where((script) => script.uri!.toLowerCase().contains(query))
            .toList();
        return Column(
          children: [
            KitField(
              controller: _query,
              label: kitText(context, 'common.search'),
              onChanged: (_) => setState(() {}),
            ),
            Expanded(
              child: items.isEmpty
                  ? KitMessage(kitText(context, 'common.empty'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) => ManaButton(
                        onPressed: () => setState(() => _selected = items[i]),
                        child: Align(
                          alignment: .centerLeft,
                          child: Text(
                            items[i].uri!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
