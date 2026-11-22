import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/host.dart';

Finder choice(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(ManaButton));

Widget frame(Widget child, {double width = 360}) => Align(
  alignment: .topCenter,
  child: SizedBox(width: width, child: child),
);

void main() {
  testWidgets('choice menus close when their page becomes inactive', (
    tester,
  ) async {
    var active = true;
    late StateSetter rebuild;
    await tester.pumpWidget(
      testHost(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return TickerMode(
              enabled: active,
              child: frame(
                KitChoiceField(
                  fieldLabel: 'Type',
                  values: const ['one', 'two', 'three'],
                  value: 'one',
                  onChanged: (_) {},
                ),
                width: 160,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(choice('one'));
    await tester.pumpAndSettle();
    expect(choice('two').hitTestable(), findsOneWidget);
    rebuild(() => active = false);
    await tester.pumpAndSettle();
    expect(choice('two'), findsNothing);
    rebuild(() => active = true);
    await tester.pumpAndSettle();
    expect(choice('two'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'tabs share one compact iOS-style rail and navigation semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var value = 'Detail';
      var changes = 0;
      await tester.pumpWidget(
        testHost(
          frame(
            StatefulBuilder(
              builder: (context, setState) => KitTabs(
                values: const ['Detail', 'Request', 'Response'],
                value: value,
                onChanged: (next) => setState(() {
                  value = next;
                  changes++;
                }),
              ),
            ),
            width: 480,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['Detail', 'Request', 'Response']) {
        expect(
          tester.getSize(choice(label)).width,
          closeTo((480 - 20) / 3, .01),
        );
        expect(tester.getSize(choice(label)).height, 28);
      }
      expect(tester.getSize(find.byType(KitTabs<String>)).height, 40);
      final rail = find.byKey(const ValueKey('kit-tabs-rail'));
      expect(tester.getSize(rail).height, 32);
      expect(
        (tester.widget<DecoratedBox>(rail).decoration as BoxDecoration)
            .borderRadius,
        BorderRadius.circular(7),
      );
      final indicator = find.byKey(const ValueKey('kit-tabs-indicator'));
      expect(tester.getSize(indicator).height, 28);
      expect(
        tester.getSize(indicator).width,
        closeTo(tester.getSize(choice('Detail')).width, .01),
      );
      expect(tester.getCenter(indicator), tester.getCenter(choice('Detail')));
      expect(
        tester.getSemantics(choice('Detail')),
        matchesSemantics(
          label: 'Detail',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(choice('Detail'));
      await tester.pumpAndSettle();
      expect(changes, 0);
      await tester.tap(choice('Request'));
      await tester.pumpAndSettle();
      expect(value, 'Request');
      expect(changes, 1);
      expect(find.byType(KitButton), findsNothing);
      expect(find.text('Working…'), findsNothing);
      final selectedText = tester.widget<Text>(find.text('Request'));
      expect(selectedText.style?.color, KitStyle.text);
      expect(selectedText.style?.fontSize, 12);
      expect(selectedText.style?.fontWeight, FontWeight.w600);
      semantics.dispose();
    },
  );

  for (final direction in TextDirection.values) {
    testWidgets('one rectangular thumb slides between segments in $direction', (
      tester,
    ) async {
      var value = 'One';
      await tester.pumpWidget(
        testHost(
          frame(
            StatefulBuilder(
              builder: (context, setState) => KitTabs(
                values: const ['One', 'Other', 'Final'],
                value: value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      final indicator = find.byKey(const ValueKey('kit-tabs-indicator'));
      expect(indicator, findsOneWidget);
      final start = tester.getCenter(indicator).dx;
      final target = tester.getCenter(find.text('Final')).dx;
      await tester.tap(choice('Final'));
      await tester.pump();
      expect(tester.getCenter(indicator).dx, closeTo(start, .01));
      await tester.pump(const Duration(milliseconds: 90));
      final progress =
          (tester.getCenter(indicator).dx - start) / (target - start);
      expect(progress, greaterThan(0));
      expect(progress, lessThan(1));
      await tester.pumpAndSettle();
      expect(tester.getCenter(indicator).dx, closeTo(target, .01));
      expect(
        tester.getSize(indicator).width,
        closeTo(tester.getSize(choice('Final')).width, .01),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('selection and resizing reveal only the strip in $direction', (
      tester,
    ) async {
      var value = 0;
      var width = 220.0;
      late StateSetter rebuild;
      final outer = ScrollController();
      addTearDown(outer.dispose);
      await tester.pumpWidget(
        testHost(
          frame(
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                controller: outer,
                child: Column(
                  children: [
                    const SizedBox(height: 400),
                    StatefulBuilder(
                      builder: (context, setState) {
                        rebuild = setState;
                        return SizedBox(
                          width: width,
                          child: KitTabs(
                            values: List.generate(8, (i) => i),
                            value: value,
                            label: (i) => 'Long tab $i',
                            onChanged: (next) => setState(() => value = next),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          direction: direction,
          scale: 1.5,
        ),
      );
      await tester.pumpAndSettle();
      rebuild(() => value = 7);
      await tester.pumpAndSettle();
      final viewport = find.byType(KitTabs<int>);
      expect(
        tester
            .getRect(viewport)
            .contains(tester.getCenter(choice('Long tab 7'))),
        isTrue,
      );
      expect(
        outer.offset,
        0,
        reason: 'Selection must not scroll the enclosing header.',
      );
      rebuild(() => width = 120);
      await tester.pumpAndSettle();
      // A label may be wider than a tiny viewport, but must still intersect it.
      expect(
        tester.getRect(viewport).overlaps(tester.getRect(choice('Long tab 7'))),
        isTrue,
      );
      expect(outer.offset, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('arrow keys select tabs in visual order in $direction', (
      tester,
    ) async {
      var value = 1;
      await tester.pumpWidget(
        testHost(
          frame(
            StatefulBuilder(
              builder: (context, setState) => KitTabs(
                values: const [0, 1, 2],
                value: value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      tester.widget<ManaButton>(choice('1')).focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(value, direction == .ltr ? 2 : 0);
      expect(
        tester.widget<ManaButton>(choice('$value')).focusNode!.hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(value, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(value, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tabs respect reduced-motion settings', (tester) async {
    var value = 0;
    await tester.pumpWidget(
      testHost(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: frame(
              StatefulBuilder(
                builder: (context, setState) => KitTabs(
                  values: const [0, 1, 2],
                  value: value,
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedPositionedDirectional>(
            find.byType(AnimatedPositionedDirectional),
          )
          .duration,
      Duration.zero,
    );
    await tester.tap(choice('2'));
    await tester.pump();
    expect(
      tester.getCenter(find.byKey(const ValueKey('kit-tabs-indicator'))).dx,
      closeTo(tester.getCenter(find.text('2')).dx, .01),
    );
  });

  testWidgets('filter tabs support nullable All and retain manual scrolling', (
    tester,
  ) async {
    String? value;
    late StateSetter rebuild;
    await tester.pumpWidget(
      testHost(
        frame(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return KitTabs<String?>(
                values: const [
                  null,
                  'TRACE',
                  'DEBUG',
                  'INFO',
                  'WARNING',
                  'ERROR',
                  'FATAL',
                ],
                value: value,
                label: (value) => value ?? 'All',
                onChanged: (next) => setState(() => value = next),
              );
            },
          ),
          width: 220,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(choice('DEBUG'));
    await tester.tap(choice('DEBUG'));
    await tester.pumpAndSettle();
    expect(value, 'DEBUG');
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final offset = scroll.position.pixels;
    rebuild(() {});
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, offset);
    rebuild(() => value = null);
    await tester.pumpAndSettle();
    expect(choice('All').hitTestable(), findsOneWidget);
    expect(tester.getSize(choice('All')).height, 28);
    expect(find.byKey(const ValueKey('kit-tabs-indicator')), findsOneWidget);
    for (final button in tester.widgetList<ManaButton>(
      find.byType(ManaButton),
    )) {
      expect(
        button.decoration?.color,
        isNull,
        reason: 'No individual pill backgrounds.',
      );
      expect(
        button.decoration?.border,
        isNull,
        reason: 'No individual pill outlines.',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'choice field adapts from segments to a dismissible selection menu',
    (tester) async {
      var width = 600.0;
      var value = 'String';
      late StateSetter rebuild;
      await tester.pumpWidget(
        testHost(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return frame(
                KitChoiceField(
                  fieldLabel: 'Type',
                  values: const ['String', 'int', 'double', 'bool', 'List'],
                  value: value,
                  onChanged: (next) => setState(() => value = next),
                ),
                width: width,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RawMenuAnchor), findsNothing);
      await tester.tap(choice('int'));
      await tester.pumpAndSettle();
      expect(value, 'int');
      rebuild(() => width = 180);
      await tester.pumpAndSettle();
      expect(find.byType(RawMenuAnchor), findsOneWidget);
      expect(choice('double'), findsNothing);
      await tester.tap(choice('int'));
      await tester.pumpAndSettle();
      expect(choice('double').hitTestable(), findsOneWidget);
      await tester.tap(choice('double'));
      await tester.pumpAndSettle();
      expect(value, 'double');
      expect(choice('String'), findsNothing);
      await tester.tap(choice('double'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(choice('String'), findsNothing);
      await tester.tap(choice('double'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 580));
      await tester.pumpAndSettle();
      expect(choice('String'), findsNothing);
      expect(value, 'double');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'menu keyboard focus starts at the selected value and returns to the field',
    (tester) async {
      var value = 'two';
      await tester.pumpWidget(
        testHost(
          frame(
            StatefulBuilder(
              builder: (context, setState) => KitChoiceField(
                fieldLabel: 'Type',
                values: const ['one', 'two', 'three'],
                value: value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
            width: 160,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final anchor = tester.widget<ManaButton>(choice('two')).focusNode!;
      anchor.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final menuOption = find
          .descendant(of: find.byType(TapRegion), matching: choice('two'))
          .last;
      expect(tester.widget<ManaButton>(menuOption).focusNode!.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(value, 'three');
      expect(anchor.hasFocus, isTrue);
      expect(choice('one'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(value, 'three');
      expect(anchor.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'open menus tolerate short RTL viewports, large text and resizing',
    (tester) async {
      tester.view.physicalSize = const Size(180, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        testHost(
          frame(
            KitChoiceField(
              fieldLabel: '数据类型',
              values: const ['String', 'int', 'double', 'bool', 'List<String>'],
              value: 'List<String>',
              onChanged: (_) {},
            ),
          ),
          direction: .rtl,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(choice('List<String>'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final menuItem = choice('List<String>').last;
      expect(menuItem.hitTestable(), findsOneWidget);
      tester.view.physicalSize = const Size(640, 360);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty groups and changing values dispose focus safely', (
    tester,
  ) async {
    var values = [0, 1, 2];
    var value = 1;
    late StateSetter rebuild;
    await tester.pumpWidget(
      testHost(
        frame(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return KitTabs(values: values, value: value, onChanged: (_) {});
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.widget<ManaButton>(choice('1')).focusNode!.requestFocus();
    await tester.pump();
    rebuild(() {
      values = [2, 0];
      value = 2;
    });
    await tester.pumpAndSettle();
    expect(choice('1'), findsNothing);
    rebuild(() => values = []);
    await tester.pumpAndSettle();
    expect(find.byType(ManaButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
