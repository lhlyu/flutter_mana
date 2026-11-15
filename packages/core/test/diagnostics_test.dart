import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vm_service/vm_service.dart' as vm;

import 'support/helpers.dart';

class _HeapInspector extends VmInspector {
  vm.AllocationProfile profile = vm.AllocationProfile();
  bool? lastReset;

  @override
  Future<vm.AllocationProfile> getAllocationProfile({bool reset = true}) async {
    lastReset = reset;
    return profile;
  }
}

void main() {
  test(
    'heap summaries tolerate omitted fields without resetting VM counters',
    () async {
      final inspector = _HeapInspector();
      expect(await inspector.getClassHeapStats(), isEmpty);
      final used = vm.ClassHeapStats(bytesCurrent: 16);
      final instantiated = vm.ClassHeapStats(instancesCurrent: 2);
      inspector.profile = vm.AllocationProfile(
        members: [vm.ClassHeapStats(), used, instantiated],
      );
      expect(await inspector.getClassHeapStats(), [used, instantiated]);
      expect(
        await inspector.getClassHeapStats(minBytes: 16, minInstances: 2),
        isEmpty,
      );
      expect(inspector.lastReset, isFalse);
    },
  );
  vm.VmService service() => vm.VmService(const Stream.empty(), (_) {});

  test('VM connections are shared in flight but not shared between inspector instances', () async {
    final gate = Completer<vm.VmService>();
    var calls = 0;
    final inspector = VmInspector(
      connect: () {
        calls++;
        return gate.future;
      },
    );
    final first = inspector.getVMService();
    final second = inspector.getVMService();
    await Future<void>.delayed(.zero);
    final connection = service();
    gate.complete(connection);
    expect(await first, same(await second));
    expect(calls, 1);
    await inspector.disconnect();
  });

  test('a failed connector can be retried', () async {
    var calls = 0;
    final inspector = VmInspector(
      connect: () async {
        if (calls++ == 0) throw StateError('offline');
        return service();
      },
    );
    await expectLater(inspector.getVMService(), throwsStateError);
    await inspector.getVMService();
    expect(calls, 2);
    await inspector.disconnect();
  });

  test(
    'disconnect cancels an in-flight connection and disposes the late socket',
    () async {
      final gate = Completer<vm.VmService>();
      final inspector = VmInspector(connect: () => gate.future);
      final connecting = inspector.getVMService();
      final error = expectLater(connecting, throwsStateError);
      await Future<void>.delayed(.zero);
      final closing = inspector.disconnect();
      final connection = service();
      gate.complete(connection);
      await closing;
      await error;
      await connection.onDone;
    },
  );

  testWidgets(
    'inspector selection changes repaint without rebuilding its host',
    (tester) async {
      final selection = InspectorSelection();
      final target = GlobalKey();
      await tester.pumpWidget(
        testApp(
          Stack(
            children: [
              SizedBox(key: target, width: 40, height: 40),
              InspectorOverlay(selection: selection, needDescription: false),
            ],
          ),
        ),
      );
      final overlay = tester.renderObject<RenderBox>(
        find.byType(InspectorOverlay),
      );
      expect(overlay.debugNeedsPaint, isFalse);
      selection.current = target.currentContext!.findRenderObject();
      expect(overlay.debugNeedsPaint, isTrue);
      await tester.pump();
      selection.clear();
      expect(overlay.debugNeedsPaint, isTrue);
      await tester.pumpWidget(const SizedBox());
      selection.clear();
      expect(tester.takeException(), isNull);
      selection.dispose();
    },
  );

  for (final size in [const Size(20, 20), const Size(120, 60)]) {
    testWidgets('inspector tooltip fits a $size viewport', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final selection = InspectorSelection();
      final target = GlobalKey();
      await tester.pumpWidget(
        testApp(
          Stack(
            children: [
              SizedBox(key: target, width: 10, height: 10),
              InspectorOverlay(selection: selection),
            ],
          ),
        ),
      );
      selection.current = target.currentContext!.findRenderObject();
      tester.renderObject(find.byType(InspectorOverlay)).markNeedsPaint();
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      selection.dispose();
    });
  }

  testWidgets('inspector descriptions support slivers as well as boxes', (
    tester,
  ) async {
    final selection = InspectorSelection();
    final target = GlobalKey();
    await tester.pumpWidget(
      testApp(
        Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  key: target,
                  child: const SizedBox(height: 40),
                ),
              ],
            ),
            InspectorOverlay(selection: selection),
          ],
        ),
      ),
    );
    selection.current = target.currentContext!.findRenderObject();
    tester.renderObject(find.byType(InspectorOverlay)).markNeedsPaint();
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    selection.dispose();
  });

  testWidgets(
    'hit testing converts global coordinates for an embedded host boundary',
    (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        testApp(
          Padding(
            padding: const .only(left: 100, top: 80),
            child: RepaintBoundary(
              key: key,
              child: const SizedBox(
                width: 60,
                height: 60,
                child: ColoredBox(color: Color(0xFFFFFFFF)),
              ),
            ),
          ),
        ),
      );
      final root = find.byKey(key);
      final hits = HitTestUtils.hitTest(tester.getCenter(root), rootKey: key);
      expect(hits, isNotEmpty);
      expect(
        HitTestUtils.hitTest(const Offset(-100, -100), rootKey: key),
        isEmpty,
      );
    },
  );
}
