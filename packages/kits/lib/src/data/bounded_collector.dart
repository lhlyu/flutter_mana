import 'dart:collection';

import 'package:flutter/foundation.dart';

/// A bounded chronological buffer. Late producer callbacks after disposal are ignored.
class BoundedCollector<T> extends ChangeNotifier {
  BoundedCollector({this.capacity = 1000, this.maxBytes = 8 * 1024 * 1024}) {
    if (capacity < 1) throw ArgumentError.value(capacity, 'capacity');
    if (maxBytes < 1) throw ArgumentError.value(maxBytes, 'maxBytes');
  }
  final int capacity;
  final int maxBytes;
  int _retainedBytes = 0;
  int get retainedBytes => _retainedBytes;
  final _items = ListQueue<({T value, int bytes})>();
  List<T>? _snapshot;
  bool _disposed = false;
  bool get isDisposed => _disposed;
  List<T> get data =>
      _snapshot ??= List.unmodifiable(_items.map((item) => item.value));
  void add(T value, {int sizeBytes = 0}) {
    if (_disposed) return;
    if (sizeBytes < 0) throw ArgumentError.value(sizeBytes, 'sizeBytes');
    if (sizeBytes > maxBytes) return;
    while (_items.isNotEmpty &&
        (_items.length >= capacity || _retainedBytes + sizeBytes > maxBytes)) {
      _retainedBytes -= _items.removeFirst().bytes;
    }
    _items.addLast((value: value, bytes: sizeBytes));
    _retainedBytes += sizeBytes;
    _snapshot = null;
    notifyListeners();
  }

  void clear() {
    if (_disposed || _items.isEmpty) return;
    _items.clear();
    _retainedBytes = 0;
    _snapshot = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _items.clear();
    _retainedBytes = 0;
    _snapshot = null;
    super.dispose();
  }
}
