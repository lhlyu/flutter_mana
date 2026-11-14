import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';

class License extends StatefulWidget {
  const License({super.key, required this.name});
  final String name;
  @override
  State<License> createState() => _LicenseState();
}

class _LicenseState extends State<License> {
  final _query = TextEditingController();
  String? _selected;
  Future<Map<String, List<LicenseEntry>>> _load() async {
    final result = <String, List<LicenseEntry>>{};
    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        (result[package] ??= []).add(entry);
      }
    }
    return result;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitWindow(
    name: widget.name,
    initialWidth: 600,
    initialHeight: double.infinity,
    showBarrier: false,
    content: KitAsync<Map<String, List<LicenseEntry>>>(
      load: _load,
      builder: (context, data) {
        if (_selected case final package?) {
          return KitDetail(
            title: package,
            onClose: () => setState(() => _selected = null),
            child: SingleChildScrollView(
              padding: const .all(12),
              child: KitSelection(
                child: Column(
                  crossAxisAlignment: .stretch,
                  spacing: 16,
                  children: [
                    for (final license
                        in data[package] ?? <LicenseEntry>[]) ...[
                      for (final paragraph in license.paragraphs)
                        Text(
                          paragraph.text,
                          textAlign:
                              paragraph.indent ==
                                  LicenseParagraph.centeredIndent
                              ? .center
                              : .start,
                          style: const TextStyle(fontSize: 12),
                        ),
                      const KitDivider(),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        final keys =
            data.keys
                .where(
                  (key) =>
                      key.toLowerCase().contains(_query.text.toLowerCase()),
                )
                .toList()
              ..sort();
        return Column(
          children: [
            KitField(
              controller: _query,
              label: kitText(context, 'common.search'),
              onChanged: (_) => setState(() {}),
            ),
            Expanded(
              child: keys.isEmpty
                  ? KitMessage(kitText(context, 'common.empty'))
                  : ListView.builder(
                      itemCount: keys.length,
                      itemBuilder: (context, i) => ManaButton(
                        onPressed: () => setState(() => _selected = keys[i]),
                        child: Align(
                          alignment: .centerLeft,
                          child: Text(keys[i]),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
}
