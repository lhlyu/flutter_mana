import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../data/bounded_collector.dart';
import '../../data/capture_budget.dart';

class CapturedLogEvent extends OutputEvent {
  CapturedLogEvent(
    super.origin,
    super.lines, {
    required this.truncated,
    required this.capturedBytes,
  });
  final bool truncated;
  final int capturedBytes;
}

/// Attach the same instance to Logger.output and ManaLogViewer.
class ManaLogCollector extends BoundedCollector<OutputEvent>
    implements LogOutput {
  ManaLogCollector({
    super.capacity,
    super.maxBytes = 4 * 1024 * 1024,
    this.maxEntryBytes = 64 * 1024,
  }) {
    CaptureBudget(math.min(maxEntryBytes, maxBytes));
  }
  final int maxEntryBytes;
  final _captures = <VoidCallback>{};
  @override
  Future<void> init() async {}
  @override
  Future<void> destroy() async {}
  @override
  void output(OutputEvent event) => add(event);

  @override
  void add(OutputEvent value, {int sizeBytes = 0}) {
    if (isDisposed) return;
    final budget = CaptureBudget(math.min(maxEntryBytes, maxBytes));
    final source = value.origin;
    final message = source.message is Function
        ? budget.lines(value.lines).replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '')
        : budget.copy(source.message);
    final error = budget.copy(source.error);
    final stack = source.stackTrace == null
        ? null
        : StackTrace.fromString(budget.text(source.stackTrace.toString()));
    final lines = <String>[];
    if (source.message is! Function) {
      for (final line in value.lines) {
        if (budget.remaining < 32) {
          budget.truncated = true;
          break;
        }
        lines.add(budget.text(line));
      }
    }
    final record = CapturedLogEvent(
      LogEvent(
        value.level,
        message,
        time: source.time,
        error: error,
        stackTrace: stack,
      ),
      List.unmodifiable(lines),
      truncated:
          budget.truncated || (value is CapturedLogEvent && value.truncated),
      capturedBytes: budget.usedBytes,
    );
    super.add(record, sizeBytes: budget.usedBytes);
  }

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
