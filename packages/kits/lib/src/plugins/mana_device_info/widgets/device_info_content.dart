import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';

const _deviceFields = [
  'name',
  'computerName',
  'hostName',
  'modelName',
  'manufacturer',
  'brand',
  'model',
  'product',
  'systemName',
  'systemVersion',
  'isPhysicalDevice',
];
const _hardwareFields = [
  'physicalRamSize',
  'availableRamSize',
  'memorySize',
  'systemMemoryInMegabytes',
  'totalDiskSize',
  'freeDiskSize',
  'numberOfCores',
  'activeCPUs',
  'arch',
];

class DeviceInfoContent extends StatelessWidget {
  const DeviceInfoContent({super.key, required this.data});
  final Map<String, Object?> data;

  String? _first(List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    String text(String key) => kitText(context, 'device.$key');
    final version = data['version'];
    final system =
        _first(['systemName', 'productName', 'prettyName', 'osRelease']) ??
        (version is Map && version['release'] != null
            ? 'Android ${version['release']}'
            : null);
    final subtitle = [
      ?system,
      if (data['systemVersion'] case final String version
          when version.isNotEmpty)
        version,
      if (data['isPhysicalDevice'] case final bool physical)
        text(physical ? 'physical' : 'simulator'),
    ].join(' · ');
    final details = <String, Object?>{
      for (final entry in data.entries)
        if (!_deviceFields.contains(entry.key) &&
            !_hardwareFields.contains(entry.key))
          entry.key: entry.value,
    };
    Widget fields(List<String> keys) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final key in keys)
          if (data.containsKey(key))
            KitInfoField(
              label: text(key),
              value: formatDeviceField(key, data[key]),
            ),
      ],
    );
    return KitInfoPage(
      title: text('title'),
      headline:
          _first([
            'modelName',
            'model',
            'computerName',
            'name',
            'prettyName',
            'browserName',
            'platform',
          ]) ??
          text('title'),
      subtitle: subtitle.isEmpty ? null : subtitle,
      data: data,
      children: [
        if (_deviceFields.any(data.containsKey))
          KitInfoSection(title: text('system'), child: fields(_deviceFields)),
        if (_hardwareFields.any(data.containsKey))
          KitInfoSection(
            title: text('hardware'),
            child: fields(_hardwareFields),
          ),
        if (details.isNotEmpty)
          KitInfoSection(
            title: text('platform_details'),
            collapsible: true,
            child: KitInfoFields(details),
          ),
      ],
    );
  }
}

/// Mobile RAM and Windows memory are reported in MB; disk and macOS RAM in bytes.
Object? formatDeviceField(String key, Object? value) {
  if (value is! num) return value;
  final megabytes = switch (key) {
    'physicalRamSize' ||
    'availableRamSize' ||
    'systemMemoryInMegabytes' => true,
    'totalDiskSize' || 'freeDiskSize' || 'memorySize' => false,
    _ => null,
  };
  if (megabytes == null) return value;
  if (value < 0) return null;
  var amount = value.toDouble();
  var unit = megabytes ? 2 : 0;
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  while (amount >= 1024 && unit < units.length - 1) {
    amount /= 1024;
    unit++;
  }
  final number = amount.toStringAsFixed(
    amount == amount.roundToDouble() ? 0 : 1,
  );
  return '$number ${units[unit]}';
}
