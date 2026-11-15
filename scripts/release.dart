import 'dart:async';
import 'dart:convert';
import 'dart:io';

({String name, String version}) packageMetadata(Directory directory) {
  final content = File('${directory.path}/pubspec.yaml').readAsStringSync();
  String field(String name) {
    final match = RegExp(
      '^$name:'
      r'[ \t]*(\S+)[ \t]*\r?$',
      multiLine: true,
    ).firstMatch(content);
    if (match == null) {
      throw StateError('Missing $name in ${directory.path}/pubspec.yaml');
    }
    return match.group(1)!;
  }

  return (name: field('name'), version: field('version'));
}

bool isValidVersion(String value) {
  final match = RegExp(
    r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)'
    r'(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'
    r'(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$',
  ).firstMatch(value);
  if (match == null || match.end != value.length) return false;
  final prerelease = match.group(4);
  return prerelease == null ||
      prerelease
          .split('.')
          .every(
            (part) =>
                !RegExp(r'^[0-9]+$').hasMatch(part) ||
                part.length == 1 ||
                !part.startsWith('0'),
          );
}

({String version, bool prerelease}) releaseMetadata(Directory directory) {
  final metadata = packageMetadata(directory);
  if (!isValidVersion(metadata.version)) {
    throw StateError('无效的发布版本：${metadata.version}');
  }
  final version = metadata.name == 'example'
      ? metadata.version.split('+').first
      : metadata.version;
  if (metadata.name != 'example') {
    final changelog = File('${directory.path}/CHANGELOG.md').readAsLinesSync();
    if (changelog.isEmpty || changelog.first != '# $version') {
      throw StateError('CHANGELOG.md 首行必须是 # $version');
    }
  }
  return (version: version, prerelease: version.split('+').first.contains('-'));
}

({String version, bool prerelease}) checkRelease(
  Directory directory,
  String tag,
) {
  final metadata = packageMetadata(directory);
  final release = releaseMetadata(directory);
  final expected = '${metadata.name}-v${release.version}';
  if (tag != expected) {
    throw StateError('tag 必须为 $expected，实际为 $tag');
  }
  return release;
}

class PubDevClient {
  PubDevClient({Uri? baseUrl, this.retryDelay = const Duration(seconds: 5)})
    : baseUrl = baseUrl ?? Uri.parse('https://pub.dev/');

  final Uri baseUrl;
  final Duration retryDelay;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30);

  Future<bool> isPublished(String name, String version) async {
    final url = baseUrl.resolve(
      'api/packages/${Uri.encodeComponent(name)}/versions/'
      '${Uri.encodeComponent(version)}',
    );
    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        final request = await _client
            .getUrl(url)
            .timeout(const Duration(seconds: 30));
        final response = await request.close().timeout(
          const Duration(seconds: 30),
        );
        final body = await utf8.decoder
            .bind(response)
            .join()
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 404) return false;
        if (response.statusCode == 200) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['version'] != version || data['pubspec']['name'] != name) {
            throw StateError('Unexpected pub.dev response for $name $version');
          }
          return true;
        }
        if (response.statusCode != 429 && response.statusCode < 500) {
          throw StateError('pub.dev returned HTTP ${response.statusCode}');
        }
        throw HttpException('pub.dev returned HTTP ${response.statusCode}');
      } catch (error) {
        if (attempt == 5 ||
            (error is! SocketException &&
                error is! TimeoutException &&
                error is! HttpException)) {
          rethrow;
        }
      }
      stdout.writeln('Retrying pub.dev lookup for $name $version...');
      await Future<void>.delayed(retryDelay);
    }
    throw StateError('Unreachable lookup state');
  }

  Future<void> waitUntilPublished(
    String name,
    String version, {
    Duration timeout = const Duration(minutes: 15),
  }) async {
    stdout.writeln('等待 $name $version 在 pub.dev 可用...');
    final timer = Stopwatch()..start();
    while (timer.elapsed < timeout) {
      final remaining = timeout - timer.elapsed;
      if (remaining <= Duration.zero) break;
      try {
        if (await isPublished(name, version).timeout(remaining)) {
          stdout.writeln('$name $version 已在 pub.dev 可用。');
          return;
        }
      } on TimeoutException {
        break;
      }
      final delayBudget = timeout - timer.elapsed;
      if (delayBudget <= Duration.zero) break;
      await Future<void>.delayed(
        retryDelay < delayBudget ? retryDelay : delayBudget,
      );
    }
    throw StateError('等待 $name $version 超时，请先完成核心包发布，再重跑工具包工作流。');
  }

  void close() => _client.close(force: true);
}

Future<bool> shouldPublish(Directory directory, PubDevClient client) async {
  final metadata = packageMetadata(directory);
  final exists = await client.isPublished(metadata.name, metadata.version);
  stdout.writeln(
    exists
        ? '${metadata.name} ${metadata.version} 已发布，跳过官方发布任务。'
        : '${metadata.name} ${metadata.version} 尚未发布。',
  );
  return !exists;
}

void writeOutputs(
  ({String version, bool prerelease}) release, {
  bool? shouldPublish,
}) {
  final output =
      'version=${release.version}\nprerelease=${release.prerelease}\n'
      '${shouldPublish == null ? '' : 'should_publish=$shouldPublish\n'}';
  stdout.write(output);
  final outputPath = Platform.environment['GITHUB_OUTPUT'];
  if (outputPath != null) {
    File(outputPath).writeAsStringSync(output, mode: FileMode.append);
  }
}

Future<void> main(List<String> args) async {
  if (args.length != 2 ||
      !{'version', 'check', 'status', 'wait'}.contains(args[0]) ||
      !{
        'packages/core',
        'packages/kits',
        'packages/example',
      }.contains(args[1]) ||
      (args[0] != 'version' && args[1] == 'packages/example')) {
    stderr.writeln(
      '用法：dart scripts/release.dart <version|check|status|wait> <package>',
    );
    exitCode = 64;
    return;
  }
  final root = Directory.fromUri(Platform.script.resolve('../'));
  final directory = Directory('${root.path}/${args[1]}');
  final client = PubDevClient();
  try {
    switch (args[0]) {
      case 'version':
        writeOutputs(releaseMetadata(directory));
      case 'check':
        writeOutputs(
          checkRelease(
            directory,
            Platform.environment['GITHUB_REF_NAME'] ?? '',
          ),
        );
      case 'wait':
        final metadata = packageMetadata(directory);
        await client.waitUntilPublished(metadata.name, metadata.version);
      case 'status':
        writeOutputs(
          releaseMetadata(directory),
          shouldPublish: await shouldPublish(directory, client),
        );
    }
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } finally {
    client.close();
  }
}
