// Run with: flutter test --enable-vmservice \
//   packages/kits/test/fixtures/source_lookup_smoke.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_mana_kits/src/plugins/mana_show_code/utils/code_display_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

class _ActualPage extends StatelessWidget {
  const _ActualPage();
  @override
  Widget build(BuildContext context) => const Text('Current page');
}

void main() {
  testWidgets('real VM resolves the current page definition', (tester) async {
    final root = GlobalKey();
    await tester.pumpWidget(
      KeyedSubtree(key: root, child: testHost(const _ActualPage())),
    );
    final service = CodeDisplayService();
    try {
      final page = await tester.runAsync(
        () => service.currentPage(root.currentContext),
      );
      expect(page?.widgetName, '_ActualPage');
      expect(page?.uri, contains('source_lookup_smoke.dart'));
      expect(
        page?.source,
        contains('class _ActualPage extends StatelessWidget'),
      );
    } finally {
      await tester.runAsync(service.close);
    }
  });
}
