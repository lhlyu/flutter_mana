import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

String formatBody(Object? data, {bool pretty = true}) {
  if (data == null) return '';
  if (data is String) return data;
  if (data is FormData) {
    return <String>[
      for (final field in data.fields) '${field.key}=${field.value}',
      for (final file in data.files)
        '${file.key}=<${file.value.filename ?? 'file'}>',
    ].join('\n');
  }
  try {
    return (pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder())
        .convert(data);
  } on JsonUnsupportedObjectError {
    return data.toString();
  }
}

String _requestBody(RequestOptions request) {
  final data = request.data;
  if (data is Map<String, dynamic> &&
      !Transformer.isJsonMimeType(request.contentType)) {
    return Transformer.urlEncodeMap(data, request.listFormat);
  }
  return formatBody(data, pretty: false);
}

String _shellQuote(String value) => "'${value.replaceAll("'", "'\"'\"'")}'";

/// Quotes every shell argument and keeps strings as their original body.
String formatCurl(RequestOptions request) {
  final data = request.data;
  if (data is Stream ||
      data is TypedData ||
      (data is FormData && data.files.isNotEmpty)) {
    throw UnsupportedError('cURL unavailable for streamed or binary bodies');
  }
  final parts = [
    'curl',
    '-X',
    _shellQuote(request.method),
    _shellQuote(request.uri.toString()),
  ];
  for (final header in request.headers.entries) {
    final key = header.key.toLowerCase();
    if (key == 'content-length' ||
        (data is FormData && key == 'content-type')) {
      continue;
    }
    parts.addAll(['-H', _shellQuote('${header.key}: ${header.value}')]);
  }
  if (request.data != null && request.data is! FormData) {
    parts.addAll(['--data-raw', _shellQuote(_requestBody(request))]);
  } else if (request.data case final FormData form) {
    for (final field in form.fields) {
      parts.addAll([
        '--form-string',
        _shellQuote('${field.key}=${field.value}'),
      ]);
    }
  }
  return parts.join(' ');
}

String formatHttp(RequestOptions request) => [
  '${request.method} ${request.uri} HTTP/1.1',
  for (final entry in request.headers.entries) '${entry.key}: ${entry.value}',
  '',
  _requestBody(request),
].join('\r\n');
