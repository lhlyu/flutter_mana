import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../ui/kit_ui.dart';

class PackageInfoContent extends StatelessWidget {
  const PackageInfoContent({super.key, required this.info});
  final PackageInfo info;

  @override
  Widget build(BuildContext context) {
    String text(String key) => kitText(context, 'package.$key');
    final version = [
      if (info.version.isNotEmpty) info.version,
      if (info.buildNumber.isNotEmpty) '(${info.buildNumber})',
    ].join(' ');
    return KitInfoPage(
      title: text('title'),
      headline: info.appName.isEmpty ? text('title') : info.appName,
      subtitle: version.isEmpty ? null : version,
      data: {
        'appName': info.appName,
        'packageName': info.packageName,
        'version': info.version,
        'buildNumber': info.buildNumber,
        'buildSignature': info.buildSignature,
        'installerStore': info.installerStore,
        'installTime': info.installTime?.toIso8601String(),
        'updateTime': info.updateTime?.toIso8601String(),
      },
      children: [
        KitInfoSection(
          title: text('identity'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KitInfoField(
                label: text('package_name'),
                value: info.packageName,
                copyText: info.packageName.isEmpty ? null : info.packageName,
              ),
              KitInfoField(label: text('version'), value: info.version),
              KitInfoField(
                label: text('build_number'),
                value: info.buildNumber,
              ),
            ],
          ),
        ),
        KitInfoSection(
          title: text('installation'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KitInfoField(
                label: text('installer'),
                value: info.installerStore,
              ),
              KitInfoField(
                label: text('installed'),
                value: _date(info.installTime),
              ),
              KitInfoField(
                label: text('updated'),
                value: _date(info.updateTime),
              ),
              KitInfoField(
                label: text('signature'),
                value: info.buildSignature,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _date(DateTime? value) => value
      ?.toLocal()
      .toIso8601String()
      .split('.')
      .first
      .replaceFirst('T', ' ');
}
