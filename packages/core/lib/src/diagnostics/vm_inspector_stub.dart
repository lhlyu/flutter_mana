import 'package:vm_service/vm_service.dart' as vm;

class VmInspector {
  VmInspector({Future<vm.VmService> Function()? connect});
  bool get isSupported => false;
  String get isolateId =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<void> disconnect() async {}
  Future<vm.VmService> getVMService() async =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<vm.VM> getVM() async =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<vm.MemoryUsage> getMemoryUsage() async =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<vm.ClassList> getClassList() async =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<vm.AllocationProfile> getAllocationProfile({
    bool reset = true,
  }) async => throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<vm.Isolate> getIsolate() async =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<List<vm.LibraryRef>?> getLibraries() async =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<vm.HeapSnapshotGraph> getSnapshot() async =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<vm.InstanceSet> getInstances(String objectId, int limit) async =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<vm.Stack> getStack() async =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<vm.Obj> getObject(String objectId, {int? offset, int? count}) async =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<vm.InboundReferences> getInboundReferences(
    String objectId, {
    int limit = 100,
  }) async => throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<List<vm.ClassHeapStats>> getClassHeapStats({
    int minBytes = 0,
    int minInstances = 0,
  }) async => throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<vm.ScriptList> getScripts() async =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
  Future<vm.Response> evaluate(String targetId, String expression) async =>
      throw UnsupportedError('VM diagnostics require a Dart VM.');
}
