import 'package:flutter/cupertino.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:vm_service/vm_service.dart';

/// 表示一个类的属性信息。
class Property {
  /// 是否为常量属性。
  final bool isConst;

  /// 是否为静态属性。
  final bool isStatic;

  /// 是否为 final 属性。
  final bool isFinal;

  /// 属性的类型。
  final String type;

  /// 属性的名称。
  final String name;

  /// 构造函数，用于创建 Property 实例。
  ///
  /// 使用 required 关键字确保这些属性在创建时必须被提供。
  const Property({
    required this.isConst,
    required this.isStatic,
    required this.isFinal,
    required this.type,
    required this.name,
  });

  /// 获取属性的字符串表示形式。
  /// 例如："static String propertyName" 或 "final int value"。
  String get propertyStr {
    // 根据属性类型确定修饰符，优先顺序：static > const > final
    final String modifier = isStatic
        ? "static"
        : isConst
            ? "const"
            : isFinal
                ? "final"
                : ""; // 如果都不是，则为空

    // 组合修饰符、类型和名称，注意修饰符和类型之间可能存在空格
    return "$modifier $type $name".trim();
  }
}

/// 表示一个类的模型，包含其属性和函数。
class ClsModel {
  /// 类的属性列表。
  final List<Property> properties;

  /// 类的函数名称列表。
  final List<String> functions;

  /// 构造函数，用于创建 ClsModel 实例。
  ///
  /// 使用 required 关键字确保这些属性在创建时必须被提供。
  const ClsModel({
    required this.properties,
    required this.functions,
  });
}

/// VM（虚拟机）的详细信息。
class VmInfo {
  final int? pid;
  final String? hostCPU;
  final String? version;

  const VmInfo({this.pid, this.hostCPU, this.version});
}

/// 内存使用情况的详细信息。
class MemoryInfo {
  final int externalUsageBytes;
  final String externalUsageFormatted;
  final int heapCapacityBytes;
  final String heapCapacityFormatted;
  final int heapUsageBytes;
  final String heapUsageFormatted;

  const MemoryInfo({
    required this.externalUsageBytes,
    required this.externalUsageFormatted,
    required this.heapCapacityBytes,
    required this.heapCapacityFormatted,
    required this.heapUsageBytes,
    required this.heapUsageFormatted,
  });
}

/// 扩展 [ClassHeapStats]，增加格式化后的累积大小属性。
class FormattedClassHeapStats extends ClassHeapStats {
  final String accumulatedSizeFormatted;

  FormattedClassHeapStats({
    super.classRef,
    super.accumulatedSize,
    super.bytesCurrent,
    super.instancesAccumulated,
    super.instancesCurrent,
    required this.accumulatedSizeFormatted, // 新增的格式化属性
  });

  // 工厂构造函数，用于从 ClassHeapStats 实例创建 FormattedClassHeapStats
  factory FormattedClassHeapStats.fromClassHeapStats(ClassHeapStats stats) {
    return FormattedClassHeapStats(
      classRef: stats.classRef,
      accumulatedSize: stats.accumulatedSize,
      bytesCurrent: stats.bytesCurrent,
      instancesAccumulated: stats.instancesAccumulated,
      instancesCurrent: stats.instancesCurrent,
      accumulatedSizeFormatted: MemoryService.byteToString(stats.accumulatedSize ?? 0),
    );
  }
}

/// 内存服务类，用于与 Dart VM 服务交互，获取内存和类信息。
/// 混入 [VmInspectorMixin] 提供 VM 服务相关的方法。
class MemoryService with VmInspectorMixin {
  /// 存储所有类的堆统计信息列表。
  List<FormattedClassHeapStats> classHeapStatsList = [];

  /// VM（虚拟机）的详细信息。
  VmInfo? vmInfo;

  /// 内存使用情况的详细信息。
  MemoryInfo? memoryUsageInfo;

  /// 从 VM 服务获取所有必要的信息，并在完成后执行回调。
  ///
  /// [completion] 回调函数，在所有信息获取并处理完毕后调用。
  Future<void> getInfos(void Function() completion) async {
    try {
      final results = await Future.wait([
        vmInspector.getClassHeapStats(), // 获取类堆统计信息
        vmInspector.getMemoryUsage(), // 获取内存使用情况
        vmInspector.getVM(), // 获取 VM 详细信息
      ]);

      // 使用模式匹配解构 results 列表，并进行类型安全检查。
      if (results case [List<ClassHeapStats> heapStats, MemoryUsage memoryUsage, VM vm]) {
        // 处理并存储格式化后的类堆统计信息
        classHeapStatsList = heapStats.map((stats) => FormattedClassHeapStats.fromClassHeapStats(stats)).toList()
          ..sort((a, b) => b.accumulatedSize?.compareTo(a.accumulatedSize ?? 0) ?? 0); // 默认按累积大小降序排序

        vmInfo = VmInfo(
          pid: vm.pid,
          hostCPU: vm.hostCPU,
          version: vm.version,
        );

        memoryUsageInfo = MemoryInfo(
          externalUsageBytes: memoryUsage.externalUsage ?? 0,
          externalUsageFormatted: byteToString(memoryUsage.externalUsage ?? 0),
          heapCapacityBytes: memoryUsage.heapCapacity ?? 0,
          heapCapacityFormatted: byteToString(memoryUsage.heapCapacity ?? 0),
          heapUsageBytes: memoryUsage.heapUsage ?? 0,
          heapUsageFormatted: byteToString(memoryUsage.heapUsage ?? 0),
        );

        completion();
      } else {
        debugPrint("Get vm info failed or unexpected result type.");
        // 在实际应用中，你可能需要更健壮的错误处理，例如抛出异常。
      }
    } catch (e) {
      debugPrint('Get vm info error: $e');
    }
  }

  /// 根据类ID获取指定数量的实例ID。
  ///
  /// [classId] 类的唯一标识符。
  /// [limit] 返回实例的最大数量。
  /// [completion] 回调函数，返回实例ID列表。
  Future<void> getInstanceIds(
    String classId,
    int limit,
    void Function(List<String>?) completion,
  ) async {
    final instanceSet = await vmInspector.getInstances(classId, limit);
    // 使用 null-aware 操作符和 map 转换列表，确保安全。
    // 如果 instances 为 null，则返回一个空列表。
    final instanceIds = instanceSet.instances?.map((e) => e.id).whereType<String>().toList();
    completion(instanceIds);
  }

  /// 获取类的详细信息，包括属性和函数。
  ///
  /// [classId] 类的唯一标识符。
  /// [completion] 回调函数，返回 [ClsModel] 实例或 null。
  Future<void> getClassDetailInfo(
    String classId,
    void Function(ClsModel?) completion,
  ) async {
    if (classId.isEmpty) {
      completion(null);
      return;
    }

    final obj = await vmInspector.getObject(classId);

    // 如果不是 Class 类型，则直接返回 null
    if (obj is! Class) {
      completion(null);
      return;
    }

    final cls = obj;
    final List<Property> properties = [];
    final List<String> functions = [];

    // 处理类的字段（属性）。
    for (final fieldRef in cls.fields ?? []) {
      // 确保类型名称存在
      if (fieldRef.declaredType?.name != null) {
        properties.add(Property(
          isConst: fieldRef.isConst ?? false,
          isStatic: fieldRef.isStatic ?? false,
          isFinal: fieldRef.isFinal ?? false,
          type: fieldRef.declaredType!.name!,
          name: fieldRef.name ?? 'N/A', // 如果名称为 null，则显示 'N/A'
        ));
      }
    }

    // 处理类的函数。
    for (final funcRef in cls.functions ?? []) {
      if (funcRef.id == null) continue; // 跳过没有ID的函数

      final funcObj = await vmInspector.getObject(funcRef.id!);
      if (funcObj is Func) {
        // 过滤掉 [Stub] 函数，并清理名称中的 [Unoptimized] 和 [Optimized]
        if (funcObj.code?.name != null && !funcObj.code!.name!.contains("[Stub]")) {
          String cleanedCodeName = funcObj.code!.name!.replaceAll('[Unoptimized] ', '').replaceAll('[Optimized] ', '');
          functions.add(cleanedCodeName);
        }
      }
    }

    // 创建 ClsModel 实例并调用完成回调。
    final clsModel = ClsModel(properties: properties, functions: functions);
    completion(clsModel);
  }

  /// 对 [classHeapStatsList] 进行排序。
  ///
  /// [getField] 用于获取排序依据的字段。
  /// [descending] 是否按降序排列。
  /// [completion] 排序完成后调用的回调函数。
  ///
  /// 这是一个通用排序方法，可以根据不同的字段进行排序。
  void sortClassHeapStats<T extends Comparable<Object?>>(
    T Function(FormattedClassHeapStats d) getField,
    bool descending,
    void Function() completion,
  ) {
    classHeapStatsList.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return descending ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
    });
    completion();
  }

  static const int kiloByte = 1024;
  static const int megaByte = kiloByte * 1024;
  static const int gigaByte = megaByte * 1024;

  /// 将字节数转换为可读的字符串格式（B, K, M, G）。
  ///
  /// [size] 字节数。
  /// 返回格式化后的字符串。
  static String byteToString(int size) {
    if (size >= gigaByte) {
      return "${(size / gigaByte).toStringAsFixed(1)} G";
    } else if (size >= megaByte) {
      return "${(size / megaByte).toStringAsFixed(1)} M";
    } else if (size >= kiloByte) {
      return "${(size / kiloByte).toStringAsFixed(1)} K";
    } else {
      return "$size B";
    }
  }
}
