import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../builtin_kit.dart';
import '../../ui/kit_ui.dart';
import 'widgets/package_info_content.dart';

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
      builder: (context, info) => PackageInfoContent(info: info),
    ),
  );
}
