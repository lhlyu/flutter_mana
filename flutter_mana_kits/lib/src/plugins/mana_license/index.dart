import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'icon.dart';

class ManaLicense extends StatefulWidget implements ManaPluggable {
  const ManaLicense({super.key});

  @override
  State<ManaLicense> createState() => _ManaLicenseState();

  @override
  Widget? buildWidget(BuildContext? context) => this;

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '许可';
      default:
        return 'License';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_license';

  @override
  void onTrigger() {}

  @override
  Future<void> initialize() async {}
}

class _ManaLicenseState extends State<ManaLicense> {
  static Future<PackageInfo> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    return info;
  }

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: widget.name,
      initialHeight: double.infinity,
      initialWidth: 600,
      showBarrier: false,
      content: FutureBuilder(
        future: _loadInfo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Theme(
            data: Theme.of(context).copyWith(
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppBarTheme(
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              cardColor: Colors.white,
            ),
            child: LicensePage(
              applicationName: snapshot.requireData.appName,
              applicationIcon: FlutterLogo(),
              applicationVersion: 'v${snapshot.requireData.version}+${snapshot.requireData.buildNumber}',
              applicationLegalese: snapshot.requireData.packageName,
            ),
          );
        },
      ),
    );
  }
}
