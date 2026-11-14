import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../data/bounded_collector.dart';

/// Attach the same instance to Logger.output and ManaLogViewer.
class ManaLogCollector extends BoundedCollector<OutputEvent>
    implements LogOutput {
  ManaLogCollector({super.capacity});
  final _captures = <VoidCallback>{};
  @override
  Future<void> init() async {}
  @override
  Future<void> destroy() async {}
  @override
  void output(OutputEvent event) => add(event);

  /// Returns an idempotent release callback. Multiple viewers may capture together.
  VoidCallback captureDebugPrint() {
    if (isDisposed) throw StateError('Collector is disposed.');
    final release = _DebugPrintCapture.attach(this);
    var active = true;
    late final VoidCallback cancel;
    cancel = () {
      if (!active) return;
      active = false;
      _captures.remove(cancel);
      release();
    };
    _captures.add(cancel);
    return cancel;
  }

  @override
  void dispose() {
    for (final release in _captures.toList()) {
      release();
    }
    super.dispose();
  }
}

abstract final class _DebugPrintCapture {
  static final _targets = <Object, ManaLogCollector>{};
  static DebugPrintCallback? _original;
  static bool _capturing = false;

  static void _print(String? message, {int? wrapWidth}) {
    final original = _original;
    if (_capturing) {
      original?.call(message, wrapWidth: wrapWidth);
      return;
    }
    _capturing = true;
    try {
      for (final collector in _targets.values.toSet()) {
        collector.output(
          OutputEvent(LogEvent(Level.debug, message ?? ''), [message ?? '']),
        );
      }
      original?.call(message, wrapWidth: wrapWidth);
    } finally {
      _capturing = false;
    }
  }

  static VoidCallback attach(ManaLogCollector collector) {
    if (_targets.isEmpty) {
      _original = debugPrint;
      debugPrint = _print;
    }
    final token = Object();
    _targets[token] = collector;
    return () {
      _targets.remove(token);
      if (_targets.isEmpty) {
        if (debugPrint == _print) debugPrint = _original!;
        _original = null;
      }
    };
  }
}
