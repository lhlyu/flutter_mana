import 'package:flutter/widgets.dart';
import 'package:flutter_mana_kits/src/plugins/mana_color_sucker/widgets/color_sucker_content.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/host.dart';

void main() {
  testWidgets('only offers the hexadecimal color and keeps magnification', (
    tester,
  ) async {
    double? magnification;
    await tester.pumpWidget(
      testHost(
        ColorSuckerContent(
          color: const Color(0x80123456),
          magnification: 8,
          onMagnificationChanged: (value) => magnification = value,
        ),
      ),
    );

    expect(find.text('#80123456'), findsOneWidget);
    expect(find.textContaining('rgba('), findsNothing);
    expect(find.byType(KitCopyButton), findsOneWidget);
    expect(
      tester.widget<KitCopyButton>(find.byType(KitCopyButton)).text,
      '#80123456',
    );
    final slider = tester.widget<ManaSlider>(find.byType(ManaSlider));
    expect(slider.value, 8);
    slider.onChanged(10);
    expect(magnification, 10);
  });
}
