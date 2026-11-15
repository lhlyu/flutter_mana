// 仅使用 Dart SDK 的独立测试，不引入额外测试依赖。
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'release.dart' as release;

void expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> expectFailure(FutureOr<void> Function() action) async {
  var failed = false;
  try {
    await action();
  } catch (_) {
    failed = true;
  }
  expect(failed, 'Expected an error');
}

void testVersions() {
  for (final version in [
    '0.0.0',
    '2.0.0',
    '2.0.0-rc.1',
    '2.0.0-0',
    '2.0.0-rc-01',
    '2.0.0+build.01',
    '2.0.0-rc.1+build.01',
  ]) {
    expect(release.isValidVersion(version), '应接受合法版本：$version');
  }
  for (final version in [
    '',
    'v2.0.0',
    '02.0.0',
    '2.00.0',
    '2.0.01',
    '2.0',
    '2.0.0-',
    '2.0.0-rc..1',
    '2.0.0-01',
    '2.0.0-rc.01',
    '2.0.0+',
    '2.0.0+build..1',
    '2.0.0+1+2',
    '2.0.0 rc.1',
    '2.0.0\n',
  ]) {
    expect(!release.isValidVersion(version), '应拒绝非法版本：$version');
  }
}

class StalledPubDevClient extends release.PubDevClient {
  @override
  Future<bool> isPublished(String name, String version) =>
      Completer<bool>().future;
}

Future<void> testWaitDeadline() async {
  final client = StalledPubDevClient();
  var timedOut = false;
  try {
    await client
        .waitUntilPublished(
          'flutter_mana',
          '2.0.0-rc.1',
          timeout: const Duration(milliseconds: 20),
        )
        .timeout(const Duration(seconds: 2));
  } on StateError {
    timedOut = true;
  } finally {
    client.close();
  }
  expect(timedOut, '卡住的网络请求也必须遵守整体等待期限');
}

Future<void> main() async {
  testVersions();
  await testWaitDeadline();
  final directory = Directory.systemTemp.createTempSync('mana-release-test-');
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final client = release.PubDevClient(
    baseUrl: Uri.parse('http://127.0.0.1:${server.port}/'),
    retryDelay: Duration.zero,
  );
  var status = 200;
  var requests = 0;
  var recoverAfterFirstRequest = false;
  var responseName = 'flutter_mana';
  server.listen((request) async {
    requests++;
    request.response.statusCode = recoverAfterFirstRequest && requests > 1
        ? 200
        : status;
    request.response.write(
      jsonEncode({
        'version': '2.0.0-rc.1',
        'pubspec': {'name': responseName},
      }),
    );
    await request.response.close();
  });

  try {
    final pubspec = File('${directory.path}/pubspec.yaml');
    final changelog = File('${directory.path}/CHANGELOG.md');
    pubspec.writeAsStringSync('name: flutter_mana\nversion: 2.0.0-rc.1\n');
    changelog.writeAsStringSync('# 2.0.0-rc.1\n');
    final metadata = release.packageMetadata(directory);
    expect(metadata.name == 'flutter_mana', 'Package name must match');
    pubspec.writeAsStringSync('name:\nversion: 2.0.0-rc.1\n');
    await expectFailure(() {
      release.packageMetadata(directory);
    });
    pubspec.writeAsStringSync('name: flutter_mana\nversion: 2.0.0-rc.1\n');
    final candidate = release.checkRelease(
      directory,
      'flutter_mana-v2.0.0-rc.1',
    );
    expect(candidate.prerelease, 'RC must be a prerelease');
    await expectFailure(() {
      release.checkRelease(directory, 'flutter_mana-v2.0.0-rc.2');
    });
    await expectFailure(() {
      release.checkRelease(directory, 'flutter_mana_kits-v2.0.0-rc.1');
    });
    await expectFailure(() {
      release.checkRelease(directory, 'v2.0.0-rc.1');
    });
    await expectFailure(() {
      release.checkRelease(directory, 'not-a-tag');
    });
    changelog.writeAsStringSync('# Wrong version\n');
    await expectFailure(() {
      release.checkRelease(directory, 'flutter_mana-v2.0.0-rc.1');
    });

    pubspec.writeAsStringSync('name: example\nversion: 2.0.0+1\n');
    final stable = release.releaseMetadata(directory);
    expect(!stable.prerelease, 'Stable example may include a build number');
    pubspec.writeAsStringSync('name: flutter_mana\nversion: 2.0.0+build-1\n');
    changelog.writeAsStringSync('# 2.0.0+build-1\n');
    expect(!release.releaseMetadata(directory).prerelease, '构建元数据中的连字符不表示预发布');

    pubspec.writeAsStringSync('name: flutter_mana\nversion: 2.0.0-rc.1\n');
    expect(
      await client.isPublished('flutter_mana', '2.0.0-rc.1'),
      'Version exists',
    );
    expect(!await release.shouldPublish(directory, client), '已存在的版本应跳过官方发布任务');
    status = 404;
    expect(
      !await client.isPublished('flutter_mana', '2.0.0-rc.1'),
      '404 means missing',
    );
    expect(await release.shouldPublish(directory, client), '未发布的版本应执行官方发布任务');
    status = 403;
    requests = 0;
    await expectFailure(() async {
      await client.isPublished('flutter_mana', '2.0.0-rc.1');
    });
    expect(requests == 1, '403 must not be retried or treated as missing');

    status = 503;
    requests = 0;
    recoverAfterFirstRequest = true;
    expect(
      await client.isPublished('flutter_mana', '2.0.0-rc.1'),
      'Transient errors retry',
    );
    expect(requests == 2, 'Should retry once before recovery');
    requests = 0;
    recoverAfterFirstRequest = false;
    await expectFailure(() async {
      await client.isPublished('flutter_mana', '2.0.0-rc.1');
    });
    expect(requests == 6, 'Persistent errors must stop after six attempts');

    status = 404;
    requests = 0;
    recoverAfterFirstRequest = true;
    await client.waitUntilPublished('flutter_mana', '2.0.0-rc.1');
    expect(requests == 2, '版本由不可用变为可用后应结束等待');

    status = 200;
    recoverAfterFirstRequest = false;
    responseName = 'wrong_package';
    await expectFailure(() async {
      await client.isPublished('flutter_mana', '2.0.0-rc.1');
    });
    await expectFailure(() async {
      await client.waitUntilPublished(
        'flutter_mana',
        '2.0.0-rc.1',
        timeout: Duration.zero,
      );
    });
    stdout.writeln('发布脚本全部测试通过。');
  } finally {
    client.close();
    await server.close(force: true);
    directory.deleteSync(recursive: true);
  }
}
