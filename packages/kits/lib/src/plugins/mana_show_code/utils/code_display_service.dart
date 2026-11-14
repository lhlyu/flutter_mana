import 'package:flutter_mana/flutter_mana_diagnostics.dart';
import 'package:vm_service/vm_service.dart';

class CodeDisplayService {
  CodeDisplayService({VmInspector? inspector})
    : inspector = inspector ?? VmInspector();
  final VmInspector inspector;
  Future<List<ScriptRef>> scripts() async {
    final scripts = (await inspector.getScripts()).scripts ?? <ScriptRef>[];
    return scripts
        .where((script) => script.id != null && script.uri != null)
        .toList()
      ..sort((a, b) => a.uri!.compareTo(b.uri!));
  }

  Future<String> source(ScriptRef script) async {
    final object = await inspector.getObject(script.id!);
    if (object is Script && object.source != null) return object.source!;
    throw StateError('Source is unavailable: ${script.uri}');
  }

  Future<void> close() => inspector.disconnect();
}
