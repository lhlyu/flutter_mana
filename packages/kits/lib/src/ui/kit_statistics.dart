import 'package:flutter/widgets.dart';

import '../data/bounded_collector.dart';
import '../i18n/kit_localizations.dart';
import 'kit_layout.dart';

/// Statistics describe retained data, independent of list filters.
class KitDataStatistics extends StatelessWidget {
  const KitDataStatistics({
    super.key,
    required this.countLabel,
    required this.count,
    this.capacity,
    this.retainedBytes,
    this.maxBytes,
  });

  final String countLabel;
  final int count;
  final int? capacity;
  final int? retainedBytes;
  final int? maxBytes;

  @override
  Widget build(BuildContext context) => KitSection(
    kitText(context, 'statistics.title'),
    child: KitDataTable({
      countLabel: count,
      kitText(context, 'statistics.capacity'): ?capacity,
      if ((retainedBytes, maxBytes) case (final bytes?, final limit?))
        kitText(context, 'statistics.captured_size'):
            '${kitText(context, 'statistics.approximate')} '
            '${_formatBytes(bytes)} / ${_formatBytes(limit)}',
    }),
  );
}

String _formatBytes(int bytes) {
  const units = ['B', 'KiB', 'MiB', 'GiB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} '
      '${units[unit]}';
}

/// Coalesces capture notifications, including those emitted during a build.
class KitCollectorStatistics<T> extends StatefulWidget {
  const KitCollectorStatistics({
    super.key,
    required this.collector,
    required this.countLabel,
  });

  final BoundedCollector<T> collector;
  final String countLabel;

  @override
  State<KitCollectorStatistics<T>> createState() =>
      _KitCollectorStatisticsState<T>();
}

class _KitCollectorStatisticsState<T> extends State<KitCollectorStatistics<T>> {
  bool _scheduled = false;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    widget.collector.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _active = TickerMode.valuesOf(context).enabled;
  }

  @override
  void didUpdateWidget(KitCollectorStatistics<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collector == widget.collector) return;
    oldWidget.collector.removeListener(_changed);
    widget.collector.addListener(_changed);
  }

  void _changed() {
    if (!mounted || !_active || _scheduled) return;
    _scheduled = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted && _active) setState(() {});
    });
    binding.ensureVisualUpdate();
  }

  @override
  void dispose() {
    widget.collector.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitDataStatistics(
    countLabel: widget.countLabel,
    count: widget.collector.length,
    capacity: widget.collector.capacity,
    retainedBytes: widget.collector.retainedBytes,
    maxBytes: widget.collector.maxBytes,
  );
}
