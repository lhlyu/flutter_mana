import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import '../../ui/kit_ui.dart';
import 'utils/get_device_info.dart';
import 'widgets/device_info_content.dart';

class ManaDeviceInfo extends BuiltinKit {
  ManaDeviceInfo()
    : super(
        name: 'mana_device_info',
        title: 'Device Info',
        chineseTitle: '设备信息',
        icon: .device,
      );
  @override
  Widget buildWidget(BuildContext context) => KitWindow(
    name: name,
    showBarrier: false,
    content: KitAsync<Map<String, Object?>>(
      load: getDeviceInfo,
      builder: (context, data) => DeviceInfoContent(data: data),
    ),
  );
}
