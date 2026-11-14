import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';

const _logPrefix = '[VmInspector]';

/// `VmInspector` 类封装了与 Dart VM 服务交互的各种操作。
/// 它提供了一系列方法来获取 VM 信息、内存使用情况、类列表、快照等。
class VmInspector {
  VmInspector({Future<vm.VmService> Function()? connect})
    : _connector = connect {
    _isolateId = Service.getIsolateId(Isolate.current);
  }

  final Future<vm.VmService> Function()? _connector;
  vm.VmService? _service;
  String? _isolateId;
  Future<vm.VmService>? _connectingFuture;
  int _generation = 0;

  bool get isSupported => true;
  String get isolateId =>
      _isolateId ?? (throw StateError('$_logPrefix Isolate is unavailable.'));

  Future<vm.VmService> getVMService() {
    if (_service case final service?) return Future.value(service);
    final generation = _generation;
    return _connectingFuture ??= Future.microtask(() => _connect(generation));
  }

  Future<vm.VmService> _connect(int generation) async {
    try {
      final service = await (_connector?.call() ?? _openConnection());
      if (generation != _generation) {
        await service.dispose();
        throw StateError('$_logPrefix Connection was cancelled.');
      }
      _service = service;
      unawaited(
        service.onDone.then((_) {
          if (identical(_service, service)) _service = null;
        }),
      );
      return service;
    } finally {
      if (generation == _generation) _connectingFuture = null;
    }
  }

  Future<vm.VmService> _openConnection() async {
    final uri = (await Service.getInfo()).serverUri;
    if (uri == null) {
      throw UnsupportedError(
        '$_logPrefix VM Service is not enabled in this build.',
      );
    }
    return vmServiceConnectUri(
      convertToWebSocketUrl(serviceProtocolUrl: uri).toString(),
    );
  }

  Future<void> disconnect() async {
    _generation++;
    final service = _service;
    final connecting = _connectingFuture;
    _service = null;
    _connectingFuture = null;
    await service?.dispose();
    if (connecting != null) {
      try {
        await connecting;
      } catch (_) {
        /* Cancelled by the generation guard. */
      }
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
  Future<vm.InstanceSet> getInstances(String objectId, int limit) async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getInstances(isolateId, objectId, limit);
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
    List<vm.ClassHeapStats> list = profile.members!
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
  Future<vm.Response> evaluate(String targetId, String expression) async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.evaluate(isolateId, targetId, expression);
  }
}
