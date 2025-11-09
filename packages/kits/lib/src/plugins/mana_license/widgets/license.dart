import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:package_info_plus/package_info_plus.dart';

class License extends StatefulWidget {
  final String name;

  const License({super.key, required this.name});

  @override
  State<License> createState() => _LicenseState();
}

class _LicenseState extends State<License> {
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
              appBarTheme: AppBarTheme(elevation: 0, scrolledUnderElevation: 0, backgroundColor: Colors.white),
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
