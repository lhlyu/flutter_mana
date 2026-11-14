import 'dart:convert';
import 'dart:io';

const _usage =
    '用法: dart run scripts/plugin.dart <plugin_name> [中文名称]\n'
    '示例: dart run scripts/plugin.dart http_inspector 网络检查器';

/// Creates a Widgets-only kit and exports it without changing loadAllPlugins.
void main(List<String> args) {
  if (args.length == 1 && ['--help', '-h'].contains(args.single)) {
    stdout.writeln(_usage);
    return;
  }
  if (args.isEmpty || args.length > 2) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }

  try {
    // Resolve from the script, not the caller's working directory.
    final root = File.fromUri(Platform.script).parent.parent;
    final target = createPlugin(
      root,
      args.first,
      chineseName: args.length == 2 ? args[1] : null,
    );
    final result = Process.runSync(Platform.resolvedExecutable, [
      'format',
      target.path,
      '${target.parent.path}/plugins.dart',
    ]);
    if (result.exitCode != 0) {
      stderr.write(result.stderr);
      exitCode = result.exitCode;
      return;
    }
    stdout.writeln('已创建: ${target.path}');
    stdout.writeln('已更新 plugins.dart 导出；按需手动加入 loadAllPlugins()。');
    stdout.writeln('图标暂用 PluginIcon.demo，请在 plugin_icons.dart 中添加专属 SVG。');
  } on ArgumentError catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(_usage);
    exitCode = 64;
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 73;
  } on FileSystemException catch (error) {
    stderr.writeln(error);
    exitCode = 74;
  }
}

/// Refuses existing paths and validates all inputs before writing any files.
Directory createPlugin(Directory root, String name, {String? chineseName}) {
  if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9 _-]*$').hasMatch(name.trim())) {
    throw ArgumentError('插件名须以英文字母开头，仅支持字母、数字、空格、下划线或连字符。');
  }
  var snake = toSnakeCase(name);
  if (snake.startsWith('mana_')) snake = snake.substring(5);
  if (snake == 'mana' || !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(snake)) {
    throw ArgumentError('请提供不含 mana 前缀的有效插件名。');
  }
  if (chineseName != null && chineseName.trim().isEmpty) {
    throw ArgumentError('中文名称不能为空。');
  }
  final words = snake.split('_');
  final title = words.map(_capitalize).join(' ');
  final pascal = words.map(_capitalize).join();
  final id = 'mana_$snake';
  final className = 'Mana$pascal';
  final plugins = Directory('${root.path}/packages/kits/lib/src/plugins');
  final barrel = File('${plugins.path}/plugins.dart');
  final original = barrel.readAsStringSync();
  final target = Directory('${plugins.path}/$id');
  if (FileSystemEntity.typeSync(target.path, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw StateError('目标路径已存在，不会覆盖: ${target.path}');
  }

  final exportPath = '$id/index.dart';
  final exports = RegExp(
    r"^export '([^']+)'.*?;",
    multiLine: true,
    dotAll: true,
  ).allMatches(original).toList();
  if (exports.isEmpty) throw StateError('plugins.dart 中未找到导出，请检查工作区。');
  if (exports.any((entry) => entry.group(1) == exportPath)) {
    throw StateError('plugins.dart 已包含 $exportPath，请先检查已有插件。');
  }
  if (exports.any((entry) => RegExp('\\b$className\\b').hasMatch(entry[0]!))) {
    throw StateError('plugins.dart 已导出 $className，请使用其他插件名。');
  }
  final insertion = exports
      .where((entry) => entry.group(1)!.compareTo(exportPath) > 0)
      .firstOrNull;
  final line = "export '$exportPath' show $className;\n";
  final updated = insertion == null
      ? '${original.trimRight()}\n$line'
      : original.replaceRange(insertion.start, insertion.start, line);
  final replacements = {
    'SNAKE': snake,
    'PASCAL': pascal,
    'ID': id,
    'CLASS': className,
    'TITLE': title,
    'TITLE_LITERAL': _dartString(title),
    'CHINESE_LITERAL': _dartString(chineseName?.trim() ?? title),
  };
  final files = {
    'index.dart': _indexContent,
    'widgets/${snake}_content.dart': _widgetContent,
    'README.md': _readmeContent,
  };
  for (final entry in files.entries) {
    final file = File('${target.path}/${entry.key}');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(renderTemplate(entry.value, replacements));
  }
  barrel.writeAsStringSync(updated);
  return target;
}

String toSnakeCase(String value) => value
    .trim()
    .replaceAllMapped(
      RegExp(r'([A-Z]+)([A-Z][a-z])'),
      (match) => '${match[1]}_${match[2]}',
    )
    .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match[1]}_${match[2]}',
    )
    .replaceAll(RegExp(r'[\s_-]+'), '_')
    .replaceAll(RegExp(r'_+$'), '')
    .toLowerCase();

String _capitalize(String word) => word[0].toUpperCase() + word.substring(1);

String _dartString(String value) => jsonEncode(value).replaceAll(r'$', r'\$');

// One pass keeps placeholder-like user text from being substituted again.
String renderTemplate(String content, Map<String, String> replacements) =>
    content.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (match) => replacements[match[1]] ?? match[0]!,
    );

const _indexContent = '''import 'package:flutter/widgets.dart';

import '../../ui/kit_ui.dart';
import '../builtin_kit.dart';
import 'widgets/{{SNAKE}}_content.dart';

class {{CLASS}} extends BuiltinKit {
  {{CLASS}}()
    : super(
        name: '{{ID}}',
        title: {{TITLE_LITERAL}},
        chineseTitle: {{CHINESE_LITERAL}},
        icon: .demo,
      );

  @override
  Widget buildWidget(BuildContext context) => KitWindow(
    name: name,
    content: const {{PASCAL}}Content(),
  );
}
''';

const _widgetContent = '''import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';

class {{PASCAL}}Content extends StatelessWidget {
  const {{PASCAL}}Content({super.key});

  @override
  Widget build(BuildContext context) => KitScaffold(
    body: KitMessage(kitText(context, 'common.empty')),
  );
}
''';

const _readmeContent = '''# {{TITLE}}

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

void main() => runApp(
  ManaWidget(
    plugins: [{{CLASS}}()],
    child: const Center(child: Text('Host')),
  ),
);
```

`ManaWidget` 管理内部 Controller 的生命周期。已有应用可在 builder 中使用
`ManaWidget.builder`，并由宿主释放传入的 Controller。

内容使用 `KitScaffold` 和 `kitText`；新增文案放在 `src/i18n/kit_localizations.dart`。
图标暂用 `PluginIcon.demo`；请在 `src/icons/plugin_icons.dart` 添加专属 SVG。
插件已导出，但不会自动加入 `loadAllPlugins()`。
''';
