import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app and kits must share the same collectors.
class DemoSession extends ChangeNotifier {
  DemoSession({ManaPreferences? preferences}) {
    dio = Dio(BaseOptions(baseUrl: 'https://mana.demo'))
      ..httpClientAdapter = _LocalAdapter()
      ..interceptors.add(requests);
    logger = Logger(
      filter: _AllLogs(),
      output: logs,
      printer: SimplePrinter(colors: false),
    );
    controller = ManaController(
      preferences: preferences,
      plugins: loadAllPlugins(
        dioCollector: requests,
        logCollector: logs,
        captureDebugPrint: true,
      ),
    );
  }

  final requests = ManaDioCollector(capacity: 100);
  final logs = ManaLogCollector(capacity: 100);
  late final Dio dio;
  late final Logger logger;
  late final ManaController controller;
  bool busy = false;
  bool _closed = false;
  Future<void>? _closing;

  Future<void> send(String scenario) async {
    if (busy || _closed) return;
    busy = true;
    notifyListeners();
    try {
      await dio.request<Object?>(
        '/$scenario',
        data: scenario == 'POST' ? {'name': 'Flutter Mana'} : null,
        options: Options(method: scenario == 'POST' ? 'POST' : 'GET'),
      );
    } on DioException {
      // Expected demo errors are already captured by ManaDioCollector.
    } finally {
      if (!_closed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void writeLogs() {
    logger.d('Debug message');
    logger.i('Hello from Flutter Mana / 你好，Flutter Mana');
    logger.w('Sample warning');
    logger.e(
      'Sample error',
      error: StateError('Demo only'),
      stackTrace: StackTrace.current,
    );
    debugPrint('[debugPrint] Captured by ManaLogViewer');
  }

  Future<void> seedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await Future.wait([
      prefs.setString('example.name', 'Flutter Mana'),
      prefs.setInt('example.count', 42),
      prefs.setDouble('example.scale', 1.5),
      prefs.setBool('example.enabled', true),
      prefs.setStringList('example.languages', ['English', '中文']),
    ]);
    if (saved.contains(false)) {
      throw StateError('Could not save sample preferences');
    }
  }

  Future<void> close() => _closing ??= _close();
  Future<void> _close() async {
    _closed = true;
    dio.close(force: true);
    // Release debugPrint capture before disposing the shared collector.
    await controller.close();
    await logger.close();
    requests.dispose();
    logs.dispose();
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}

class _AllLogs extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

/// Offline responses still travel through the real Dio interceptor.
class _LocalAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (options.path == '/Timeout') {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
        message: 'Simulated timeout',
      );
    }
    final status = options.path == '/404'
        ? 404
        : options.method == 'POST'
        ? 201
        : 200;
    return ResponseBody.fromString(
      jsonEncode({
        'message': status == 404 ? 'Not found' : 'Hello, Mana',
        'mock': true,
      }),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
