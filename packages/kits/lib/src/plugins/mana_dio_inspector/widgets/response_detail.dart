import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';
import '../mana_dio_collector.dart';
import '../request_format.dart';

class ResponseDetail extends StatefulWidget {
  const ResponseDetail({
    super.key,
    required this.response,
    required this.onClose,
  });
  final Response<dynamic> response;
  final VoidCallback onClose;
  @override
  State<ResponseDetail> createState() => _ResponseDetailState();
}

class _ResponseDetailState extends State<ResponseDetail> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final response = widget.response;
    final request = response.requestOptions;
    final start = request.extra[ManaDioCollector.startTimeKey];
    final end = response.extra[ManaDioCollector.endTimeKey];
    return KitDetail(
      title: '${request.uri}',
      onClose: widget.onClose,
      child: KitScaffold(
        header: Column(
          mainAxisSize: .min,
          children: [
            KitTabs(
              values: const [0, 1, 2],
              value: _tab,
              label: (tab) => kitText(
                context,
                [
                  'dio_inspector.detail',
                  'dio_inspector.request',
                  'dio_inspector.response',
                ][tab],
              ),
              onChanged: (value) => setState(() => _tab = value),
            ),
            const KitDivider(),
          ],
        ),
        body: SingleChildScrollView(
          child: switch (_tab) {
            0 => KitDataTable({
              'URL': request.uri,
              'Method': request.method,
              'Status': response.statusCode,
              'Message': response.statusMessage,
              'Time': start is DateTime ? start.toIso8601String() : null,
              'Duration': start is DateTime && end is DateTime
                  ? '${end.difference(start).inMilliseconds}ms'
                  : null,
              'Error': ?response.extra[ManaDioCollector.errorKey],
            }),
            1 => Column(
              children: [
                KitSection(
                  kitText(context, 'dio_inspector.request_header'),
                  child: KitDataTable(request.headers),
                ),
                KitSection(
                  kitText(context, 'dio_inspector.request_body'),
                  child: KitCode(formatBody(request.data)),
                ),
              ],
            ),
            _ => Column(
              children: [
                KitSection(
                  kitText(context, 'dio_inspector.response_header'),
                  child: KitDataTable(
                    response.headers.map.map(
                      (k, v) => MapEntry(k, v.join('; ')),
                    ),
                  ),
                ),
                KitSection(
                  kitText(context, 'dio_inspector.response_body'),
                  child: KitCode(formatBody(response.data)),
                ),
              ],
            ),
          },
        ),
        footer: KitToolbar(
          children: [
            for (final (label, value) in [
              ('URL', () => request.uri.toString()),
              ('cURL', () => formatCurl(request)),
              ('HTTP', () => formatHttp(request)),
              (
                kitText(context, 'dio_inspector.response'),
                () => formatBody(response.data),
              ),
            ])
              KitButton(
                label: '${kitText(context, 'common.copy')} $label',
                icon: .copy,
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: value())),
              ),
          ],
        ),
      ),
    );
  }
}
