import 'package:flutter/widgets.dart';

import '../i18n/kit_localizations.dart';
import 'kit_layout.dart';

/// Caches each load, shows failures and retries without rebuilding a Future.
class KitAsync<T> extends StatefulWidget {
  const KitAsync({super.key, required this.load, required this.builder});
  final Future<T> Function() load;
  final Widget Function(BuildContext, T) builder;
  @override
  State<KitAsync<T>> createState() => _KitAsyncState<T>();
}

class _KitAsyncState<T> extends State<KitAsync<T>> {
  Future<T>? _future;
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future ??= Future.sync(widget.load),
    builder: (context, snapshot) {
      if (snapshot.connectionState != .done) {
        return KitMessage(kitText(context, 'common.loading'));
      }
      if (snapshot.hasError) {
        return KitMessage(
          '${snapshot.error}',
          error: true,
          onRetry: () => setState(() {
            _future = null;
          }),
        );
      }
      return widget.builder(context, snapshot.data as T);
    },
  );
}
