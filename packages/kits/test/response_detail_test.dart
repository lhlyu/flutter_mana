import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/request_format.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/widgets/response_detail.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/host.dart';

Finder get copyMenu => find.byWidgetPredicate(
  (widget) => widget is ManaButton && widget.tooltip == 'Copy',
);

Finder copyAction(String label) => find.byWidgetPredicate(
  (widget) => widget is KitButton && widget.label == 'Copy $label',
);

void main() {
  late Response<Object?> response;
  String? clipboard;

  setUp(() {
    response = Response<Object?>(
      requestOptions: RequestOptions(
        path: 'https://example.test/items',
        method: 'POST',
        headers: {'X-Test': 'example'},
        data: {'name': 'test'},
      ),
      statusCode: 200,
      data: {'id': 42},
    );
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget detail({double width = 360, double scale = 1}) => testHost(
    Center(
      child: SizedBox(
        width: width,
        height: 400,
        child: ResponseDetail(response: response, onClose: () {}),
      ),
    ),
    scale: scale,
  );

  testWidgets('exports are grouped in the header instead of a footer', (
    tester,
  ) async {
    await tester.pumpWidget(detail());
    expect(copyMenu, findsOneWidget);
    expect(find.byType(KitToolbar), findsNothing);
    expect(copyAction('URL'), findsNothing);
    expect(
      tester.getCenter(copyMenu).dy,
      lessThan(tester.getTopLeft(find.byType(KitTabs<int>)).dy),
    );

    for (final (label, expected) in [
      ('URL', response.requestOptions.uri.toString()),
      ('cURL', formatCurl(response.requestOptions)),
      ('HTTP', formatHttp(response.requestOptions)),
      ('Response', formatBody(response.data)),
    ]) {
      await tester.tap(copyMenu);
      await tester.pumpAndSettle();
      expect(copyAction(label), findsOneWidget);
      await tester.tap(copyAction(label));
      await tester.pumpAndSettle();
      expect(clipboard, expected);
      expect(copyAction(label), findsNothing);
    }

    await tester.tap(find.text('Response'));
    await tester.pumpAndSettle();
    await tester.tap(copyMenu);
    await tester.pumpAndSettle();
    expect(copyAction('HTTP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard navigation, escape and outside taps dismiss the menu', (
    tester,
  ) async {
    await tester.pumpWidget(detail());
    await tester.tap(copyMenu);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(clipboard, formatCurl(response.requestOptions));
    expect(copyAction('URL'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(copyAction('URL'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(copyAction('URL'), findsNothing);

    await tester.tap(copyMenu);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(copyAction('URL'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unsupported cURL stays recoverable without closing the detail', (
    tester,
  ) async {
    response.requestOptions.data = Uint8List.fromList([1, 2, 3]);
    await tester.pumpWidget(detail());
    await tester.tap(copyMenu);
    await tester.pumpAndSettle();
    await tester.tap(copyAction('cURL'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cURL unavailable'), findsOneWidget);
    expect(clipboard, isNull);
    await tester.tap(copyAction('URL'));
    await tester.pumpAndSettle();
    expect(clipboard, response.requestOptions.uri.toString());
    expect(copyAction('URL'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact header works in narrow layouts with large text', (
    tester,
  ) async {
    for (final width in [96.0, 180.0, 360.0]) {
      await tester.pumpWidget(detail(width: width, scale: 3));
      await tester.tap(copyMenu);
      await tester.pumpAndSettle();
      await tester.ensureVisible(copyAction('HTTP'));
      await tester.tap(copyAction('HTTP'));
      await tester.pumpAndSettle();
      expect(clipboard, formatHttp(response.requestOptions));
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });
}
