import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';
import '../code/code_widget.dart';
import '../utils/code_display_service.dart';

class ShowCodeContent extends StatefulWidget {
  const ShowCodeContent({super.key, this.root, this.service});
  final BuildContext? root;
  final CodeDisplayService? service;
  @override
  State<ShowCodeContent> createState() => _ShowCodeContentState();
}

class _ShowCodeContentState extends State<ShowCodeContent> {
  late CodeDisplayService _service = widget.service ?? CodeDisplayService();
  @override
  void didUpdateWidget(ShowCodeContent old) {
    super.didUpdateWidget(old);
    if (old.service == widget.service) return;
    if (old.service == null) unawaited(_service.close());
    _service = widget.service ?? CodeDisplayService();
  }

  @override
  void dispose() {
    if (widget.service == null) unawaited(_service.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitAsync<PageSource?>(
    key: ValueKey((_service, widget.root)),
    load: () => _service.currentPage(widget.root),
    builder: (context, page) {
      if (page == null) {
        return KitMessage(kitText(context, 'show_code.no_page'));
      }
      return KitScaffold(
        header: Padding(
          padding: const .symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${page.widgetName}\n${page.uri}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              KitCopyButton(page.source),
            ],
          ),
        ),
        body: CodeWidget(code: page.source),
      );
    },
  );
}
