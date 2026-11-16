import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana_kits/src/ui/kit_selection.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/host.dart';

Finder get handles => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_SelectionHandleOverlay',
  ),
  matching: find.byType(DecoratedBox),
);

Offset textPosition(RenderParagraph paragraph, int offset) =>
    paragraph.localToGlobal(
      paragraph.getOffsetForCaret(TextPosition(offset: offset), Rect.zero) +
          Offset(0, paragraph.preferredLineHeight / 2),
    );

void main() {
  for (final type in TextSelectionHandleType.values) {
    testWidgets('$type handle keeps its advertised size in a loose overlay', (
      tester,
    ) async {
      var taps = 0;
      const key = ValueKey('handle');
      await tester.pumpWidget(
        testHost(
          Center(
            child: Builder(
              builder: (context) => KeyedSubtree(
                key: key,
                child: kitSelectionControls.buildHandle(
                  context,
                  type,
                  20,
                  () => taps++,
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(key)),
        kitSelectionControls.getHandleSize(20),
      );
      expect(kitSelectionControls.getHandleAnchor(type, 20), switch (type) {
        .left => const Offset(33, 15),
        .right => const Offset(15, 15),
        .collapsed => const Offset(24, 15),
      });
      expect(kitSelectionControls.getHandleSize(20), const Size(48, 48));
      await tester.tap(find.byKey(key));
      await tester.tapAt(tester.getTopLeft(find.byKey(key)) + const Offset(2, 2));
      expect(taps, 2);
    });
  }

  testWidgets(
    'touch selection handles can adjust and copy a code snippet',
    (tester) async {
      const text = 'alpha bravo charlie delta echo';
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        testHost(
          const Center(child: SizedBox(width: 600, child: KitCode(text))),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      );
      await tester.longPressAt(textPosition(paragraph, 8));
      await tester.pumpAndSettle();
      expect(
        paragraph.selections.single,
        const TextSelection(baseOffset: 6, extentOffset: 11),
      );
      expect(handles, findsNWidgets(2));
      for (var index = 0; index < 2; index++) {
        expect(tester.getSize(handles.at(index)), const Size(18, 18));
      }

      Future<void> dragHandle(Finder handle, double dx) async {
        final gesture = await tester.startGesture(
          // Grab the padded touch target, not just the small painted handle.
          tester.getCenter(handle) + const Offset(0, 20),
          kind: PointerDeviceKind.touch,
        );
        await gesture.moveBy(Offset(dx, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
      }

      await dragHandle(
        handles.last,
        textPosition(paragraph, 19).dx - textPosition(paragraph, 11).dx,
      );
      expect(
        paragraph.selections.single,
        const TextSelection(baseOffset: 6, extentOffset: 19),
      );
      await dragHandle(
        handles.first,
        textPosition(paragraph, 0).dx - textPosition(paragraph, 6).dx,
      );
      expect(
        paragraph.selections.single,
        const TextSelection(baseOffset: 0, extentOffset: 19),
      );
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(clipboard, 'alpha bravo charlie');
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'desktop mouse dragging still selects text in a data table',
    (tester) async {
      const text = 'alpha bravo charlie delta echo';
      await tester.pumpWidget(
        testHost(
          const Center(
            child: SizedBox(width: 600, child: KitDataTable({'Message': text})),
          ),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      );
      final mouse = await tester.startGesture(
        textPosition(paragraph, 6),
        kind: PointerDeviceKind.mouse,
      );
      await mouse.moveTo(textPosition(paragraph, 19));
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();
      expect(
        paragraph.selections.single,
        const TextSelection(baseOffset: 6, extentOffset: 19),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
