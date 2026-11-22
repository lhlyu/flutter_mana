// Run the debug screenshot entry point first; see docs/screenshots.md.
import 'dart:convert';
import 'dart:io';

const kits = [
  'mana_preview',
  'mana_align_ruler',
  'mana_color_sucker',
  'mana_device_info',
  'mana_dio_inspector',
  'mana_fps_monitor',
  'mana_grid',
  'mana_license',
  'mana_log_viewer',
  'mana_memory_info',
  'mana_package_info',
  'mana_screen_info',
  'mana_shared_preferences_viewer',
  'mana_show_code',
  'mana_touch_indicator',
  'mana_visual_helper',
  'mana_widget_info_inspector',
];

Future<void> main(List<String> args) async {
  final options = <String, String>{};
  for (final arg in args) {
    final match = RegExp(r'^--(device|date|port)=(.+)$').firstMatch(arg);
    if (match == null) {
      stderr.writeln(
        'Usage: dart run scripts/screenshots.dart '
        '[--device=UDID] [--date=YYYY-MM-DD] [--port=17931]',
      );
      exitCode = 64;
      return;
    }
    options[match[1]!] = match[2]!;
  }
  final root = File.fromUri(Platform.script).parent.parent;
  final date =
      options['date'] ?? DateTime.now().toIso8601String().split('T').first;
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
    throw ArgumentError('Date must be YYYY-MM-DD.');
  }
  final port = int.parse(options['port'] ?? '17931');
  final client = HttpClient()..findProxy = (_) => 'DIRECT';

  Future<Map<String, dynamic>> command(
    String path, [
    Map<String, String> params = const {},
  ]) async {
    final uri = Uri.http('127.0.0.1:$port', path, params);
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 10));
    final response = await request.close().timeout(const Duration(seconds: 45));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) throw StateError('$uri: $body');
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<String> simctl(List<String> arguments) async {
    final result = await Process.run('xcrun', ['simctl', ...arguments]);
    if (result.exitCode != 0) {
      throw ProcessException(
        'xcrun',
        ['simctl', ...arguments],
        '${result.stdout}\n${result.stderr}',
        result.exitCode,
      );
    }
    return result.stdout as String;
  }

  String? device;
  var statusOverridden = false;
  try {
    device = options['device'];
    if (device == null) {
      final devices = jsonDecode(
        await simctl(['list', 'devices', 'booted', '--json']),
      ) as Map<String, dynamic>;
      final booted = (devices['devices'] as Map<String, dynamic>).values
          .expand((items) => items as List)
          .where((item) => item['state'] == 'Booted')
          .toList();
      if (booted.length != 1) {
        throw StateError('Boot one iOS simulator or pass --device=UDID.');
      }
      device = booted.single['udid'] as String;
    }
    await command('/health');
    await simctl([
      'status_bar',
      device,
      'override',
      '--time',
      '9:41',
      '--dataNetwork',
      'wifi',
      '--wifiMode',
      'active',
      '--wifiBars',
      '3',
      '--batteryState',
      'discharging',
      '--batteryLevel',
      '100',
    ]);
    statusOverridden = true;
    final output = Directory('${root.path}/screenshots')..createSync();
    for (final kit in kits) {
      var state = await command('/prepare', {'kit': kit});
      if (kit != 'mana_preview' && state['active'] != kit) {
        throw StateError('$kit was not activated: $state');
      }
      if (const {
        'mana_device_info',
        'mana_dio_inspector',
        'mana_license',
        'mana_log_viewer',
        'mana_memory_info',
        'mana_shared_preferences_viewer',
        'mana_show_code',
      }.contains(kit)) {
        state = await command('/fullscreen');
      }
      switch (kit) {
        case 'mana_color_sucker':
          final sample = state['sample'] as Map<String, dynamic>;
          state = await command('/tap', {
            'x': '${(sample['x'] as num) + 12}',
            'y': '${(sample['y'] as num) + 8}',
          });
          break;
        case 'mana_fps_monitor':
          state = await command('/tap', {'text': '动画'});
          await Future<void>.delayed(const Duration(seconds: 3));
          break;
        case 'mana_show_code':
          state = await command('/text', {'value': 'plugin_icons.dart'});
          final script = (state['texts'] as List).cast<String>().firstWhere(
            (text) => text.endsWith('/src/icons/plugin_icons.dart'),
          );
          state = await command('/tap', {'text': script});
          break;
        case 'mana_touch_indicator':
          final sample = state['sample'] as Map<String, dynamic>;
          state = await command('/hold', {
            'x': '${sample['x']}',
            'y': '${sample['y']}',
          });
          break;
        case 'mana_widget_info_inspector':
          await command('/minimize');
          await command('/tap', {'key': 'sample-input'});
          state = await command('/restore');
          break;
      }
      final texts = (state['texts'] as List).cast<String>();
      if (kit == 'mana_widget_info_inspector' && texts.contains('—')) {
        throw StateError('The widget inspector did not select a widget.');
      }
      if (texts.any((text) => text.contains('Exception:') || text == '加载中…')) {
        throw StateError('$kit is not ready: $texts');
      }
      final path = '${output.path}/${date}_$kit.png';
      await simctl(['io', device, 'screenshot', '--type=png', path]);
      stdout.writeln('Captured ${date}_$kit.png');
      if (kit == 'mana_fps_monitor') {
        await command('/tap', {'text': '动画'});
      }
    }
    stdout.writeln(
      'Saved ${kits.length} screenshots. '
      'Update docs/previews.md and README.md to reference the $date filenames.',
    );
  } finally {
    client.close(force: true);
    if (statusOverridden && device != null) {
      await simctl(['status_bar', device, 'clear']);
    }
  }
}
