import 'package:flutter_mana/flutter_mana_diagnostics.dart';
import 'package:vm_service/vm_service.dart';

class MemorySnapshot {
  MemorySnapshot(this.vm, this.usage, List<ClassHeapStats> classes)
    : classes = List.unmodifiable(classes);
  final VM vm;
  final MemoryUsage usage;
  final List<ClassHeapStats> classes;
}

class MemoryService {
  MemoryService({VmInspector? inspector})
    : inspector = inspector ?? VmInspector();
  final VmInspector inspector;
  Future<MemorySnapshot> load() async {
    final (vm, usage, classes) = await (
      inspector.getVM(),
      inspector.getMemoryUsage(),
      inspector.getAllocationProfile(reset: false),
    ).wait;
    return MemorySnapshot(vm, usage, classes.members ?? const []);
  }

  Future<Class?> classDetails(String id) async {
    if (id.isEmpty) return null;
    final object = await inspector.getObject(id);
    return object is Class ? object : null;
  }

  Future<void> close() => inspector.disconnect();
  static String formatBytes(int bytes) => switch (bytes) {
    >= 1073741824 => '${(bytes / 1073741824).toStringAsFixed(1)} GiB',
    >= 1048576 => '${(bytes / 1048576).toStringAsFixed(1)} MiB',
    >= 1024 => '${(bytes / 1024).toStringAsFixed(1)} KiB',
    _ => '$bytes B',
  };
}
