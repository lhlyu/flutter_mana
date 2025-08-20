import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ManaDioCollector extends ChangeNotifier implements Interceptor {
  static final ManaDioCollector _instance = ManaDioCollector._internal();

  factory ManaDioCollector() => _instance;

  ManaDioCollector._internal();

  static const int _max = 1000;

  final ListQueue<Response> _data = ListQueue();

  UnmodifiableListView<Response> get data => UnmodifiableListView(_data);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['manaDioRequestStartTime'] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    addResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      addResponse(err.response!);
    }
    handler.next(err);
  }

  void addResponse(Response response) {
    response.extra['manaDioRequestEndTime'] = DateTime.now();
    _data.add(response);
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
