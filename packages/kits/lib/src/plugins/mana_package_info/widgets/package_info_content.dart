import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PackageInfoContent extends StatelessWidget {
  const PackageInfoContent({super.key});

  static const _borderSide = BorderSide(width: 1, color: Color(0xFFE0E0E0));
  static const _tableBorder = TableBorder(
    top: _borderSide,
    bottom: _borderSide,
    horizontalInside: _borderSide,
    verticalInside: _borderSide,
  );

  /// 把 PackageInfo 转成 Map
  static Future<Map<String, String>> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    return {
      'appName': info.appName,
      'packageName': info.packageName,
      'version': info.version,
      'buildNumber': info.buildNumber,
      'buildSignature': info.buildSignature,
      'installerStore': info.installerStore ?? '-',
      'installTime': info.installTime?.toString() ?? '-',
      'updateTime': info.updateTime?.toString() ?? '-',
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _loadInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        return SelectionArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Table(
              border: _tableBorder,
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
              },
              children:
                  data.entries
                      .map(
                        (e) => TableRow(
                          children: [_Cell(e.key, bold: true), _Cell(e.value)],
                        ),
                      )
                      .toList(),
            ),
          ),
        );
      },
    );
  }
}

/// 复用 DeviceInfoContent 中的单元格组件
class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      text,
      style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
    ),
  );
}
