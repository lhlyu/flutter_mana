import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/request_format.dart';
import 'package:flutter_mana_kits/src/plugins/mana_log_viewer/widgets/log_item_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _ErrorHandler extends ErrorInterceptorHandler {
  DioException? received;
  @override
  void next(DioException error) {
    received = error;
  }
}

void main() {
  test('debugPrint listeners cannot recursively capture themselves', () {
    final original = debugPrint;
    final forwarded = <String?>[];
    debugPrint = (message, {wrapWidth}) => forwarded.add(message);
    final collector = ManaLogCollector();
    addTearDown(() {
      collector.dispose();
      debugPrint = original;
    });
    collector.captureDebugPrint();
    var notifications = 0;
    collector.addListener(() {
      if (++notifications < 3) debugPrint('listener');
    });
    debugPrint('message');
    expect(notifications, 1);
    expect(collector.data.single.origin.message, 'message');
    expect(forwarded, ['listener', 'message']);
  });

  test(
    'releasing the final debugPrint capture still forwards the current message',
    () {
      final original = debugPrint;
      final forwarded = <String?>[];
      debugPrint = (message, {wrapWidth}) => forwarded.add(message);
      final baseline = debugPrint;
      final collector = ManaLogCollector();
      addTearDown(() {
        collector.dispose();
        debugPrint = original;
      });
      final cancel = collector.captureDebugPrint();
      collector.addListener(cancel);
      debugPrint('message');
      expect(forwarded, ['message']);
      expect(debugPrint, same(baseline));
    },
  );

  test('cURL respects form encoding and regenerates multipart boundaries', () {
    final encoded = RequestOptions(
      path: 'https://example.test',
      method: 'POST',
      contentType: Headers.formUrlEncodedContentType,
      data: <String, dynamic>{'a': 'x y'},
    );
    expect(formatCurl(encoded), contains("--data-raw 'a=x+y'"));
    final multipart = RequestOptions(
      path: 'https://example.test',
      method: 'POST',
      headers: {'content-type': 'multipart/form-data; boundary=old'},
      data: FormData.fromMap({'a': 'b'}),
    );
    expect(formatCurl(multipart), contains("--form-string 'a=b'"));
    expect(formatCurl(multipart), isNot(contains('boundary=old')));
  });

  test('rendering a lazy log message never executes application callbacks', () {
    var calls = 0;
    final event = OutputEvent(
      LogEvent(Level.info, () {
        calls++;
        return 'evaluated';
      }),
      ['rendered message'],
    );
    expect(formatLog(event, verbose: false), 'rendered message');
    expect(calls, 0);
  });
  test(
    'streamed uploads cannot be silently reconstructed as executable curl',
    () {
      final request = RequestOptions(
        path: 'https://example.test',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes([1, 2], filename: 'file.bin'),
        }),
      );
      expect(() => formatCurl(request), throwsUnsupportedError);
    },
  );

  test(
    'collector capacity is bounded, snapshots immutable, instances independent',
    () {
      final first = ManaLogCollector(capacity: 2);
      final second = ManaLogCollector();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      for (var i = 0; i < 3; i++) {
        first.output(OutputEvent(LogEvent(Level.info, i), []));
      }
      expect(first.data.map((event) => event.origin.message), [1, 2]);
      final snapshot = first.data;
      expect(() => snapshot.clear(), throwsUnsupportedError);
      first.clear();
      expect(snapshot, hasLength(2));
      expect(second.data, isEmpty);
      expect(() => ManaDioCollector(capacity: 0), throwsArgumentError);
    },
  );

  test('late callbacks from detached producers are ignored after disposal', () {
    final logs = ManaLogCollector();
    logs.dispose();
    logs.output(OutputEvent(LogEvent(Level.info, 'late'), []));
    expect(logs.data, isEmpty);
    final network = ManaDioCollector();
    network.dispose();
    final handler = ResponseInterceptorHandler();
    network.onResponse(
      Response<dynamic>(requestOptions: RequestOptions(path: '/')),
      handler,
    );
    expect(handler.isCompleted, isTrue);
    expect(network.data, isEmpty);
  });

  test(
    'network errors without an HTTP response are retained and forwarded',
    () {
      final collector = ManaDioCollector();
      addTearDown(collector.dispose);
      final request = RequestOptions(path: 'https://example.test');
      final requestHandler = RequestInterceptorHandler();
      collector.onRequest(request, requestHandler);
      final error = DioException(
        requestOptions: request,
        type: .connectionTimeout,
        message: 'timeout',
      );
      final handler = _ErrorHandler();
      collector.onError(error, handler);
      expect(handler.received, same(error));
      final record = collector.data.single;
      expect(record.requestOptions, same(request));
      expect(record.statusCode, isNull);
      expect(record.extra[ManaDioCollector.errorKey], 'timeout');
      expect(request.extra[ManaDioCollector.startTimeKey], isA<DateTime>());
    },
  );

  test('debug print captures are leased, deduplicated and restore the previous handler', () {
    final original = debugPrint;
    final forwarded = <String?>[];
    debugPrint = (message, {wrapWidth}) => forwarded.add(message);
    final baseline = debugPrint;
    final first = ManaLogCollector();
    final second = ManaLogCollector();
    addTearDown(() {
      first.dispose();
      second.dispose();
      debugPrint = original;
    });
    final cancel = first.captureDebugPrint();
    final duplicate = first.captureDebugPrint();
    final other = second.captureDebugPrint();
    debugPrint('one');
    expect(first.data, hasLength(1));
    expect(second.data, hasLength(1));
    cancel();
    cancel();
    debugPrint('two');
    expect(first.data, hasLength(2));
    first.dispose();
    debugPrint('three');
    expect(second.data, hasLength(3));
    other();
    duplicate();
    expect(debugPrint, same(baseline));
    expect(forwarded, ['one', 'two', 'three']);
  });

  test(
    'plugins dispose owned collectors but preserve injected producers',
    () async {
      final external = ManaLogCollector();
      final owned = ManaDioInspector();
      final injected = ManaLogViewer(
        collector: external,
        captureDebugPrint: true,
      );
      final original = debugPrint;
      injected.initialize();
      injected.dispose();
      owned.dispose();
      expect(debugPrint, same(original));
      expect(external.isDisposed, isFalse);
      expect(owned.collector.isDisposed, isTrue);
      external.dispose();
    },
  );

  test('loadAllPlugins creates fresh sessions with unique IDs and explicit collectors', () async {
    final logs = ManaLogCollector();
    final network = ManaDioCollector();
    final first = loadAllPlugins(logCollector: logs, dioCollector: network);
    final second = loadAllPlugins();
    expect(first, hasLength(16));
    expect(first.map((plugin) => plugin.name).toSet(), hasLength(16));
    expect(first.whereType<ManaLogViewer>().single.collector, same(logs));
    expect(first.whereType<ManaDioInspector>().single.collector, same(network));
    for (var i = 0; i < first.length; i++) {
      expect(first[i], isNot(same(second[i])));
    }
    for (final plugin in [...first, ...second]) {
      await Future<void>.sync(plugin.dispose);
    }
    expect(logs.isDisposed, isFalse);
    logs.dispose();
    network.dispose();
  });

  test('request exports preserve raw strings, escape shell arguments and handle form data', () {
    final request = RequestOptions(
      path: "https://example.test/a'b",
      method: 'POST',
      headers: {'Content-Length': '2', 'X-Test': "a'b\nnext"},
      data: '{"raw":true}',
    );
    final curl = formatCurl(request);
    expect(curl, contains("'\"'\"'"));
    expect(curl.toLowerCase(), isNot(contains('content-length')));
    expect(curl, contains("--data-raw '{\"raw\":true}'"));
    expect(formatBody('plain'), 'plain');
    expect(formatHttp(request), contains('\r\n\r\n{"raw":true}'));
    expect(formatBody(FormData.fromMap({'a': 'b'})), 'a=b');
  });

  test('verbose log formatting includes error and stack without mutating the event', () {
    final event = OutputEvent(
      LogEvent(
        Level.error,
        'message',
        error: 'error',
        stackTrace: StackTrace.fromString('trace'),
      ),
      [],
    );
    expect(formatLog(event, verbose: false), 'message');
    expect(formatLog(event, verbose: true), 'message\nerror\ntrace');
  });
}
