import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:flutter_mana_kits/src/icons/plugin_icons.dart';
import 'package:flutter_mana_kits/src/plugins/builtin_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every built-in kit has a distinct vector icon', () async {
    final plugins = [...loadAllPlugins(), Demo()];
    final icons = plugins
        .cast<BuiltinKit>()
        .map((plugin) => plugin.icon)
        .toSet();
    expect(icons, PluginIcon.values.toSet());
    expect(icons.map((icon) => icon.svg).toSet(), hasLength(17));
    for (final plugin in plugins) {
      await Future<void>.sync(plugin.dispose);
    }
  });

  for (final icon in PluginIcon.values) {
    test(
      '${icon.name} renders at small and high-density resolutions',
      () async {
        for (final (size, scale) in [(32.0, 1.0), (96.0, 3.0)]) {
          final provider = PluginIconImage(icon);
          final stream = provider.resolve(
            ImageConfiguration(
              size: Size.square(size),
              devicePixelRatio: scale,
            ),
          );
          final loaded = Completer<ImageInfo>();
          final listener = ImageStreamListener(
            (image, _) => loaded.complete(image),
            onError: loaded.completeError,
          );
          stream.addListener(listener);
          final info = await loaded.future;
          try {
            expect(info.image.width, (size * scale).ceil());
            expect(info.image.height, (size * scale).ceil());
            expect(info.scale, scale);
            final pixels = await info.image.toByteData(
              format: ui.ImageByteFormat.rawStraightRgba,
            );
            expect(pixels, isNotNull);
            expect(pixels!.getUint8(3), 0); // Rounded corners stay transparent.
            final center =
                ((info.image.height ~/ 2) * info.image.width +
                    info.image.width ~/ 2) *
                4;
            expect(pixels.getUint8(center + 3), greaterThan(0));
            if (scale == 3) {
              final accent = int.parse(icon.accent.substring(1), radix: 16);
              var foundAccent = false;
              for (var offset = 0; offset < pixels.lengthInBytes; offset += 4) {
                if (pixels.getUint8(offset) == (accent >> 16) &&
                    pixels.getUint8(offset + 1) == ((accent >> 8) & 255) &&
                    pixels.getUint8(offset + 2) == (accent & 255) &&
                    pixels.getUint8(offset + 3) == 255) {
                  foundAccent = true;
                  break;
                }
              }
              expect(
                foundAccent,
                isTrue,
                reason: '${icon.name} must retain its accent color',
              );
            }
          } finally {
            info.dispose();
            stream.removeListener(listener);
            await provider.evict(
              configuration: ImageConfiguration(
                size: Size.square(size),
                devicePixelRatio: scale,
              ),
            );
          }
        }
      },
    );
  }
}
