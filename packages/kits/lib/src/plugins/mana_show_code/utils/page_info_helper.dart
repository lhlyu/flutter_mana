import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'code_display_service.dart';

/// `PageInfoHelper` 辅助类，用于获取当前选中的 Flutter Widget 的相关信息，
/// 包括其渲染对象、元素、文件路径、行号以及尝试获取其源代码。
class PageInfoHelper {
  // `CodeDisplayService` 的实例，用于获取源代码相关信息。
  // 共享实例以避免不必要的重复创建。
  final CodeDisplayService _codeDisplayService = CodeDisplayService();

  // Widget Inspector 的选中服务实例，用于获取当前选中的 Widget 信息。
  final InspectorSelection selection =
      WidgetInspectorService.instance.selection;

  // 构造函数，在创建实例时初始化选择器。
  PageInfoHelper() {
    _selectionInit();
  }

  /// 获取当前选中 Widget 的渲染对象。
  /// 如果 `selection.current` 为 `null`，则返回 `null`。
  RenderObject? get renderObject => selection.current;

  /// 获取当前选中 Widget 的元素。
  /// 如果 `selection.currentElement` 为 `null`，则返回 `null`。
  Element? get element => selection.currentElement;

  /// 获取当前选中 Widget 的创建文件路径。
  /// 如果无法获取到信息，则返回 `null`。
  String? get filePath {
    final info = _jsonInfo;
    return info != null ? (info['creationLocation']?['file'] as String?) : null;
  }

  /// 将文件路径转换为 Flutter `package:` 格式的路径关键词。
  ///
  /// [filePath]：原始的文件系统路径。
  /// 返回：`package:` 格式的路径字符串，例如 `package:my_app/lib/src/my_widget.dart`。
  /// 注意：此方法目前只返回关键词，并打印调试信息，没有实际使用 `findScriptUrisByKeyword` 的返回值。
  String packagePathConvertFromFilePath(String? filePath) {
    if (filePath == null) {
      return '';
    }
    // 尝试根据 `/lib/` 分割路径，提取包名和包内文件路径
    final parts = filePath.split(r'/lib/');
    if (parts.length < 2) {
      debugPrint('Warning: File path does not contain "/lib/": $filePath');
      // 如果路径不包含 /lib/，可能无法正确构建 package 路径
      // 这里可以根据实际情况返回空字符串或抛出异常
      return '';
    }

    final fileForwardPart = parts.sublist(1).join('/lib/'); // 重新组合 /lib/ 之后的部分
    final packageName = parts.first.split('/').last; // 获取路径的最后一个部分作为包名

    final keyword = "package:$packageName/$fileForwardPart";

    // 注意：这里调用了 findScriptUrisByKeyword 但没有处理其返回值。
    // 如果此调用是为了副作用（例如缓存），则可以保留。
    // 如果是为了获取数据但未被使用，则可能是冗余的。
    _codeDisplayService.findScriptUrisByKeyword(keyword);
    return keyword;
  }

  /// 获取当前选中 Widget 的创建行号。
  /// 如果无法获取到信息，则返回 `null`。
  int? get line {
    final info = _jsonInfo;
    return info != null ? (info['creationLocation']?['line'] as int?) : null;
  }

  /// 生成当前选中 Widget 的摘要信息字符串。
  /// 返回：包含 Widget 类型、大小、文件路径和行号的字符串。
  String get message {
    // 使用空安全操作符 `?` 和默认值 `??` 来防止空指针异常
    final size = renderObject?.paintBounds.size;
    return '''${element?.toStringShort() ?? 'Unknown Widget'}\nsize: ${size ?? 'Unknown Size'}\nfilePath: ${filePath ?? 'Unknown Path'}\nline: ${line ?? 'Unknown Line'}''';
  }

  /// 获取当前选中 Widget 的 JSON 诊断信息。
  /// 返回：包含 Widget 详细信息的 Map，如果无法获取则为 `null`。
  Map? get _jsonInfo {
    if (renderObject == null) {
      return null;
    }

    try {
      // 获取 Widget 的诊断节点 ID。
      // 这可能会在 Flutter 更新时导致兼容性问题，应寻找官方支持的替代方案。
      final widgetId = WidgetInspectorService.instance
      // ignore: invalid_use_of_protected_member
      .toId(renderObject!.toDiagnosticsNode(), ''); // renderObject 已在前面进行了空检查

      if (widgetId == null) {
        return null;
      }

      // 获取选中 Widget 的摘要信息字符串，通常是 JSON 格式。
      String infoStr = WidgetInspectorService.instance.getSelectedSummaryWidget(
        widgetId,
        '',
      );

      // 尝试解码 JSON 字符串。
      return json.decode(infoStr) as Map?; // 明确转换类型
    } catch (e) {
      debugPrint('Error decoding widget info JSON: $e');
      return null;
    }
  }

  /// 计算给定渲染对象的可见面积。
  /// [object]：要计算面积的渲染对象。
  /// 返回：渲染对象的宽度乘以高度。
  /// 注意：`object.paintBounds.size` 通常不会为 `null`，但其 `width` 或 `height` 可能为 `0`。
  double _area(RenderObject object) {
    final Size size = object.paintBounds.size;
    // 假设 size 不为 null，如果 size.width 或 size.height 为 0，则面积为 0。
    return size.width * size.height;
  }

  /// 初始化当前页面可选择的渲染对象列表。
  /// 遍历渲染树，收集所有 `RenderBox` 类型的对象，并按面积排序后去重，
  /// 然后将其设置为 Inspector Selection 的候选列表。
  void _selectionInit() {
    // 确保 `manaRootKey.currentContext` 和其 `findRenderObject()` 非空。
    final RenderObject? rootRenderObject =
        manaRootKey.currentContext?.findRenderObject();
    if (rootRenderObject == null) {
      debugPrint(
        'Warning: Root render object not found for selection initialization.',
      );
      return;
    }

    // 假设 `manaRootKey.currentContext!.findRenderObject()` 返回的是 `RenderView` 或类似的根节点，
    // 其 `child` 属性才是用户界面的根 `RenderObject`。
    // 最好明确类型或通过更安全的 API 获取子渲染对象。
    // 现在 _ignorePointer 是 RenderObject 类型
    final RenderObject? userRender =
        (rootRenderObject as dynamic).child as RenderObject?;

    if (userRender == null) {
      debugPrint(
        'Warning: User render object not found. Cannot initialize selection.',
      );
      return;
    }

    List<RenderObject> objectList = [];

    // 递归函数：查找所有 RenderObject 类型的子节点。
    void findAllRenderObject(RenderObject object) {
      try {
        final List<DiagnosticsNode> children = object.debugDescribeChildren();
        for (final c in children) {
          // 仅处理可见的 RenderBox 类型子节点
          if (c.style == DiagnosticsTreeStyle.offstage ||
              c.value is! RenderBox) {
            continue;
          }
          final RenderObject child = c.value as RenderObject;
          objectList.add(child);
          findAllRenderObject(child);
        }
      } catch (e) {
        debugPrint('Error traversing render object children: $e');
        // 继续遍历其他分支或停止，取决于错误性质
      }
    }

    findAllRenderObject(userRender);

    // 按照面积大小进行排序 (从小到大)
    objectList.sort(
      (RenderObject a, RenderObject b) => _area(a).compareTo(_area(b)),
    );

    // 使用 Set 去重并保持顺序
    Set<RenderObject> objectSet = <RenderObject>{};
    objectSet.addAll(objectList);
    objectList = objectSet.toList(); // 转换为 List

    // 将处理后的渲染对象列表设置为 Inspector 的候选列表。
    selection.candidates = objectList;
  }

  /// 根据当前选中 Widget 的文件路径，获取其源代码。
  ///
  /// 返回：源代码字符串，如果获取失败则为 `null`。
  Future<String?> getCode(String packagePath) async {
    if (filePath == null || filePath!.isEmpty) {
      debugPrint('Error: filePath is null or empty for current selection.');
      return null;
    }

    try {
      String? scriptId = await _codeDisplayService.getScriptIdByPackagePath(
        packagePath,
      );

      if (scriptId == null) {
        debugPrint('Script ID not found for file: $packagePath');
        return null;
      }
      String? sourceCode = await _codeDisplayService.getSourceCodeByScriptId(
        scriptId,
      );
      if (sourceCode == null) {
        debugPrint('Source code is null for script ID: $scriptId');
      }
      return sourceCode;
    } catch (e) {
      debugPrint('Error getting code for file "$packagePath": $e');
      return null;
    }
  }

  /// 根据指定的文件名（或部分文件名）获取其源代码。
  ///
  /// [fileName]：要查找的文件的名称或部分名称。
  /// 返回：源代码字符串，如果获取失败则为 `null`。
  Future<String?> getCodeByFileName(String fileName) async {
    try {
      String? scriptId = await _codeDisplayService.getScriptIdByPackagePath(
        fileName,
      );
      if (scriptId == null) {
        debugPrint('Script ID not found for file name substring: $fileName');
        return null;
      }
      String? sourceCode = await _codeDisplayService.getSourceCodeByScriptId(
        scriptId,
      );
      if (sourceCode == null) {
        debugPrint('Source code is null for script ID: $scriptId');
      }
      return sourceCode;
    } catch (e) {
      debugPrint('Error getting code by file name "$fileName": $e');
      return null;
    }
  }

  /// 根据关键词获取所有匹配的脚本的 URI 和源代码。
  ///
  /// [keyword]：用于在脚本 URI 中匹配的关键词。
  /// 返回：一个 Map，键是脚本 URI，值是对应的源代码字符串。
  /// 只有成功获取到源代码的脚本才会被包含在结果中。
  Future<Map<String?, String>> getCodeListByKeyword(String keyword) async {
    final Map<String?, String> result = <String?, String>{};
    try {
      // 获取所有匹配关键词的脚本 ID 和 URI
      final scriptUris = await _codeDisplayService.findScriptUrisByKeyword(
        keyword,
      );

      if (scriptUris.isEmpty) {
        debugPrint('No scripts found with keyword: $keyword');
        return result;
      }

      // 遍历所有匹配的脚本，尝试获取其源代码
      for (final entry in scriptUris.entries) {
        final scriptId = entry.key;
        final scriptUri = entry.value;

        // 确保 scriptId 非空
        if (scriptId != null) {
          final code = await _codeDisplayService.getSourceCodeByScriptId(
            scriptId,
          );
          // 仅当源代码非空且非空字符串时才添加到结果中
          if (code != null && code.isNotEmpty) {
            result[scriptUri] = code;
          } else {
            debugPrint(
              'Warning: Could not retrieve source code for script ID: $scriptId (URI: $scriptUri)',
            );
          }
        } else {
          debugPrint('Warning: Null script ID found for URI: $scriptUri');
        }
      }
    } catch (e) {
      debugPrint('Error getting code list by keyword "$keyword": $e');
      // 返回目前收集到的部分结果或空 Map
    }
    return result;
  }
}
