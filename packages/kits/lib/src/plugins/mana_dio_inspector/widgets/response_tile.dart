import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';
import '../mana_dio_collector.dart';

class ResponseTile extends StatelessWidget {
  const ResponseTile({super.key, required this.response, this.onTap});
  final Response<dynamic> response;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final start = response.requestOptions.extra[ManaDioCollector.startTimeKey];
    final end = response.extra[ManaDioCollector.endTimeKey];
    final elapsed = start is DateTime && end is DateTime
        ? end.difference(start).inMilliseconds
        : null;
    final failed = response.statusCode == null || response.statusCode! >= 400;
    return ManaButton(
      onPressed: onTap,
      padding: const .all(12),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 6,
        children: [
          Wrap(
            spacing: 12,
            children: [
              Text(
                response.requestOptions.method,
                style: const TextStyle(
                  color: KitStyle.accent,
                  fontWeight: .bold,
                ),
              ),
              Text(
                '${response.statusCode ?? 'ERR'}',
                style: TextStyle(
                  color: failed ? KitStyle.danger : KitStyle.success,
                ),
              ),
              if (elapsed != null) Text('${elapsed}ms'),
              if (start is DateTime)
                Text(
                  start.toIso8601String().split('T').last,
                  style: const TextStyle(color: KitStyle.muted, fontSize: 12),
                ),
            ],
          ),
          Text(
            '${response.requestOptions.uri}',
            maxLines: 2,
            overflow: .ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          if (response.extra[ManaDioCollector.errorKey] case final error?)
            Text(
              '$error',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: KitStyle.danger, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
