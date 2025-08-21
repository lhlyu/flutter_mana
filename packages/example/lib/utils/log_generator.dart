import 'dart:convert';
import 'dart:math';

import 'package:example/utils/json_demo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:logger/logger.dart';

class ReleaseFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return event.level.value >= level!.value;
  }
}

class LogGenerator {
  static final Logger _logger = Logger(level: Level.all, filter: ReleaseFilter(), output: ManaLogCollector());
  static final Random _random = Random();

  static void generateRandomLog() {
    final levels = [Level.debug, Level.info, Level.warning, Level.error];
    final level = levels[_random.nextInt(levels.length)];

    final messages = [
      "用户登录成功",
      "网络请求超时",
      "数据缓存失败",
      "权限请求被拒绝",
      "收到推送通知: ${_random.nextInt(1000)}",
      "页面跳转至 /settings",
      "数据库查询耗时 ${_random.nextInt(500)}ms",
      "内存使用量: ${_random.nextInt(80) + 20}%",
      "服务器响应错误: 404",
      "位置更新: (${_random.nextDouble() * 180 - 90}, ${_random.nextDouble() * 360 - 180})",
      jsonEncode(jsonDemo),
    ];
    final message = messages[_random.nextInt(messages.length)];

    if (_random.nextDouble() > 0.9) {
      debugPrint('[debugPrint] $message');
      return;
    }

    final error = _random.nextBool() ? null : Exception("随机异常 ${_random.nextInt(100)}");
    final stackTrace = _random.nextDouble() > 0.7 ? StackTrace.current : null;

    _logger.log(level, message, error: error, stackTrace: stackTrace);
  }
}
