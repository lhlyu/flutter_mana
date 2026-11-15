import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';

const _logPrefix = '[VmInspector]';

/// Owns a VM Service connection for the current isolate.
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

  Future<vm.VM> getVM() async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getVM();
  }

  Future<vm.MemoryUsage> getMemoryUsage() async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getMemoryUsage(isolateId);
  }

  Future<vm.ClassList> getClassList() async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getClassList(isolateId);
  }

  /// Set [reset] to clear allocation counters after reading.
  Future<vm.AllocationProfile> getAllocationProfile({bool reset = true}) async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getAllocationProfile(isolateId, reset: reset);
  }

  Future<vm.Isolate> getIsolate() async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getIsolate(isolateId);
  }

  Future<List<vm.LibraryRef>?> getLibraries() async {
    vm.Isolate isolate = await getIsolate();
    return isolate.libraries;
  }

  Future<vm.HeapSnapshotGraph> getSnapshot() async {
    vm.VmService virtualMachine = await getVMService();
    vm.Isolate isolate = await getIsolate();
    return vm.HeapSnapshotGraph.getSnapshot(virtualMachine, isolate);
  }

  Future<vm.InstanceSet> getInstances(String objectId, int limit) async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getInstances(isolateId, objectId, limit);
  }

  Future<vm.Stack> getStack() async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getStack(isolateId);
  }

  /// [offset] and [count] page through list elements or string characters.
  Future<vm.Obj> getObject(String objectId, {int? offset, int? count}) async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getObject(
      isolateId,
      objectId,
      offset: offset,
      count: count,
    );
  }

  Future<vm.InboundReferences> getInboundReferences(
    String objectId, {
    int limit = 100,
  }) async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getInboundReferences(isolateId, objectId, limit);
  }

  /// Returns entries above either threshold without resetting allocation counters.
  Future<List<vm.ClassHeapStats>> getClassHeapStats({
    int minBytes = 0,
    int minInstances = 0,
  }) async {
    final profile = await getAllocationProfile(reset: false);
    return (profile.members ?? const <vm.ClassHeapStats>[])
        .where(
          (element) =>
              (element.bytesCurrent ?? 0) > minBytes ||
              (element.instancesCurrent ?? 0) > minInstances,
        )
        .toList();
  }

  Future<vm.ScriptList> getScripts() async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.getScripts(isolateId);
  }

  Future<vm.Response> evaluate(String targetId, String expression) async {
    vm.VmService virtualMachine = await getVMService();
    return virtualMachine.evaluate(isolateId, targetId, expression);
  }
}
