import 'package:flutter/widgets.dart';

import '../builtin_kit.dart';
import '../../ui/kit_ui.dart';
import 'utils/get_device_info.dart';

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
      builder: (context, data) =>
          SingleChildScrollView(child: KitDataTable(data)),
    ),
  );
}
