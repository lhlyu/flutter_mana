import 'dart:collection';

import 'package:flutter/foundation.dart';

/// A bounded chronological buffer. Late producer callbacks after disposal are ignored.
class BoundedCollector<T> extends ChangeNotifier {
  BoundedCollector({this.capacity = 1000}) {
    if (capacity < 1) throw ArgumentError.value(capacity, 'capacity');
  }
  final int capacity;
  final _items = ListQueue<T>();
  bool _disposed = false;
  bool get isDisposed => _disposed;
  List<T> get data => List.unmodifiable(_items);
  void add(T value) {
    if (_disposed) return;
    if (_items.length == capacity) _items.removeFirst();
    _items.addLast(value);
    notifyListeners();
  }

  void clear() {
    if (_disposed || _items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _items.clear();
    super.dispose();
  }
}
