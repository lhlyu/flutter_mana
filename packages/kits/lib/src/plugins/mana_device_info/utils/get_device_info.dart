import 'package:device_info_plus/device_info_plus.dart';

Future<Map<String, Object?>> getDeviceInfo({DeviceInfoPlugin? plugin}) async =>
    (await (plugin ?? DeviceInfoPlugin()).deviceInfo).data;
