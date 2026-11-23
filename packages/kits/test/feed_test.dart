import 'package:flutter/widgets.dart';
import 'package:flutter_mana_kits/src/data/bounded_collector.dart';
import 'package:flutter_mana_kits/src/ui/kit_feed.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/host.dart';

class _Entry {
  const _Entry(this.text, {this.category = 'INFO'});
  final String text;
  final String category;
}

class _FeedHarness {
  _FeedHarness({int capacity = 1000})
    : collector = BoundedCollector<_Entry>(capacity: capacity);

  final BoundedCollector<_Entry> collector;
  final searched = <_Entry>[];
  final categorized = <_Entry>[];

  String searchText(_Entry entry) {
    searched.add(entry);
    return entry.text;
  }

  String categoryOf(_Entry entry) {
    categorized.add(entry);
    return entry.category;
  }

  Widget build({
    bool enabled = true,
    BoundedCollector<_Entry>? source,
    String Function(_Entry)? search,
    String Function(_Entry)? category,
  }) => testHost(
    TickerMode(
      enabled: enabled,
      child: KitFeed<_Entry>(
        collector: source ?? collector,
        categories: const ['INFO', 'ERROR'],
        categoryOf: category ?? categoryOf,
        searchText: search ?? searchText,
        itemBuilder: (_, entry) => Text(entry.text),
      ),
    ),
  );
}

Finder _button(String label) => find.byWidgetPredicate(
  (widget) => widget is KitButton && widget.label == label,
);

Future<void> _search(WidgetTester tester, String query) async {
  await tester.tap(_button('Search'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(EditableText), query);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search only formats new retained records for a stable query', (
    tester,
  ) async {
    final harness = _FeedHarness();
    addTearDown(harness.collector.dispose);
    const first = _Entry('needle first');
    const second = _Entry('unrelated');
    const third = _Entry('NEEDLE next');
    harness.collector
      ..add(first)
      ..add(second);
    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();
    expect(harness.searched, isEmpty);

    await _search(tester, ' needle ');
    expect(harness.searched, [first, second]);
    expect(find.text(first.text), findsOneWidget);
    expect(find.text(second.text), findsNothing);

    harness.collector.add(third);
    await tester.pumpAndSettle();
    expect(harness.searched, [first, second, third]);
    expect(find.text(third.text), findsOneWidget);

    await tester.tap(_button('Lock auto-scroll'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();
    expect(harness.searched, [first, second, third]);
    expect(harness.categorized, isEmpty);
  });

  testWidgets('a full collector searches only the new record after eviction', (
    tester,
  ) async {
    final harness = _FeedHarness();
    addTearDown(harness.collector.dispose);
    for (var i = 0; i < 1000; i++) {
      harness.collector.add(_Entry('archived $i'));
    }
    await tester.pumpWidget(harness.build());
    await _search(tester, 'needle');
    expect(harness.searched, hasLength(1000));

    const next = _Entry('needle latest');
    harness.collector.add(next);
    await tester.pumpAndSettle();
    expect(harness.collector.length, 1000);
    expect(harness.searched, hasLength(1001));
    expect(harness.searched.last, same(next));
    expect(find.text(next.text), findsOneWidget);
  });

  testWidgets('query changes and search toggles invalidate previous matches', (
    tester,
  ) async {
    final harness = _FeedHarness();
    addTearDown(harness.collector.dispose);
    const first = _Entry('first message');
    const second = _Entry('second message');
    harness.collector
      ..add(first)
      ..add(second);
    await tester.pumpWidget(harness.build());
    await _search(tester, 'first');
    expect(find.text(first.text), findsOneWidget);
    expect(find.text(second.text), findsNothing);

    await tester.enterText(find.byType(EditableText), 'second');
    await tester.pumpAndSettle();
    expect(harness.searched, [first, second, first, second]);
    expect(find.text(first.text), findsNothing);
    expect(find.text(second.text), findsOneWidget);

    await tester.tap(_button('Search'));
    await tester.pumpAndSettle();
    expect(find.text(first.text), findsOneWidget);
    expect(find.text(second.text), findsOneWidget);
    await tester.tap(_button('Search'));
    await tester.pumpAndSettle();
    expect(find.text(first.text), findsNothing);
    expect(harness.searched, [first, second, first, second, first, second]);
  });

  testWidgets('category matches are cached and reset when the tab changes', (
    tester,
  ) async {
    final harness = _FeedHarness();
    addTearDown(harness.collector.dispose);
    const info = _Entry('info record');
    const error = _Entry('error record', category: 'ERROR');
    const next = _Entry('next info record');
    harness.collector
      ..add(info)
      ..add(error);
    await tester.pumpWidget(harness.build());
    await tester.tap(find.text('INFO'));
    await tester.pumpAndSettle();
    expect(harness.categorized, [info, error]);
    expect(find.text(error.text), findsNothing);

    harness.collector.add(next);
    await tester.pumpAndSettle();
    expect(harness.categorized, [info, error, next]);
    expect(harness.searched, isEmpty);
    await tester.tap(find.text('ERROR'));
    await tester.pumpAndSettle();
    expect(harness.categorized, [info, error, next, info, error, next]);
    expect(find.text(error.text), findsOneWidget);
    expect(find.text(next.text), findsNothing);
  });

  testWidgets('eviction and clear remove obsolete cached search records', (
    tester,
  ) async {
    final harness = _FeedHarness(capacity: 2);
    addTearDown(harness.collector.dispose);
    const first = _Entry('message first');
    const second = _Entry('message second');
    const third = _Entry('message third');
    harness.collector
      ..add(first)
      ..add(second);
    await tester.pumpWidget(harness.build());
    await _search(tester, 'message');

    harness.collector.add(third);
    await tester.pumpAndSettle();
    expect(harness.searched, [first, second, third]);
    expect(find.text(first.text), findsNothing);
    harness.collector.add(first);
    await tester.pumpAndSettle();
    expect(harness.searched, [first, second, third, first]);
    expect(find.text(second.text), findsNothing);

    harness.collector.clear();
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsNothing);
    harness.collector.add(first);
    await tester.pumpAndSettle();
    expect(harness.searched, [first, second, third, first, first]);
    expect(find.text(first.text), findsOneWidget);
  });

  testWidgets('replacing the collector or search callback resets matches', (
    tester,
  ) async {
    final harness = _FeedHarness();
    final replacement = BoundedCollector<_Entry>();
    addTearDown(harness.collector.dispose);
    addTearDown(replacement.dispose);
    const entry = _Entry('original message');
    harness.collector.add(entry);
    replacement.add(entry);
    await tester.pumpWidget(harness.build());
    await _search(tester, 'original');
    expect(harness.searched, [entry]);

    await tester.pumpWidget(harness.build(source: replacement));
    await tester.pumpAndSettle();
    expect(harness.searched, [entry, entry]);
    expect(find.text(entry.text), findsOneWidget);

    await tester.pumpWidget(
      harness.build(source: replacement, search: (_) => 'changed'),
    );
    await tester.pumpAndSettle();
    expect(find.text(entry.text), findsNothing);
  });

  testWidgets('replacing the category callback invalidates cached matches', (
    tester,
  ) async {
    final harness = _FeedHarness();
    addTearDown(harness.collector.dispose);
    const entry = _Entry('message');
    harness.collector.add(entry);
    await tester.pumpWidget(harness.build());
    await tester.tap(find.text('INFO'));
    await tester.pumpAndSettle();
    expect(find.text(entry.text), findsOneWidget);

    await tester.pumpWidget(harness.build(category: (_) => 'ERROR'));
    await tester.pumpAndSettle();
    expect(find.text(entry.text), findsNothing);
  });

  testWidgets('hidden feeds defer search work and catch up when restored', (
    tester,
  ) async {
    final harness = _FeedHarness();
    addTearDown(harness.collector.dispose);
    const first = _Entry('message first');
    const second = _Entry('message second');
    harness.collector.add(first);
    await tester.pumpWidget(harness.build());
    await _search(tester, 'message');
    await tester.pumpWidget(harness.build(enabled: false));
    await tester.pumpAndSettle();

    harness.collector.add(second);
    await tester.pumpAndSettle();
    expect(harness.searched, [first]);
    expect(find.text(second.text), findsNothing);

    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();
    expect(harness.searched, [first, second]);
    expect(find.text(second.text), findsOneWidget);
  });
}
