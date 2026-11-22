import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_mana_kits/src/ui/kit_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/host.dart';

void main() {
  Widget host(Future<String> Function() load) => testHost(
    KitAsync<String>(load: load, builder: (_, value) => Text(value)),
  );

  testWidgets('changing the loader replaces the cached result', (tester) async {
    var firstCalls = 0;
    var secondCalls = 0;
    Future<String> first() async {
      firstCalls++;
      return 'first';
    }

    Future<String> second() async {
      secondCalls++;
      return 'second';
    }

    await tester.pumpWidget(host(first));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsOneWidget);
    await tester.pumpWidget(host(first));
    await tester.pumpAndSettle();
    expect(firstCalls, 1);
    await tester.pumpWidget(host(second));
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);
    expect(find.text('first'), findsNothing);
    expect(secondCalls, 1);
  });

  testWidgets('inline loaders reuse results until their load key changes', (
    tester,
  ) async {
    var calls = 0;
    Widget keyedHost(int source) => testHost(
      KitAsync<String>(
        loadKey: source,
        load: () async {
          calls++;
          return 'source $source';
        },
        builder: (_, value) => Text(value),
      ),
    );
    await tester.pumpWidget(keyedHost(1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(keyedHost(1));
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.pumpWidget(keyedHost(2));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('source 2'), findsOneWidget);
  });

  testWidgets('late results from a replaced loader are ignored', (
    tester,
  ) async {
    final first = Completer<String>();
    final second = Completer<String>();
    await tester.pumpWidget(host(() => first.future));
    await tester.pumpWidget(host(() => second.future));
    second.complete('current');
    await tester.pumpAndSettle();
    first.complete('stale');
    await tester.pumpAndSettle();
    expect(find.text('current'), findsOneWidget);
    expect(find.text('stale'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
