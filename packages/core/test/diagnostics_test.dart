import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vm_service/vm_service.dart' as vm;

import 'support/helpers.dart';

void main() {
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
