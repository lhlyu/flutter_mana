import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

const captureExportUnavailableKey = 'manaCaptureExportUnavailable';

/// Estimated retained payload bytes, not heap usage.
class CaptureBudget {
  CaptureBudget(this.limit) {
    if (limit < 256) {
      throw ArgumentError.value(limit, 'maxEntryBytes', 'Must be at least 256');
    }
  }

  final int limit;
  int usedBytes = 0;
  bool truncated = false;
  final _parents = HashSet<Object>.identity();
  int get remaining => limit - usedBytes;

  bool _reserve(int bytes) {
    if (bytes > remaining) {
      truncated = true;
      return false;
    }
    usedBytes += bytes;
    return true;
  }

  String text(String value) {
    if (!_reserve(16)) return '';
    var length = math.min(value.length, remaining ~/ 2);
    if (length > 0 && length < value.length) {
      final last = value.codeUnitAt(length - 1);
      if (last >= 0xD800 && last <= 0xDBFF) length--;
    }
    usedBytes += length * 2;
    if (length < value.length) truncated = true;
    return value.substring(0, length);
  }

  String lines(Iterable<String> values) {
    final result = StringBuffer();
    for (final value in values) {
      if (remaining < 32) {
        truncated = true;
        break;
      }
      if (result.isNotEmpty) result.write(text('\n'));
      result.write(text(value));
    }
    return result.toString();
  }

  Object? copy(Object? value, [int depth = 0]) {
    if (value == null) return null;
    if (value is String) return text(value);
    if (value is num || value is bool || value is DateTime) {
      return _reserve(16) ? value : null;
    }
    if (value is Stream || value is Function) {
      truncated = true;
      return text('[Not captured]');
    }
    if (depth >= 12 || _parents.contains(value)) {
      truncated = true;
      return text('[Nested or cyclic data omitted]');
    }
    if (value is TypedData) {
      if (!_reserve(32)) return null;
      final length = math.min(value.lengthInBytes, remaining);
      if (length < value.lengthInBytes) truncated = true;
      usedBytes += length;
      return Uint8List.fromList(
        value.buffer.asUint8List(value.offsetInBytes, length),
      );
    }
    if (value is Map || value is List) {
      if (!_reserve(32)) return null;
      _parents.add(value);
      try {
        if (value is List) {
          final items = <Object?>[];
          for (final item in value) {
            if (remaining < 32) {
              truncated = true;
              break;
            }
            _reserve(8);
            items.add(copy(item, depth + 1));
          }
          return List<Object?>.unmodifiable(items);
        }
        final map = value as Map;
        final result = <Object?, Object?>{};
        for (final entry in map.entries) {
          if (remaining < 64) {
            truncated = true;
            break;
          }
          _reserve(16);
          result[copy(entry.key, depth + 1)] = copy(entry.value, depth + 1);
        }
        if (map is Map<String, dynamic>) {
          return Map<String, dynamic>.unmodifiable(
            result.cast<String, dynamic>(),
          );
        }
        return Map<Object?, Object?>.unmodifiable(result);
      } finally {
        _parents.remove(value);
      }
    }
    truncated = true;
    try {
      return text(value.toString());
    } catch (_) {
      return text('[Unprintable object]');
    }
  }
}
