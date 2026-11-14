import 'package:dio/dio.dart';

import '../../data/bounded_collector.dart';

/// Attach the same instance to Dio and ManaDioInspector.
class ManaDioCollector extends BoundedCollector<Response<dynamic>>
    implements Interceptor {
  ManaDioCollector({super.capacity});
  static const startTimeKey = 'manaDioRequestStartTime';
  static const endTimeKey = 'manaDioRequestEndTime';
  static const errorKey = 'manaDioError';
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
    final response =
        error.response ??
        Response<dynamic>(requestOptions: error.requestOptions);
    response.extra[errorKey] = error.message ?? error.type.name;
    addResponse(response);
    handler.next(error);
  }

  void addResponse(Response<dynamic> response) {
    response.extra[endTimeKey] = DateTime.now();
    add(response);
  }
}
