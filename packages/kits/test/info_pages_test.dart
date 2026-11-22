import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana_kits/src/plugins/mana_device_info/widgets/device_info_content.dart';
import 'package:flutter_mana_kits/src/plugins/mana_package_info/widgets/package_info_content.dart';
import 'package:flutter_mana_kits/src/plugins/mana_screen_info/widgets/screen_info_content.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/host.dart';

const device = <String, Object?>{
  'name': 'Development iPhone',
  'modelName': 'iPhone 17',
  'model': 'iPhone',
  'systemName': 'iOS',
  'systemVersion': '27.2',
  'isPhysicalDevice': false,
  'physicalRamSize': 8192,
  'availableRamSize': 900,
  'totalDiskSize': 274877906944,
  'freeDiskSize': 68719476736,
  'identifierForVendor': 'AE08058C-3570-4ED3-8CD8-2871FC599AEE',
  'utsname': {
    'machine': 'iPhone18,3',
    'version':
        'Darwin Kernel Version with a long unbroken identifier: ARM64_T6050',
  },
  'futurePlatformField': ['one', 'two'],
};

final package = PackageInfo(
  appName: 'Mana Example / 调试示例',
  packageName: 'com.example.a.very.long.application.identifier',
  version: '2.0.0',
  buildNumber: '123',
  buildSignature: 'a' * 128,
  installerStore: '',
  installTime: DateTime(2026, 11, 15, 10, 15, 51, 458),
);

const screen = MediaQueryData(
  size: Size(360, 780),
  devicePixelRatio: 3,
  padding: EdgeInsets.only(top: 24),
  viewPadding: EdgeInsets.only(top: 24, bottom: 34),
  viewInsets: EdgeInsets.only(bottom: 300),
  textScaler: TextScaler.linear(1.15),
);

Finder button(String label) => find.byWidgetPredicate(
  (widget) => widget is KitButton && widget.label == label,
);

void main() {
  for (final (size, scale, language) in [
    (const Size(320, 568), 1.0, 'zh'),
    (const Size(240, 320), 2.0, 'zh'),
    (const Size(160, 200), 3.0, 'en'),
    (const Size(640, 160), 1.5, 'en'),
    (const Size(800, 600), 1.0, 'en'),
  ]) {
    testWidgets('info pages fit $size / $scale / $language with real data', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = [Locale(language)];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      for (final child in [
        const DeviceInfoContent(data: device),
        PackageInfoContent(info: package),
        const ScreenInfoContent(data: screen),
      ]) {
        await tester.pumpWidget(
          testHost(
            Builder(
              builder: (context) => Localizations.override(
                context: context,
                locale: Locale(language),
                child: Center(
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: child,
                  ),
                ),
              ),
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${child.runtimeType}');
        if (child is DeviceInfoContent) {
          final details = find.text(
            language == 'zh' ? '平台详情' : 'Platform details',
          );
          await tester.ensureVisible(details);
          final visible = tester
              .getRect(details)
              .intersect(tester.getRect(find.byType(DeviceInfoContent)));
          expect(visible.isEmpty, isFalse);
          await tester.tapAt(visible.center);
          await tester.pumpAndSettle();
          expect(find.text('utsname.machine'), findsOneWidget);
        }
        final copyAll = button(language == 'zh' ? '复制全部数据' : 'Copy all data');
        await tester.ensureVisible(copyAll);
        await tester.pumpAndSettle();
        expect(copyAll.hitTestable(), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: '${child.runtimeType} scrolled',
        );
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  testWidgets(
    'platform details expand and retain unknown nested fields on resize',
    (tester) async {
      Widget page(double width) => testHost(
        Center(
          child: SizedBox(
            width: width,
            height: 500,
            child: const DeviceInfoContent(data: device),
          ),
        ),
      );
      await tester.pumpWidget(page(320));
      expect(find.text('utsname.machine'), findsNothing);
      final expand = find.text('Platform details');
      await tester.ensureVisible(expand);
      await tester.tap(expand);
      await tester.pumpAndSettle();
      expect(find.text('utsname.machine'), findsOneWidget);
      expect(find.text('iPhone18,3'), findsOneWidget);
      expect(find.text('futurePlatformField'), findsOneWidget);
      expect(find.text('one\ntwo'), findsOneWidget);
      await tester.pumpWidget(page(180));
      await tester.pumpAndSettle();
      expect(find.text('iPhone18,3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('copy keeps original units and raw nested data with feedback', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
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
    await tester.pumpWidget(testHost(const DeviceInfoContent(data: device)));
    expect(find.text('8 GB'), findsOneWidget);
    expect(find.text('900 MB'), findsOneWidget);
    final copy = button('Copy all data');
    await tester.ensureVisible(copy);
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(jsonDecode(copied!), device);
    expect(button('Copied'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'package dates omit milliseconds and empty fields have placeholders',
    (tester) async {
      await tester.pumpWidget(testHost(PackageInfoContent(info: package)));
      expect(find.text('2.0.0 (123)'), findsOneWidget);
      expect(find.text('2026-11-15 10:15:51'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'screen values reflect source media and update with keyboard insets',
    (tester) async {
      await tester.pumpWidget(testHost(const ScreenInfoContent(data: screen)));
      expect(find.text('360 × 780'), findsOneWidget);
      expect(find.text('1080 × 2340 px'), findsOneWidget);
      expect(find.text('14 → 16.1 logical px'), findsOneWidget);
      final obstruction = find.descendant(
        of: find.byType(Table),
        matching: find.text('300'),
      );
      expect(obstruction, findsOneWidget);
      await tester.pumpWidget(
        testHost(
          ScreenInfoContent(data: screen.copyWith(viewInsets: EdgeInsets.zero)),
        ),
      );
      await tester.pumpAndSettle();
      expect(obstruction, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('device memory fields use their documented units', () {
    expect(formatDeviceField('physicalRamSize', 8192), '8 GB');
    expect(formatDeviceField('memorySize', 8589934592), '8 GB');
    expect(formatDeviceField('systemMemoryInMegabytes', 8192), '8 GB');
    expect(formatDeviceField('freeDiskSize', 0), '0 B');
    expect(formatDeviceField('physicalRamSize', -1), isNull);
    expect(formatDeviceField('numberOfCores', 8), 8);
  });
}
