import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/plugin.dart' as generator;

Directory _repositoryRoot() {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/scripts/plugin.dart').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) throw StateError('Workspace not found');
    directory = parent;
  }
  return directory;
}

void _copyDirectory(Directory source, Directory target) {
  for (final entity in source.listSync(recursive: true)) {
    if (entity is! File) continue;
    final file = File(
      '${target.path}/${entity.path.substring(source.path.length + 1)}',
    );
    file.parent.createSync(recursive: true);
    entity.copySync(file.path);
  }
}

void main() {
  final root = _repositoryRoot();
  late Directory fixture;
  late File barrel;
  late String original;

  setUp(() {
    fixture = Directory.systemTemp.createTempSync('mana-plugin-generator-');
    barrel = File('${fixture.path}/packages/kits/lib/src/plugins/plugins.dart');
    barrel.parent.createSync(recursive: true);
    original = File('${root.path}/packages/kits/lib/src/plugins/plugins.dart')
        .readAsStringSync();
    barrel.writeAsStringSync(original);
  });

  tearDown(() => fixture.deleteSync(recursive: true));

  for (final name in [
    'http_inspector',
    'httpInspector',
    'HttpInspector',
    'HTTPInspector',
    'http-inspector',
    'http inspector',
    'mana_http_inspector',
    'ManaHttpInspector',
  ]) {
    test('normalizes $name and generates the current kit API', () {
      final target = generator.createPlugin(
        fixture,
        name,
        chineseName: '网络检查器',
      );
      expect(target.path, endsWith('/mana_http_inspector'));
      final index = File('${target.path}/index.dart').readAsStringSync();
      expect(index, contains('class ManaHttpInspector extends BuiltinKit'));
      expect(index, contains('Widget buildWidget(BuildContext context)'));
      expect(index, contains('KitWindow('));
      expect(index, contains('icon: .demo'));
      expect(index, contains('chineseTitle: "网络检查器"'));
      final content = File('${target.path}/widgets/http_inspector_content.dart')
          .readAsStringSync();
      expect(content, contains('KitScaffold('));
      expect(content, contains("KitMessage(kitText(context, 'common.empty'))"));
      expect(File('${target.path}/icon.dart').existsSync(), isFalse);
      expect(
        '$index$content',
        isNot(contains('package:flutter/material.dart')),
      );
      expect('$index$content', isNot(contains('I18nMixin')));
      final updated = barrel.readAsStringSync();
      final export =
          "export 'mana_http_inspector/index.dart' show ManaHttpInspector;";
      expect(updated.split(export), hasLength(2));
      expect(updated.replaceFirst('$export\n', ''), original);
      expect(
        updated.indexOf(export),
        lessThan(updated.indexOf("export 'mana_license/")),
      );
    });
  }

  test('rejects invalid names without writing files or changing exports', () {
    for (final name in [
      '',
      ' ',
      '___',
      '../escape',
      'foo/bar',
      'foo.dart',
      '1test',
      '中文',
      'mana',
      'mana_42',
    ]) {
      expect(
        () => generator.createPlugin(fixture, name),
        throwsArgumentError,
        reason: name,
      );
    }
    expect(
      () => generator.createPlugin(fixture, 'valid', chineseName: '  '),
      throwsArgumentError,
    );
    expect(barrel.readAsStringSync(), original);
    expect(barrel.parent.listSync(), hasLength(1));
  });

  test('does not overwrite existing or partially created plugins', () {
    final target = generator.createPlugin(fixture, 'http_inspector');
    final index = File('${target.path}/index.dart')
      ..writeAsStringSync('// custom');
    final updated = barrel.readAsStringSync();
    expect(
      () => generator.createPlugin(fixture, 'ManaHttpInspector'),
      throwsStateError,
    );
    expect(index.readAsStringSync(), '// custom');
    expect(barrel.readAsStringSync(), updated);
    final partial = Directory('${barrel.parent.path}/mana_partial')
      ..createSync();
    expect(() => generator.createPlugin(fixture, 'partial'), throwsStateError);
    expect(partial.listSync(), isEmpty);
  });

  test('rejects class names that collide with existing public exports', () {
    expect(
      () => generator.createPlugin(fixture, 'dio_collector'),
      throwsStateError,
    );
    expect(barrel.readAsStringSync(), original);
    final target = generator.createPlugin(fixture, 'http2');
    expect(target.path, endsWith('/mana_http2'));
    final updated = barrel.readAsStringSync();
    expect(() => generator.createPlugin(fixture, 'http_2'), throwsStateError);
    expect(barrel.readAsStringSync(), updated);
    expect(
      Directory('${barrel.parent.path}/mana_http_2').existsSync(),
      isFalse,
    );
  });

  test('refuses stale exports and a missing workspace', () {
    barrel.writeAsStringSync(
      "$original\nexport 'mana_stale/index.dart' show ManaStale;\n",
    );
    expect(() => generator.createPlugin(fixture, 'stale'), throwsStateError);
    expect(barrel.parent.listSync(), hasLength(1));
    barrel.deleteSync();
    expect(
      () => generator.createPlugin(fixture, 'fresh'),
      throwsA(isA<FileSystemException>()),
    );
    expect(barrel.parent.listSync(), isEmpty);
  });

  test('template replacement is single-pass and Dart strings are escaped', () {
    const title = '引号 " \' \\ \n \$value {{ID}}';
    final target = generator.createPlugin(
      fixture,
      'escape',
      chineseName: title,
    );
    final index = File('${target.path}/index.dart').readAsStringSync();
    expect(index, contains(jsonEncode(title).replaceAll(r'$', r'\$')));
    expect(index, contains('{{ID}}'));
    expect(
      generator.renderTemplate('{{A}} {{AB}}', {'A': '{{AB}}', 'AB': 'value'}),
      '{{AB}} value',
    );
  });

  test(
    'CLI works outside the workspace, formats output and refuses duplicates',
    () async {
      final script = File('${fixture.path}/scripts/plugin.dart');
      script.parent.createSync();
      File('${root.path}/scripts/plugin.dart').copySync(script.path);
      Future<ProcessResult> run(List<String> args) => Process.run('dart', [
        'run',
        script.path,
        ...args,
      ], workingDirectory: Directory.systemTemp.path);
      final help = await run(['--help']);
      expect(help.exitCode, 0);
      expect(barrel.readAsStringSync(), original);
      final invalid = await run(['../escape']);
      expect(invalid.exitCode, 64);
      final success = await run(['HTTPInspector', '网络检查器']);
      expect(success.exitCode, 0, reason: '${success.stdout}${success.stderr}');
      expect(success.stdout, contains('已创建:'));
      final formatted = await Process.run('dart', [
        'format',
        '--output=none',
        '--set-exit-if-changed',
        '${barrel.parent.path}/mana_http_inspector',
        barrel.path,
      ]);
      expect(
        formatted.exitCode,
        0,
        reason: '${formatted.stdout}${formatted.stderr}',
      );
      final duplicate = await run(['http_inspector']);
      expect(duplicate.exitCode, 73);
      expect(duplicate.stderr, contains('不会覆盖'));
    },
  );

  test(
    'generated plugin and README example analyze against current APIs',
    () async {
      final kits = Directory('${fixture.path}/packages/kits');
      _copyDirectory(
        Directory('${root.path}/packages/kits/lib'),
        Directory('${kits.path}/lib'),
      );
      File('${root.path}/packages/kits/analysis_options.yaml')
          .copySync('${kits.path}/analysis_options.yaml');
      final config = File('${root.path}/.dart_tool/package_config.json');
      final packages =
          jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
      for (final package in packages['packages'] as List) {
        package['rootUri'] = package['name'] == 'flutter_mana_kits'
            ? kits.uri.toString()
            : config.parent.uri
                  .resolve(package['rootUri'] as String)
                  .toString();
      }
      final targetConfig = File(
        '${fixture.path}/.dart_tool/package_config.json',
      );
      targetConfig.parent.createSync();
      targetConfig.writeAsStringSync(jsonEncode(packages));
      final target = generator.createPlugin(
        fixture,
        'HTTPInspector',
        chineseName: '网络 " \' \\ \n \$value {{ID}}',
      );
      final readme = File('${target.path}/README.md').readAsStringSync();
      final example = File('${kits.path}/example/main.dart');
      example.parent.createSync();
      example.writeAsStringSync(readme.split('```dart\n')[1].split('```')[0]);
      final result = await Process.run('dart', [
        'analyze',
        kits.path,
      ], workingDirectory: fixture.path);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    },
  );
}
