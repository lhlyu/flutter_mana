import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/widgets/dio_inspector_content.dart';
import 'package:flutter_mana_kits/src/plugins/mana_dio_inspector/widgets/response_detail.dart';
import 'package:flutter_mana_kits/src/plugins/mana_log_viewer/widgets/log_item_widget.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'support/host.dart';

void main() {
  testWidgets(
    'input padding focuses the field while text selection still works',
    (tester) async {
      final controller = TextEditingController(text: 'hello world');
      try {
        await tester.pumpWidget(
          testHost(
            Center(
              child: SizedBox(
                width: 300,
                child: KitField(controller: controller),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final field = find.byType(EditableText);
        final rect = tester.getRect(field);
        await tester.tapAt(Offset(rect.left - 5, rect.center.dy));
        await tester.pump();
        expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
        await tester.longPressAt(rect.topLeft + const Offset(15, 10));
        await tester.pumpAndSettle();
        expect(controller.selection.isCollapsed, isFalse);
        expect(
          controller.text.substring(
            controller.selection.start,
            controller.selection.end,
          ),
          'hello',
        );
        await tester.enterText(field, 'changed');
        expect(controller.text, 'changed');
      } finally {
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      }
    },
  );

  testWidgets(
    'network error summaries use two lines and details retain the full error',
    (tester) async {
      final collector = ManaDioCollector();
      final error = List.generate(
        30,
        (i) => 'Long error explanation $i',
      ).join('\n');
      collector.addResponse(
        Response(
          requestOptions: RequestOptions(path: 'https://example.test'),
          statusCode: 404,
          extra: {ManaDioCollector.errorKey: error},
        ),
      );
      try {
        await tester.pumpWidget(
          testHost(DioInspectorContent(collector: collector)),
        );
        await tester.pumpAndSettle();
        final summary = tester.widget<Text>(find.text(error));
        expect(summary.maxLines, 2);
        expect(summary.overflow, TextOverflow.ellipsis);
        await tester.tap(find.text('https://example.test'));
        await tester.pumpAndSettle();
        expect(find.byType(ResponseDetail), findsOneWidget);
        expect(tester.widget<Text>(find.text(error)).maxLines, isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        collector.dispose();
      }
    },
  );

  for (final language in ['en', 'zh']) {
    testWidgets('$language network and log views disclose truncated captures', (
      tester,
    ) async {
      final network = ManaDioCollector(maxEntryBytes: 1024);
      final logs = ManaLogCollector(maxEntryBytes: 1024);
      network.addResponse(
        Response(
          requestOptions: RequestOptions(path: '/'),
          data: 'x' * 10000,
        ),
      );
      logs.output(OutputEvent(LogEvent(Level.info, 'x' * 10000), []));
      final notice = language == 'zh' ? '内容已截断。' : 'Content truncated.';
      Widget localized(Widget child) => testHost(
        Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: Locale(language),
            child: child,
          ),
        ),
      );
      try {
        await tester.pumpWidget(
          localized(
            ResponseDetail(response: network.data.single, onClose: () {}),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(notice), findsOneWidget);
        await tester.pumpWidget(
          localized(
            SingleChildScrollView(
              child: LogItemWidget(verboseLogs: false, log: logs.data.single),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(notice), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        network.dispose();
        logs.dispose();
      }
    });
  }
}
