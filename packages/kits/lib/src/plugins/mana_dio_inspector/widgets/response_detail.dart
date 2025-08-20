import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';
import 'package:flutter_mana_kits/src/icons/kit_icons.dart';

class ResponseDetail extends StatelessWidget with I18nMixin {
  final Response response;

  final VoidCallback? onClose;

  const ResponseDetail({super.key, required this.response, this.onClose});

  static final _divider = Divider(height: 1, color: Colors.grey.shade200);

  @override
  Widget build(BuildContext context) {
    final RequestOptions requestOptions = response.requestOptions;

    final DateTime? requestStartTime = requestOptions.extra['manaDioRequestStartTime'];
    final DateTime? requestEndTime = response.extra['manaDioRequestEndTime'];

    Duration duration = Duration.zero;
    if (requestStartTime != null && requestEndTime != null) {
      duration = requestEndTime.difference(requestStartTime);
    }

    String formattedRequestTime = requestStartTime != null
        ? '${requestStartTime.hour.toString().padLeft(2, '0')}:${requestStartTime.minute.toString().padLeft(2, '0')}:${requestStartTime.second.toString().padLeft(2, '0')}.${requestStartTime.millisecond.toString().padLeft(3, '0')}'
        : 'N/A';

    // 请求详情
    final Map<String, String> details = {
      'URL': requestOptions.uri.toString(),
      'Method': requestOptions.method.toString(),
      'Time': formattedRequestTime,
      'Duration': '${duration.inMilliseconds}ms',
      'Status': response.statusCode?.toString() ?? 'N/A',
      'Message': response.statusMessage ?? 'N/A',
    };

    // 请求头
    final Map<String, String> requestHeaders =
        requestOptions.headers.map((key, value) => MapEntry(key, value.toString()));

    // 请求体
    var requestBody = '';
    if (requestOptions.data != null) {
      try {
        requestBody = JsonEncoder.withIndent('  ').convert(requestOptions.data);
      } catch (e) {
        requestBody = requestOptions.data.toString();
      }
    }

    // 响应头
    final Map<String, String> responseHeaders =
        response.headers.map.map((key, value) => MapEntry(key, value.join(';')));

    // 响应体
    var responseBody = '';
    if (response.data != null) {
      try {
        responseBody = JsonEncoder.withIndent('  ').convert(response.data);
      } catch (e) {
        responseBody = response.data.toString();
      }
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _divider,
          Row(
            children: [
              IconButton(
                icon: Icon(
                  KitIcons.close,
                  color: Colors.grey,
                  size: 16,
                ),
                style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: onClose,
              ),
              Expanded(
                child: Text(
                  requestOptions.uri.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              MorePopupMenu(
                response: response,
              ),
            ],
          ),
          _divider,
          TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.transparent,
            dividerHeight: 0,
            isScrollable: false,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                text: t('dio_inspector.detail'),
                height: 36,
              ),
              Tab(text: t('dio_inspector.request'), height: 36),
              Tab(text: t('dio_inspector.response'), height: 36),
            ],
          ),
          _divider,
          Expanded(
            child: TabBarView(
              children: [
                _buildDetails(details),
                _buildRequestDetails(requestHeaders, requestBody),
                _buildResponseDetails(responseHeaders, responseBody),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(Map<String, String> data) {
    final children = data.entries.map(
      (row) {
        return TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(row.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: SelectableText(row.value, style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        );
      },
    ).toList();

    return Table(
      border: TableBorder(
        verticalInside: BorderSide(color: Colors.grey.shade200),
        horizontalInside: BorderSide(color: Colors.grey.shade200),
        top: BorderSide(color: Colors.grey.shade200),
        bottom: BorderSide(color: Colors.grey.shade200),
      ),
      columnWidths: {
        0: FixedColumnWidth(120),
        1: FlexColumnWidth(),
      },
      children: children,
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }

  // 构建详情
  Widget _buildDetails(Map<String, String> details) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Text(t('dio_inspector.request_details'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          _buildTable(details),
        ],
      ),
    );
  }

  // 构建请求详情
  Widget _buildRequestDetails(Map<String, String> requestHeaders, String requestBody) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(t('dio_inspector.request_header'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          _buildTable(requestHeaders),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(t('dio_inspector.request_body'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          _buildCodeBlock(requestBody),
        ],
      ),
    );
  }

  // 构建响应详情
  Widget _buildResponseDetails(Map<String, String> responseHeaders, String responseBody) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Text(t('dio_inspector.response_header'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          _buildTable(responseHeaders),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(t('dio_inspector.response_body'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          _buildCodeBlock(responseBody),
        ],
      ),
    );
  }
}

/// 通用“更多”弹出菜单
class MorePopupMenu extends StatelessWidget {
  final Response response;

  const MorePopupMenu({
    super.key,
    required this.response,
  });

  static const List<String> items = ['复制URL', '复制cURL', '复制HTTP', '复制响应'];

  @override
  Widget build(BuildContext context) {
    final request = response.requestOptions;
    final method = request.method;
    final url = request.uri.toString();

    // 请求头
    final Map<String, String> requestHeaders = request.headers.map((key, value) => MapEntry(key, value.toString()));

    requestHeaders.remove('content-length');

    // 请求体
    var requestBody = '';
    if (request.data != null) {
      try {
        requestBody = jsonEncode(request.data);
      } catch (e) {
        requestBody = request.data.toString();
      }
    }

    // 响应体
    var responseBody = '';
    if (response.data != null) {
      try {
        responseBody = JsonEncoder.withIndent('  ').convert(response.data);
      } catch (e) {
        responseBody = response.data.toString();
      }
    }

    /// 如果下拉框存在的时候，热更新会报错
    /// https://github.com/flutter/flutter/pull/171970
    return PopupMenuButton<int>(
      icon: const Icon(KitIcons.more, size: 16, color: Colors.grey),
      color: Colors.white,
      elevation: 2,
      padding: EdgeInsets.zero,
      menuPadding: EdgeInsets.zero,
      popUpAnimationStyle: AnimationStyle.noAnimation,
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      itemBuilder: (_) => List.generate(
        items.length,
        (index) => PopupMenuItem<int>(
          value: index,
          height: 34,
          child: Text(items[index], style: const TextStyle(fontSize: 12)),
        ),
      ),
      onSelected: (index) {
        String textToCopy = '';

        switch (index) {
          case 0:
            textToCopy = request.uri.toString();
            break;
          case 1:
            final headers = requestHeaders.entries.map((e) => '\t-H "${e.key}: ${e.value}"').join(' \\\n');
            textToCopy = 'curl -X $method "$url" \\\n$headers \\\n\t-d \'$requestBody\'';
            break;
          case 2:
            final headers = requestHeaders.entries.map((e) => '${e.key}: ${e.value}').join('\n');
            textToCopy = '$method $url\n$headers\n\n$requestBody';
            break;
          case 3:
            textToCopy = responseBody;
            break;
        }

        Clipboard.setData(ClipboardData(text: textToCopy));
      },
    );
  }
}
