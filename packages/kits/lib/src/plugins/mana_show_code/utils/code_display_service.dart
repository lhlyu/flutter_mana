import 'package:flutter/cupertino.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:vm_service/vm_service.dart';

/// `CodeDisplayService` 类利用 `VMvmInspector` 提供的服务，
/// 专注于获取和显示 Dart VM 中与代码相关的信息，例如类ID、脚本ID和源代码。
class CodeDisplayService with VmInspectorMixin {
  /// 根据类名获取对应的类 ID。
  ///
  /// [className]：要查找的类的名称。
  /// 返回：如果找到匹配的类，则返回其 ID；否则返回 `null`。
  Future<String?> getClassIdByName(String className) async {
    try {
      final classList = await vmInspector.getClassList();
      final classes = classList.classes;

      // 显式检查 classes 是否为空或没有元素
      if (classes == null || classes.isEmpty) {
        debugPrint('Warning: No classes found in the VM service.');
        return null;
      }

      for (final cls in classes) {
        // 确保 cls.name 非空再进行比较
        if (cls.name == className) {
          return cls.id;
        }
      }
      debugPrint('Info: Class "$className" not found.');
      return null;
    } catch (e) {
      debugPrint('Error getting class ID for "$className": $e');
      return null;
    }
  }

  /// 根据文件名（或文件路径中的部分字符串）获取对应的脚本 ID。
  ///
  /// [packagePath]：要查找的文件名或文件路径中的关键词。
  /// 返回：如果找到包含该文件名的脚本，则返回其 ID；否则返回 `null`。
  Future<String?> getScriptIdByPackagePath(String packagePath) async {
    try {
      ScriptList scriptList = await vmInspector.getScripts();
      final scripts = scriptList.scripts;

      // 显式检查 scripts 是否为空或没有元素
      if (scripts == null || scripts.isEmpty) {
        debugPrint('Warning: No scripts found in the VM service.');
        return null;
      }

      for (final script in scripts) {
        // 确保 script.uri 非空再进行包含检查
        if (script.uri?.contains(packagePath) ?? false) {
          return script.id;
        }
      }
      debugPrint('Info: Script containing "$packagePath" not found.');
      return null;
    } catch (e) {
      debugPrint('Error getting script ID for "$packagePath": $e');
      return null;
    }
  }

  /// 根据关键词获取所有匹配的脚本 ID 和对应的 URI。
  ///
  /// [keyword]：用于在脚本 URI 中匹配的关键词。
  /// 返回：一个映射（Map），键是脚本 ID，值是脚本 URI。
  Future<Map<String?, String?>> findScriptUrisByKeyword(String keyword) async {
    final result = <String?, String?>{};
    try {
      ScriptList scriptList = await vmInspector.getScripts();
      final scripts = scriptList.scripts;

      // 显式检查 scripts 是否为空或没有元素
      if (scripts == null || scripts.isEmpty) {
        debugPrint('Warning: No scripts found in the VM service.');
        return result; // 返回空 Map
      }

      for (var script in scripts) {
        // 确保 script.uri 非空再进行包含检查
        if (script.uri?.contains(keyword) ?? false) {
          result[script.id] = script.uri;
        }
      }
    } catch (e) {
      debugPrint('Error finding script URIs with keyword "$keyword": $e');
      // 可以选择在此处重新抛出异常，或返回部分结果，取决于具体需求
    }
    return result;
  }

  /// 根据脚本 ID 获取其源代码。
  ///
  /// [scriptId]：要获取源代码的脚本 ID。
  /// 返回：如果成功获取到脚本源代码，则返回源代码字符串；否则返回 `null`。
  Future<String?> getSourceCodeByScriptId(String scriptId) async {
    try {
      Obj scriptObject = await vmInspector.getObject(scriptId);
      // 检查获取到的对象是否是 `Script` 类型，并且其 source 属性非空
      if (scriptObject is Script) {
        if (scriptObject.source != null) {
          return scriptObject.source;
        } else {
          debugPrint('Warning: Source code is null for script ID: $scriptId');
          return null;
        }
      } else {
        debugPrint('Error: Object with ID $scriptId is not a Script type.');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting source code for script ID "$scriptId": $e');
      return null;
    }
  }
}
