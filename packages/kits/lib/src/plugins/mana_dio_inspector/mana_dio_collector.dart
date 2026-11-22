import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../../data/bounded_collector.dart';
import '../../data/capture_budget.dart';

/// Attach the same instance to Dio and ManaDioInspector.
class ManaDioCollector extends BoundedCollector<Response<dynamic>>
    implements Interceptor {
  ManaDioCollector({
    super.capacity,
    super.maxBytes = 8 * 1024 * 1024,
    this.maxEntryBytes = 256 * 1024,
  }) {
    CaptureBudget(math.min(maxEntryBytes, maxBytes));
  }

  final int maxEntryBytes;
  static const startTimeKey = 'manaDioRequestStartTime';
  static const endTimeKey = 'manaDioRequestEndTime';
  static const errorKey = 'manaDioError';
  static const truncatedKey = 'manaDioCaptureTruncated';
  static const capturedBytesKey = 'manaDioCapturedBytes';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[startTimeKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    addResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    _capture(
      error.response ?? Response<dynamic>(requestOptions: error.requestOptions),
      error: error.message ?? error.type.name,
    );
    handler.next(error);
  }

  void addResponse(Response<dynamic> response) => add(response);

  @override
  void add(Response<dynamic> value, {int sizeBytes = 0}) => _capture(value);

  void _capture(Response<dynamic> response, {String? error}) {
    if (isDisposed) return;
    final budget = CaptureBudget(math.min(maxEntryBytes, maxBytes));
    final source = response.requestOptions;
    final rawPath = budget.text(source.uri.toString());
    final path = Uri.tryParse(rawPath) == null ? '' : rawPath;
    final method = budget.text(source.method);
    final headers = budget.copy(source.headers) as Map<String, dynamic>? ?? {};
    final data = _body(source.data, budget);
    final request = RequestOptions(
      path: path,
      method: method,
      headers: headers,
      data: data,
      listFormat: source.listFormat,
      sourceStackTrace: StackTrace.empty,
      extra: {
        if (source.extra[startTimeKey] case final DateTime start)
          startTimeKey: start,
        if (budget.truncated ||
            source.requestEncoder != null ||
            source.extra[captureExportUnavailableKey] == true)
          captureExportUnavailableKey: true,
      },
    );
    budget.truncated = budget.truncated || response.extra[truncatedKey] == true;
    final statusMessage = response.statusMessage == null
        ? null
        : budget.text(response.statusMessage!);
    final capturedError = budget.copy(error ?? response.extra[errorKey]);
    final responseHeaders = <String, List<String>>{};
    for (final entry in response.headers.map.entries) {
      if (budget.remaining < 64) {
        budget.truncated = true;
        break;
      }
      final key = budget.text(entry.key);
      final values = budget.copy(entry.value) as List? ?? [];
      responseHeaders[key] = values.whereType<String>().toList();
    }
    final body = _body(response.data, budget);
    final record = Response<dynamic>(
      requestOptions: request,
      statusCode: response.statusCode,
      statusMessage: statusMessage,
      isRedirect: response.isRedirect,
      headers: Headers.fromMap(responseHeaders),
      data: body,
      extra: {
        endTimeKey: response.extra[endTimeKey] is DateTime
            ? response.extra[endTimeKey]
            : DateTime.now(),
        errorKey: ?capturedError,
        truncatedKey: budget.truncated,
        capturedBytesKey: budget.usedBytes,
      },
    );
    super.add(record, sizeBytes: budget.usedBytes);
  }

  Object? _body(Object? value, CaptureBudget budget) {
    if (value is! FormData) return budget.copy(value);
    final form = FormData();
    for (final field in value.fields) {
      if (budget.remaining < 64) {
        budget.truncated = true;
        break;
      }
      form.fields.add(
        MapEntry(budget.text(field.key), budget.text(field.value)),
      );
    }
    for (final file in value.files) {
      budget.truncated = true;
      if (budget.remaining < 64) break;
      form.files.add(
        MapEntry(
          budget.text(file.key),
          MultipartFile.fromBytes(
            [],
            filename: budget.text(file.value.filename ?? 'file'),
          ),
        ),
      );
    }
    return form;
  }
}
