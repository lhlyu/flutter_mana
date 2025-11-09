import 'dart:developer';
import 'dart:isolate';

import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';

const _logPrefix = '[VmInspector]';

/// `VmInspector` 类封装了与 Dart VM 服务交互的各种操作。
/// 它提供了一系列方法来获取 VM 信息、内存使用情况、类列表、快照等。
class VmInspector {
  static final VmInspector _instance = VmInspector._internal();

  factory VmInspector() => _instance;

  VmInspector._internal() {
    _isolateId = Service.getIsolateId(Isolate.current);
  }

  vm.VmService? _service;
  String? _isolateId;

  // 是否已有连接正在创建中
  Future<vm.VmService>? _connectingFuture;

  String get isolateId {
    if (_isolateId == null) {
      throw StateError('$_logPrefix Isolate ID has not been initialized.');
    }
    return _isolateId!;
  }

  Future<vm.VmService> getVMService() async {
    // 已连接，直接返回
    if (_service != null) return _service!;

    // 如果正在连接中，复用正在进行的 future
    if (_connectingFuture != null) return _connectingFuture!;

    // 否则新建连接并缓存 future，确保并发时只走一次连接逻辑
    _connectingFuture = _connect();
    try {
      _service = await _connectingFuture!;
      return _service!;
    } finally {
      _connectingFuture = null; // 清理
    }
  }

  Future<vm.VmService> _connect() async {
    try {
      final info = await Service.getInfo();
      final wsUri = convertToWebSocketUrl(serviceProtocolUrl: info.serverUri!);
      final service = await vmServiceConnectUri(wsUri.toString());
      return service;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_service != null) {
      try {
        await _service!.dispose();
      } catch (e) {
        rethrow;
      }
      _service = null;
    }
  }

  /// 获取 Dart VM 的信息。
  Future<vm.VM> getVM() async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getVM();
  }

  /// 获取当前协程的内存使用情况。
  Future<vm.MemoryUsage> getMemoryUsage() async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getMemoryUsage(
      isolateId,
    ); // 使用非空断言，因为 isolateId 已在构造函数中初始化
  }

  /// 获取当前协程中所有已加载类的列表。
  Future<vm.ClassList> getClassList() async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getClassList(isolateId);
  }

  /// 获取当前协程的内存分配概要信息，并重置统计数据。
  /// 允许通过参数控制是否重置统计数据。
  Future<vm.AllocationProfile> getAllocationProfile({bool reset = true}) async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getAllocationProfile(isolateId, reset: reset);
  }

  /// 获取当前协程的详细信息。
  Future<vm.Isolate> getIsolate() async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getIsolate(isolateId);
  }

  /// 获取当前协程中所有已加载库的引用列表。
  Future<List<vm.LibraryRef>?> getLibraries() async {
    vm.Isolate isolate = await getIsolate();
    return isolate.libraries;
  }

  /// 获取当前协程的堆快照图。
  Future<vm.HeapSnapshotGraph> getSnapshot() async {
    vm.VmService virtualMachine = await getVMService();
    vm.Isolate isolate = await getIsolate();
    return vm.HeapSnapshotGraph.getSnapshot(virtualMachine, isolate);
  }

  /// 获取指定对象 ID 的实例集合。
  /// [objectId]：对象的 ID。
  /// [limit]：返回实例的最大数量。
  /// 添加了错误处理以捕获 API 调用失败的情况。
  Future<vm.InstanceSet> getInstances(String objectId, int limit) async {
    vm.VmService virtualMachine = await getVMService();
    try {
      return virtualMachine.getInstances(isolateId, objectId, limit);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取当前协程的调用栈信息。
  Future<vm.Stack> getStack() async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getStack(isolateId);
  }

  /// 获取指定对象 ID 的详细信息。
  /// [objectId]：对象的 ID。
  /// [offset]：如果对象是列表或字符串，表示开始获取的偏移量。
  /// [count]：如果对象是列表或字符串，表示获取的元素或字符数量。
  Future<vm.Obj> getObject(String objectId, {int? offset, int? count}) async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getObject(
      isolateId,
      objectId,
      offset: offset,
      count: count,
    );
  }

  /// 获取指向指定对象的入站引用。
  /// [objectId]：对象的 ID。
  /// [limit]：返回入站引用的最大数量，默认为 100。
  Future<vm.InboundReferences> getInboundReferences(
    String objectId, {
    int limit = 100,
  }) async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getInboundReferences(isolateId, objectId, limit);
  }

  /// 获取所有类的堆统计信息，只返回当前字节数或实例数大于 0 的类。
  /// 可以通过可选参数 [minBytes] 和 [minInstances] 来调整过滤条件。
  Future<List<vm.ClassHeapStats>> getClassHeapStats({
    int minBytes = 0,
    int minInstances = 0,
  }) async {
    vm.AllocationProfile profile = await getAllocationProfile(); // 获取最新的分配概要
    List<vm.ClassHeapStats> list =
        profile.members!
            .where(
              (element) =>
                  element.bytesCurrent! > minBytes ||
                  element.instancesCurrent! > minInstances,
            )
            .toList();
    return list;
  }

  /// 获取当前协程中所有已加载脚本的列表。
  Future<vm.ScriptList> getScripts() async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getScripts(isolateId);
  }

  /// 在指定目标上评估一个表达式。
  /// [targetId]：目标对象的 ID，通常是库或类。
  /// [expression]：要评估的 Dart 表达式字符串。
  /// 添加了错误处理以捕获评估失败的情况。
  Future<vm.Response> evaluate(String targetId, String expression) async {
    vm.VmService virtualMachine = await getVMService();
    try {
      return virtualMachine.evaluate(isolateId, targetId, expression);
    } catch (e) {
      rethrow;
    }
  }
}
