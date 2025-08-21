import 'dart:io';

const dir = 'packages/kits/lib/src/plugins/';

const files = {
  'mana_{{SNAKE_CASE}}/icon.dart': _iconContent,
  'mana_{{SNAKE_CASE}}/index.dart': _indexContent,
  'mana_{{SNAKE_CASE}}/README.md': _readmeContent,
  'mana_{{SNAKE_CASE}}/widgets/{{SNAKE_CASE}}.dart': _widgetContent,
};

/// 快速创建一个插件目录
/// dart run scripts/plugin.dart <plugin_name> [plugin_chinese_name]
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('使用: dart run scripts/plugin.dart <plugin_name> [plugin_chinese_name]');
    exit(64);
  }

  final pluginName = args.first.trim();
  if (pluginName.isEmpty) {
    stderr.writeln('插件不能为空！');
    exit(64);
  }

  // 创建根目录
  final rootDir = Directory(dir);
  if (!rootDir.existsSync()) {
    rootDir.createSync(recursive: true);
  }

  final pluginChineseName = args.length >= 2 ? args[1] : '无名';

  final snake = toSnakeCase(pluginName);
  final pascal = toPascalCase(pluginName);
  final spacePascal = toSpacePascalCase(pluginName);

  final replacements = {
    'SNAKE_CASE': snake,
    'PASCAL_CASE': pascal,
    'SPACE_PASCAL_CASE': spacePascal,
    'ZH_NAME': pluginChineseName,
  };

  files.forEach((templatePath, content) {
    final targetPath = renderTemplate(templatePath, replacements);
    final file = File('${rootDir.path}$targetPath');

    // 确保父目录存在
    file.parent.createSync(recursive: true);

    // 写入文件
    file.writeAsStringSync(renderTemplate(content, replacements));
    print('文件创建成功: ${file.path}');
  });

  print('\n**********************************************************************\n');
  print(
      '[$pluginChineseName - $pascal](https://github.com/lhlyu/flutter_mana/tree/master/packages/kits/lib/src/plugins/mana_$snake)');
  print('\n**********************************************************************');
}

const _iconContent = '''import 'dart:convert';

import 'package:flutter/cupertino.dart';

/// png to base64
const _iconData = r'';

final _iconBytes = base64Decode(_iconData);

final iconImage = MemoryImage(_iconBytes);''';

const _indexContent = '''import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'icon.dart';
import 'widgets/{{SNAKE_CASE}}.dart';

class Mana{{PASCAL_CASE}} extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => {{PASCAL_CASE}}(name: name);

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_{{SNAKE_CASE}}';

  @override
  String getLocalizedDisplayName(Locale locale) {
    if (locale.languageCode == 'zh') {
      return '{{ZH_NAME}}';
    }
    return '{{SPACE_PASCAL_CASE}}';
  }
}
''';

const _readmeContent = '''# {{ZH_NAME}} - {{PASCAL_CASE}}

## 使用 - Use

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';

void main() {
  /// add plugin
  ManaPluginManager.instance.register(Mana{{PASCAL_CASE}}());

  runApp(ManaWidget(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '{{PASCAL_CASE}}',
      home: Text('{{SPACE_PASCAL_CASE}}'),
    );
  }
}
```
''';

const _widgetContent = '''import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';

class {{PASCAL_CASE}} extends StatelessWidget with I18nMixin {
  final String name;

  const {{PASCAL_CASE}}({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: name,
      content: Text('{{PASCAL_CASE}}'),
    );
  }
}
''';

// --------------------------- 工具函数 -----------------------
/// 统一转成大驼峰（PascalCase）
/// 支持：snake_case、camelCase、PascalCase 以及带空格/连字符/下划线的任意组合
String toPascalCase(String src) {
  // 1. 按所有非字母数字字符（包括空格）拆分
  final words = src
      .split(RegExp(r'[^a-zA-Z0-9]+'))
      .expand((w) => w.split(RegExp(r'(?=[A-Z])'))) // 处理驼峰里的隐性分隔
      .where((w) => w.isNotEmpty)
      .toList();

  // 2. 首字母大写，其余小写
  return words.map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join();
}

String toSpacePascalCase(String src) {
  // 1. 按所有非字母数字字符（包括空格）拆分
  final words = src
      .split(RegExp(r'[^a-zA-Z0-9]+'))
      .expand((w) => w.split(RegExp(r'(?=[A-Z])'))) // 处理驼峰里的隐性分隔
      .where((w) => w.isNotEmpty)
      .toList();

  // 2. 首字母大写，其余小写
  return words.map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
}

/// 统一转成蛇形（snake_case）
/// 支持：snake_case、camelCase、PascalCase 以及带空格/连字符/任意分隔符的混合写法
String toSnakeCase(String src) {
  // 1. 先把所有非字母数字字符（含空格、连字符等）统一换成下划线
  var s = src.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');

  // 2. 处理大小写驼峰：在字母由小写→大写 或 数字→字母 之前插入下划线
  s = s.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])|([0-9])([a-zA-Z])|([a-zA-Z])([0-9])'),
    (m) => '${m[1] ?? m[3] ?? m[5]}_${m[2] ?? m[4] ?? m[6]}',
  );

  // 3. 去掉首尾多余下划线并合并连续下划线，再整体转小写
  return s.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_+|_+\$'), '').toLowerCase();
}

/// 批量替换 content 中的占位符
/// [content] 原始模板字符串
/// [replacements] Map<占位符, 替换值>
/// 占位符统一写成 `{{key}}` 的形式
String renderTemplate(String content, Map<String, String> replacements) {
  // 先按 key 长度倒序，避免短 key 影响长 key 的前缀
  final sortedKeys = replacements.keys.toList()..sort((a, b) => b.length.compareTo(a.length));

  var result = content;
  for (final key in sortedKeys) {
    final placeholder = '{{$key}}';
    result = result.replaceAll(placeholder, replacements[key] ?? '');
  }
  return result;
}
