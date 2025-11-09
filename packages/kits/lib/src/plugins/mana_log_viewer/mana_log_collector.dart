import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class ManaLogCollector extends ChangeNotifier implements LogOutput {
  static final ManaLogCollector _instance = ManaLogCollector._internal();

  factory ManaLogCollector() => _instance;

  ManaLogCollector._internal();

  static const int _max = 1000;

  final ListQueue<OutputEvent> _data = ListQueue();

  UnmodifiableListView<OutputEvent> get data => UnmodifiableListView(_data);

  static DebugPrintCallback? _originalDebugPrint;

  static redirectDebugPrint() {
    if (_originalDebugPrint != null) return;
    _originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      ManaLogCollector._instance.output(
        OutputEvent(LogEvent(Level.debug, message), []),
      );

      if (_originalDebugPrint != null) {
        _originalDebugPrint!(message, wrapWidth: wrapWidth);
      }
    };
  }

  @override
  Future<void> init() => Future.value();

  @override
  Future<void> destroy() => Future.value();

  @override
  void output(OutputEvent event) {
    _data.add(event);
    if (_data.length > _max) {
      _data.removeFirst();
    }
    notifyListeners();
  }

  void clear() {
    _data.clear();
    notifyListeners();
  }
}
