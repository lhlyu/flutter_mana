import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../builtin_kit.dart';
import '../../ui/kit_ui.dart';

class ManaPackageInfo extends BuiltinKit {
  ManaPackageInfo()
    : super(
        name: 'mana_package_info',
        title: 'Package Info',
        chineseTitle: '包信息',
        icon: .package,
      );
  @override
  Widget buildWidget(BuildContext context) => KitWindow(
    name: name,
    showBarrier: false,
    content: KitAsync<PackageInfo>(
      load: PackageInfo.fromPlatform,
      builder: (context, info) => SingleChildScrollView(
        child: KitDataTable({
          'appName': info.appName,
          'packageName': info.packageName,
          'version': info.version,
          'buildNumber': info.buildNumber,
          'buildSignature': info.buildSignature,
          'installerStore': info.installerStore,
          'installTime': info.installTime,
          'updateTime': info.updateTime,
        }),
      ),
    ),
  );
}
