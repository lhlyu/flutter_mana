import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana_diagnostics.dart';
import 'package:flutter_mana_kits/src/plugins/mana_memory_info/utils/memory_service.dart';
import 'package:flutter_mana_kits/src/plugins/mana_memory_info/widgets/memory_info_content.dart';
import 'package:flutter_mana_kits/src/plugins/mana_show_code/utils/code_display_service.dart';
import 'package:flutter_mana_kits/src/plugins/mana_show_code/widgets/show_code_content.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vm_service/vm_service.dart' as vm;

import 'support/host.dart';

class _Vm extends VmInspector {
  bool fail = false;
  int allocationCalls = 0;
  int disconnectCalls = 0;
  @override
  Future<void> disconnect() async {
    disconnectCalls++;
  }

  bool? reset;
  @override
  Future<vm.VM> getVM() async =>
      vm.VM(pid: 123, hostCPU: 'arm64', version: 'test');
  @override
  Future<vm.MemoryUsage> getMemoryUsage() async =>
      vm.MemoryUsage(heapUsage: 1024, heapCapacity: 2048, externalUsage: 0);
  @override
  Future<vm.AllocationProfile> getAllocationProfile({bool reset = true}) async {
    allocationCalls++;
    this.reset = reset;
    if (fail) throw StateError('offline');
    return vm.AllocationProfile(
      members: [
        vm.ClassHeapStats(
          classRef: vm.ClassRef(id: 'class', name: 'Example'),
          bytesCurrent: 512,
          accumulatedSize: 999999,
          instancesCurrent: 2,
        ),
        vm.ClassHeapStats(
          classRef: vm.ClassRef(id: 'private', name: '_Private'),
          bytesCurrent: 2048,
          instancesCurrent: 1,
        ),
      ],
    );
  }

  @override
  Future<vm.ScriptList> getScripts() async {
    if (fail) throw StateError('offline');
    return vm.ScriptList(
      scripts: [vm.ScriptRef(id: 'script', uri: 'package:app/main.dart')],
    );
  }

  @override
  Future<vm.Obj> getObject(String id, {int? offset, int? count}) async {
    if (fail) throw StateError('offline');
    if (id == 'class') {
      return vm.Class(
        id: id,
        name: 'Example',
        fields: [
          vm.FieldRef(
            name: 'answer',
            isStatic: true,
            isConst: true,
            isFinal: true,
            declaredType: vm.InstanceRef(name: 'int'),
          ),
          vm.FieldRef(
            name: 'count',
            isStatic: true,
            isFinal: true,
            declaredType: vm.InstanceRef(name: 'int'),
          ),
        ],
        functions: [vm.FuncRef(id: 'function', name: 'run')],
      );
    }
    return vm.Script(
      id: id,
      uri: 'package:app/main.dart',
      source: 'sealed class Example {}',
    );
  }
}

Finder button(String label) => find.byWidgetPredicate(
  (widget) => widget is KitButton && widget.label == label,
);

void main() {
  for (final memory in [true, false]) {
    testWidgets(
      '${memory ? 'memory' : 'source'} changes services without closing injected resources',
      (tester) async {
        final first = _Vm();
        final second = _Vm()..fail = true;
        await tester.pumpWidget(
          testHost(
            memory
                ? MemoryInfoContent(service: MemoryService(inspector: first))
                : ShowCodeContent(
                    service: CodeDisplayService(inspector: first),
                  ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          testHost(
            memory
                ? MemoryInfoContent(service: MemoryService(inspector: second))
                : ShowCodeContent(
                    service: CodeDisplayService(inspector: second),
                  ),
          ),
        );
        await tester.pumpAndSettle();
        expect(button('Retry'), findsOneWidget);
        expect(first.disconnectCalls, 0);
        await tester.pumpWidget(const SizedBox());
        expect(second.disconnectCalls, 0);
      },
    );
  }

  testWidgets(
    'memory statistics show live bytes without resetting VM counters, detail stays local',
    (tester) async {
      final vm = _Vm();
      final service = MemoryService(inspector: vm);
      await tester.pumpWidget(testHost(MemoryInfoContent(service: service)));
      await tester.pumpAndSettle();
      expect(vm.reset, isFalse);
      expect(find.text('512 B'), findsOneWidget);
      expect(find.text('_Private'), findsNothing);
      await tester.tap(find.text('Example'));
      await tester.pumpAndSettle();
      expect(find.text('run'), findsOneWidget);
      expect(
        find.text('static const int answer\nstatic final int count'),
        findsOneWidget,
      );
      expect(find.byType(Navigator), findsOneWidget);
      await tester.tap(button('Back'));
      await tester.pumpAndSettle();
      expect(find.text('512 B'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await service.close();
    },
  );
  testWidgets('memory errors are visible and retriable', (tester) async {
    final vm = _Vm()..fail = true;
    final service = MemoryService(inspector: vm);
    await tester.pumpWidget(testHost(MemoryInfoContent(service: service)));
    await tester.pumpAndSettle();
    expect(button('Retry'), findsOneWidget);
    vm.fail = false;
    await tester.tap(button('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('512 B'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await service.close();
  });
  testWidgets(
    'source browser searches exact script URIs and renders code using Widgets',
    (tester) async {
      final service = CodeDisplayService(inspector: _Vm());
      await tester.pumpWidget(testHost(ShowCodeContent(service: service)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'APP/MAIN');
      await tester.pumpAndSettle();
      await tester.tap(find.text('package:app/main.dart'));
      await tester.pumpAndSettle();
      expect(
        find.text('sealed class Example {}', findRichText: true),
        findsOneWidget,
      );
      expect(find.byType(Navigator), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await service.close();
    },
  );
}
