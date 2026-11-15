import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/kit_feed.dart';
import '../mana_dio_collector.dart';
import 'response_detail.dart';
import 'response_tile.dart';

class DioInspectorContent extends StatefulWidget {
  const DioInspectorContent({super.key, required this.collector});
  final ManaDioCollector collector;
  @override
  State<DioInspectorContent> createState() => _DioInspectorContentState();
}

class _DioInspectorContentState extends State<DioInspectorContent> {
  Response<dynamic>? _selected;
  @override
  void didUpdateWidget(DioInspectorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collector != widget.collector) _selected = null;
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: .expand,
    children: [
      Visibility(
        visible: _selected == null,
        maintainState: true,
        child: ExcludeFocus(
          excluding: _selected != null,
          child: KitFeed<Response<dynamic>>(
            collector: widget.collector,
            categories: const [
              'GET',
              'POST',
              'PUT',
              'PATCH',
              'DELETE',
              'HEAD',
              'OPTIONS',
            ],
            categoryOf: (response) =>
                response.requestOptions.method.toUpperCase(),
            searchText: (response) =>
                '${response.requestOptions.uri} ${response.statusCode} ${response.extra[ManaDioCollector.errorKey] ?? ''}',
            itemBuilder: (context, response) => ResponseTile(
              response: response,
              onTap: () => setState(() => _selected = response),
            ),
          ),
        ),
      ),
      if (_selected case final response?)
        ResponseDetail(
          response: response,
          onClose: () => setState(() => _selected = null),
        ),
    ],
  );
}
