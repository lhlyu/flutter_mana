import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/request_format.dart';
import 'package:flutter_test/flutter_test.dart';

class _CaptureAdapter implements HttpClientAdapter {
  List<int> bytes = [];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    bytes = await requestStream?.expand((chunk) => chunk).toList() ?? [];
    return ResponseBody.fromString('ok', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  for (final (name, contentType, data) in <(String, String, Object)>[
    ('plain list', 'text/plain', ['alpha', 'beta']),
    ('JSON list', 'application/json', ['alpha', 'beta']),
    ('vendor JSON', 'application/vnd.example+json', {'hello': '中文'}),
    ('plain map', 'text/plain', <String, dynamic>{'a': 'x y'}),
    (
      'form map',
      Headers.formUrlEncodedContentType,
      <String, dynamic>{
        'a': 'x y',
        'tags': ['a', 'b'],
      },
    ),
    ('raw string', 'application/json', '{ "raw": true }'),
  ]) {
    test('$name exports the exact body sent by Dio', () async {
      final adapter = _CaptureAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      try {
        final response = await dio.post<Object?>(
          'https://example.test',
          data: data,
          options: Options(contentType: contentType),
        );
        final body = utf8.decode(adapter.bytes);
        expect(
          formatCurl(response.requestOptions),
          contains("--data-raw '$body'"),
        );
        expect(
          formatHttp(response.requestOptions).split('\r\n\r\n').last,
          body,
        );
      } finally {
        dio.close();
      }
    });
  }

  test('custom encoders are rejected without executing application code', () {
    var calls = 0;
    final request = RequestOptions(
      path: '/',
      data: 'text',
      requestEncoder: (value, options) {
        calls++;
        return [1, 2];
      },
    );
    expect(() => formatCurl(request), throwsUnsupportedError);
    expect(() => formatHttp(request), throwsUnsupportedError);
    expect(calls, 0);
  });
}
