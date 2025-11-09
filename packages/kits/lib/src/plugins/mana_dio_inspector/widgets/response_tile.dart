import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ResponseTile extends StatelessWidget {
  final Response response;

  final GestureTapCallback? onTap;

  const ResponseTile({super.key, required this.response, this.onTap});

  @override
  Widget build(BuildContext context) {
    final RequestOptions requestOptions = response.requestOptions;

    final DateTime? requestStartTime =
        requestOptions.extra['manaDioRequestStartTime'];
    final DateTime? requestEndTime = response.extra['manaDioRequestEndTime'];

    Duration? duration;
    if (requestStartTime != null && requestEndTime != null) {
      duration = requestEndTime.difference(requestStartTime);
    }

    String formattedRequestTime =
        requestStartTime != null
            ? '${requestStartTime.hour.toString().padLeft(2, '0')}:${requestStartTime.minute.toString().padLeft(2, '0')}:${requestStartTime.second.toString().padLeft(2, '0')}.${requestStartTime.millisecond.toString().padLeft(3, '0')}'
            : 'N/A';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      shape: const Border(),
      title: _buildTitle(
        formattedRequestTime,
        requestOptions.method,
        response.statusCode,
        duration,
      ),
      subtitle: _buildSubtitle(requestOptions.uri.toString()),
      onTap: onTap,
    );
  }

  // ExpansionTile Title: 请求时间、请求方法、响应状态码、请求耗时
  Widget _buildTitle(
    String requestTime,
    String method,
    int? statusCode,
    Duration? duration,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 8,
      children: [
        // 时间
        Text(
          requestTime,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        // 方法
        Text(
          method,
          style: TextStyle(
            color: _getMethodColor(method),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        // 状态码
        if (statusCode != null)
          Text(
            statusCode.toString(),
            style: TextStyle(
              color: _getStatusCodeColor(statusCode),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        // 耗时
        if (duration != null)
          Text(
            '${duration.inMilliseconds}ms',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
      ],
    );
  }

  //
  Widget _buildSubtitle(String url) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        url,
        style: TextStyle(fontSize: 12, color: Colors.black87),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusCodeColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return Colors.green;
    } else if (statusCode >= 300 && statusCode < 400) {
      return Colors.orange;
    } else if (statusCode >= 400 && statusCode < 500) {
      return Colors.red;
    } else if (statusCode >= 500) {
      return Colors.purple;
    }
    return Colors.grey;
  }
}
