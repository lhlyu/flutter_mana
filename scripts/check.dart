import 'dart:io';

const _usage = '''用法: dart scripts/check.dart [--web]

检查格式、全仓静态分析、发布脚本及 core / kits / example 测试。
--web  同时构建 example 的 Web Release 产物。
''';

Future<void> main(List<String> args) async {
  if (args.length == 1 && ['--help', '-h'].contains(args.single)) {
    stdout.write(_usage);
    return;
  }
  if (args.isNotEmpty && !(args.length == 1 && args.single == '--web')) {
    stderr.write(_usage);
    exitCode = 64;
    return;
  }

  final root = File.fromUri(Platform.script).parent.parent;
  final dart = Platform.resolvedExecutable;

  Future<bool> run(
    String executable,
    List<String> arguments, {
    String? package,
  }) async {
    final directory = package == null
        ? root.path
        : '${root.path}/packages/$package';
    stdout.writeln(
      '\n[${package ?? 'workspace'}] ${[executable, ...arguments].join(' ')}',
    );
    try {
      final process = await Process.start(
        executable,
        arguments,
        workingDirectory: directory,
        mode: ProcessStartMode.inheritStdio,
        runInShell: Platform.isWindows,
      );
      final result = await process.exitCode;
      if (result == 0) return true;
      exitCode = result;
    } on ProcessException catch (error) {
      stderr.writeln(error);
      exitCode = 1;
    }
    return false;
  }

  if (!await run('flutter', ['pub', 'get'])) return;
  if (!await run(dart, [
    'format',
    '--output=none',
    '--set-exit-if-changed',
    'packages',
    'scripts',
  ]))
    return;
  if (!await run('flutter', ['analyze', '--no-pub'])) return;
  if (!await run(dart, ['scripts/release_test.dart'])) return;

  // Package assets (including shaders) must be resolved from each package root.
  for (final package in ['core', 'kits', 'example']) {
    if (!await run('flutter', [
      'test',
      '--no-pub',
      '--reporter',
      'expanded',
    ], package: package))
      return;
  }
  if (args.contains('--web') &&
      !await run('flutter', [
        'build',
        'web',
        '--release',
        '--no-pub',
      ], package: 'example'))
    return;

  stdout.writeln('\n所有检查通过。');
}
