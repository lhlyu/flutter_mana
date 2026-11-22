import 'package:flutter/widgets.dart';

import '../i18n/kit_localizations.dart';
import 'kit_layout.dart';

class KitAsync<T> extends StatefulWidget {
  const KitAsync({
    super.key,
    required this.load,
    required this.builder,
    this.loadKey,
  });
  final Future<T> Function() load;
  final Widget Function(BuildContext, T) builder;

  /// Identifies inline loaders whose closures change on each build.
  final Object? loadKey;
  @override
  State<KitAsync<T>> createState() => _KitAsyncState<T>();
}

class _KitAsyncState<T> extends State<KitAsync<T>> {
  Future<T>? _future;

  @override
  void didUpdateWidget(KitAsync<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.loadKey ?? oldWidget.load) !=
        (widget.loadKey ?? widget.load)) {
      _future = null;
    }
  }

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
