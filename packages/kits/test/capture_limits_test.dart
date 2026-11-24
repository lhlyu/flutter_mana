import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/request_format.dart';
import 'package:flutter_mana_kits/src/plugins/mana_log_viewer/widgets/log_item_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _UnprintableQueryValue {
  @override
  String toString() => throw StateError('Query value unavailable');
}

class _UnreadableMap extends MapBase<String, Object?> {
  @override
  Iterable<String> get keys => ['broken'];
  @override
  Object? operator [](Object? key) => throw StateError('Payload unavailable');
  @override
  void operator []=(String key, Object? value) =>
      throw UnsupportedError('Read only');
  @override
  void clear() => throw UnsupportedError('Read only');
  @override
  Object? remove(Object? key) => throw UnsupportedError('Read only');
}

class _UnreadableHeaders extends Headers {
  _UnreadableHeaders();
  @override
  Map<String, List<String>> get map => throw StateError('Headers unavailable');
}

void main() {
  test('invalid request URLs preserve the original network error', () async {
    final collector = ManaDioCollector();
    addTearDown(collector.dispose);
    final request = RequestOptions(path: 'https://[invalid', method: 'POST');
    final error = DioException(
      requestOptions: request,
      message: 'Invalid request URL',
    );
    final dio = Dio()
      ..interceptors.addAll([
        collector,
        InterceptorsWrapper(
          onRequest: (_, handler) => handler.reject(error, true),
        ),
      ]);
    addTearDown(() => dio.close(force: true));

    await expectLater(dio.fetch<dynamic>(request), throwsA(same(error)));
    final record = collector.data.single;
    expect(() => record.requestOptions.uri, returnsNormally);
    expect(record.requestOptions.method, 'POST');
    expect(record.extra[ManaDioCollector.errorKey], 'Invalid request URL');
    expect(record.extra[ManaDioCollector.truncatedKey], isTrue);
    expect(() => formatCurl(record.requestOptions), throwsUnsupportedError);
    expect(() => formatHttp(record.requestOptions), throwsUnsupportedError);
    expect(request.path, 'https://[invalid');
  });

  test(
    'unreadable query values do not interrupt successful responses',
    () async {
      final collector = ManaDioCollector();
      addTearDown(collector.dispose);
      final response = Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/items',
          queryParameters: {'value': _UnprintableQueryValue()},
        ),
        statusCode: 200,
        data: 'response body',
      );
      final dio = Dio()
        ..interceptors.addAll([
          collector,
          InterceptorsWrapper(
            onRequest: (_, handler) => handler.resolve(response, true),
          ),
        ]);
      addTearDown(() => dio.close(force: true));

      expect(await dio.fetch<dynamic>(response.requestOptions), same(response));
      final record = collector.data.single;
      expect(() => record.requestOptions.uri, returnsNormally);
      expect(record.statusCode, 200);
      expect(record.data, 'response body');
      expect(record.extra[ManaDioCollector.truncatedKey], isTrue);
      expect(() => formatCurl(record.requestOptions), throwsUnsupportedError);
    },
  );

  test(
    'request timing accepts immutable extras without changing their map',
    () {
      final collector = ManaDioCollector();
      addTearDown(collector.dispose);
      const extra = <String, dynamic>{'business': 'value'};
      final request = RequestOptions(path: '/items', extra: extra);
      final handler = RequestInterceptorHandler();

      collector.onRequest(request, handler);

      expect(handler.isCompleted, isTrue);
      expect(request.extra['business'], 'value');
      expect(request.extra[ManaDioCollector.startTimeKey], isA<DateTime>());
      expect(extra, {'business': 'value'});
    },
  );

  test('disposed request interceptors forward without modifying extras', () {
    final collector = ManaDioCollector()..dispose();
    final request = RequestOptions(path: '/items');
    final handler = RequestInterceptorHandler();

    collector.onRequest(request, handler);

    expect(handler.isCompleted, isTrue);
    expect(request.extra, isEmpty);
  });

  test('capture failures never replace the business response', () async {
    final collector = ManaDioCollector();
    addTearDown(collector.dispose);
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/ok'),
      statusCode: 200,
      headers: _UnreadableHeaders(),
      data: 'business payload',
    );
    final dio = Dio()
      ..interceptors.addAll([
        collector,
        InterceptorsWrapper(
          onRequest: (_, handler) => handler.resolve(response, true),
        ),
      ]);
    addTearDown(() => dio.close(force: true));

    final result = await dio.fetch<dynamic>(response.requestOptions);
    expect(result.data, 'business payload');
    final record = collector.data.single;
    expect(record.data, 'business payload');
    expect(record.statusCode, 200);
    expect(record.headers.map, isEmpty);
    expect(record.extra[ManaDioCollector.truncatedKey], isTrue);
  });

  test('unreadable response bodies do not interrupt the Dio pipeline', () {
    final collector = ManaDioCollector();
    addTearDown(collector.dispose);
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/'),
      data: _UnreadableMap(),
    );
    final handler = ResponseInterceptorHandler();
    collector.onResponse(response, handler);
    expect(handler.isCompleted, isTrue);
    final record = collector.data.single;
    expect(record.statusCode, response.statusCode);
    expect(record.extra[ManaDioCollector.truncatedKey], isTrue);
    expect(record.data, contains('omitted'));
    expect(response.data, isA<_UnreadableMap>());
  });

  test('unreadable request data cannot be exported as a complete request', () {
    final collector = ManaDioCollector();
    addTearDown(collector.dispose);
    collector.addResponse(
      Response<dynamic>(
        requestOptions: RequestOptions(path: '/', data: _UnreadableMap()),
      ),
    );
    final record = collector.data.single;
    expect(record.extra[ManaDioCollector.truncatedKey], isTrue);
    expect(() => formatCurl(record.requestOptions), throwsUnsupportedError);
    expect(() => formatHttp(record.requestOptions), throwsUnsupportedError);
  });

  test('unreadable log values preserve subsequent capture', () {
    final collector = ManaLogCollector();
    addTearDown(collector.dispose);
    collector.output(OutputEvent(LogEvent(Level.info, _UnreadableMap()), []));
    collector.output(OutputEvent(LogEvent(Level.info, 'next'), []));
    expect(collector.data, hasLength(2));
    expect((collector.data.first as CapturedLogEvent).truncated, isTrue);
    expect(formatLog(collector.data.first, verbose: true), contains('omitted'));
    expect(collector.data.last.origin.message, 'next');
  });
  test(
    'network snapshots detach application bodies, headers and callbacks',
    () {
      final collector = ManaDioCollector();
      addTearDown(collector.dispose);
      final payload = {
        'items': ['original'],
      };
      final request = RequestOptions(
        path: 'https://example.test/items',
        method: 'POST',
        contentType: 'application/json',
        data: payload,
        headers: {'X-Test': 'original'},
        extra: {'applicationObject': Object()},
        onSendProgress: (_, _) {},
        cancelToken: CancelToken(),
      );
      final response = Response(
        requestOptions: request,
        data: payload,
        statusCode: 200,
      );
      collector.addResponse(response);
      final record = collector.data.single;
      payload['items']!.add('changed');
      request.headers['X-Test'] = 'changed';
      expect(record.requestOptions, isNot(same(request)));
      expect(record.data, {
        'items': ['original'],
      });
      expect(record.requestOptions.data, {
        'items': ['original'],
      });
      expect(record.requestOptions.headers['X-Test'], 'original');
      expect(record.requestOptions.cancelToken, isNull);
      expect(record.requestOptions.onSendProgress, isNull);
      expect(
        record.requestOptions.extra.containsKey('applicationObject'),
        isFalse,
      );
      expect(record.extra[ManaDioCollector.truncatedKey], isFalse);
      expect(response.extra, isEmpty);
      expect(
        formatCurl(record.requestOptions),
        contains('--data-raw \'{"items":["original"]}\''),
      );
    },
  );

  test('network entry and total budgets truncate and evict without mutating the source', () {
    final collector = ManaDioCollector(maxEntryBytes: 1024, maxBytes: 1500);
    addTearDown(collector.dispose);
    final original = '界' * 10000;
    for (var i = 0; i < 4; i++) {
      collector.addResponse(
        Response(
          requestOptions: RequestOptions(path: 'https://example.test/$i'),
          data: original,
        ),
      );
    }
    expect(collector.data, hasLength(1));
    expect(collector.retainedBytes, lessThanOrEqualTo(1500));
    final record = collector.data.single;
    expect(
      record.extra[ManaDioCollector.capturedBytesKey],
      lessThanOrEqualTo(1024),
    );
    expect(record.extra[ManaDioCollector.truncatedKey], isTrue);
    expect((record.data as String).length, lessThan(original.length));
    expect(
      formatCurl(record.requestOptions),
      contains('https://example.test/3'),
    );
    collector.clear();
    expect(collector.retainedBytes, 0);
    collector.addResponse(
      Response(
        requestOptions: RequestOptions(path: '/'),
        data: 'new',
      ),
    );
    collector.dispose();
    expect(collector.retainedBytes, 0);
  });

  test('truncated request bodies and custom encoders cannot be replayed', () {
    final collector = ManaDioCollector(maxEntryBytes: 1024);
    addTearDown(collector.dispose);
    final request = RequestOptions(
      path: 'https://example.test',
      data: 'x' * 10000,
    );
    collector.addResponse(Response(requestOptions: request));
    final snapshot = collector.data.last.requestOptions;
    expect(() => formatCurl(snapshot), throwsUnsupportedError);
    expect(() => formatHttp(snapshot), throwsUnsupportedError);
    expect(request.data, hasLength(10000));
    var calls = 0;
    collector.addResponse(
      Response(
        requestOptions: RequestOptions(
          path: 'https://example.test',
          data: 'input',
          requestEncoder: (value, options) {
            calls++;
            return [1, 2];
          },
        ),
      ),
    );
    expect(collector.data.last.requestOptions.requestEncoder, isNull);
    expect(
      () => formatCurl(collector.data.last.requestOptions),
      throwsUnsupportedError,
    );
    expect(calls, 0);
  });

  test(
    'binary and multipart captures do not retain upload buffers or streams',
    () {
      final collector = ManaDioCollector(maxEntryBytes: 1024);
      addTearDown(collector.dispose);
      final bytes = Uint8List(10000)..[0] = 42;
      collector.addResponse(
        Response(
          requestOptions: RequestOptions(path: '/'),
          data: bytes,
        ),
      );
      final captured = collector.data.last.data as Uint8List;
      expect(captured.length, lessThan(1024));
      captured[0] = 7;
      expect(bytes[0], 42);
      var listens = 0;
      final stream = Stream<List<int>>.multi((controller) {
        listens++;
        controller.close();
      });
      final form = FormData()
        ..files.add(
          MapEntry(
            'file',
            MultipartFile.fromStream(
              () => stream,
              10000,
              filename: 'example.bin',
            ),
          ),
        );
      collector.addResponse(
        Response(
          requestOptions: RequestOptions(path: '/', data: form),
        ),
      );
      expect(listens, 0);
      final snapshot = collector.data.last;
      expect(formatBody(snapshot.requestOptions.data), contains('example.bin'));
      expect(snapshot.extra[ManaDioCollector.truncatedKey], isTrue);
      expect(() => formatCurl(snapshot.requestOptions), throwsUnsupportedError);
    },
  );

  test('cyclic and deeply nested captures stay bounded and printable', () {
    final collector = ManaDioCollector(maxEntryBytes: 1024);
    addTearDown(collector.dispose);
    final cyclic = <String, Object?>{};
    cyclic['self'] = cyclic;
    collector.addResponse(
      Response(
        requestOptions: RequestOptions(path: '/'),
        data: cyclic,
      ),
    );
    expect(collector.data.last.extra[ManaDioCollector.truncatedKey], isTrue);
    expect(formatBody(collector.data.last.data), contains('omitted'));
    expect(collector.retainedBytes, lessThanOrEqualTo(1024));
  });

  test('log snapshots bound messages, errors, stacks and formatted lines', () {
    final collector = ManaLogCollector(maxEntryBytes: 1024, maxBytes: 1500);
    addTearDown(collector.dispose);
    final original = '😀' * 10000;
    for (var i = 0; i < 4; i++) {
      collector.output(
        OutputEvent(
          LogEvent(
            Level.error,
            original,
            error: original,
            stackTrace: StackTrace.fromString(original),
          ),
          [original],
        ),
      );
    }
    expect(collector.data, hasLength(1));
    final event = collector.data.single as CapturedLogEvent;
    expect(event.truncated, isTrue);
    expect(event.capturedBytes, lessThanOrEqualTo(1024));
    expect(collector.retainedBytes, lessThanOrEqualTo(1500));
    expect(formatLog(event, verbose: true).length, lessThan(1024));
    expect(
      (event.origin.message as String).codeUnits.last,
      isNot(inInclusiveRange(0xD800, 0xDBFF)),
    );
    collector.clear();
    expect(collector.retainedBytes, 0);
  });

  test(
    'lazy log snapshots use formatted output without keeping the callback',
    () {
      final collector = ManaLogCollector();
      addTearDown(collector.dispose);
      var calls = 0;
      collector.output(
        OutputEvent(
          LogEvent(Level.info, () {
            calls++;
            return Object();
          }),
          ['\x1B[31mformatted\x1B[0m'],
        ),
      );
      expect(calls, 0);
      expect(collector.data.single.origin.message, 'formatted');
      expect(formatLog(collector.data.single, verbose: true), 'formatted');
    },
  );

  test('large null-filled containers still consume the capture budget', () {
    final collector = ManaDioCollector(maxEntryBytes: 1024);
    addTearDown(collector.dispose);
    collector.addResponse(
      Response(
        requestOptions: RequestOptions(path: '/'),
        data: List<Object?>.filled(100000, null),
      ),
    );
    final record = collector.data.single;
    expect((record.data as List).length, lessThan(128));
    expect(record.extra[ManaDioCollector.truncatedKey], isTrue);
    expect(collector.retainedBytes, lessThanOrEqualTo(1024));
  });

  test('snapshots preserve non-string-typed map encoding semantics', () {
    final collector = ManaDioCollector();
    addTearDown(collector.dispose);
    final request = RequestOptions(
      path: 'https://example.test',
      contentType: 'text/plain',
      data: <Object, Object>{'a': 'b'},
    );
    collector.addResponse(Response(requestOptions: request));
    expect(
      formatCurl(collector.data.single.requestOptions),
      formatCurl(request),
    );
    expect(collector.data.single.extra[ManaDioCollector.truncatedKey], isFalse);
  });

  test('forwarding snapshots preserves truncation and replay restrictions', () {
    final firstNetwork = ManaDioCollector(maxEntryBytes: 1024);
    final nextNetwork = ManaDioCollector();
    final firstLogs = ManaLogCollector(maxEntryBytes: 1024);
    final nextLogs = ManaLogCollector();
    addTearDown(firstNetwork.dispose);
    addTearDown(nextNetwork.dispose);
    addTearDown(firstLogs.dispose);
    addTearDown(nextLogs.dispose);
    firstNetwork.addResponse(
      Response(
        requestOptions: RequestOptions(path: '/', data: 'x' * 10000),
      ),
    );
    nextNetwork.addResponse(firstNetwork.data.single);
    expect(
      nextNetwork.data.single.extra[ManaDioCollector.truncatedKey],
      isTrue,
    );
    expect(
      () => formatCurl(nextNetwork.data.single.requestOptions),
      throwsUnsupportedError,
    );
    firstLogs.output(OutputEvent(LogEvent(Level.info, 'x' * 10000), []));
    nextLogs.output(firstLogs.data.single);
    expect((nextLogs.data.single as CapturedLogEvent).truncated, isTrue);
  });

  test('invalid capture budgets fail eagerly', () {
    expect(() => ManaDioCollector(maxEntryBytes: 0), throwsArgumentError);
    expect(() => ManaLogCollector(maxBytes: 128), throwsArgumentError);
  });
}
