import 'dart:async';
import 'dart:math' as math;
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
    expect(icons.map((icon) => icon.accent).toSet(), hasLength(17));
    for (final plugin in plugins) {
      await Future<void>.sync(plugin.dispose);
    }
  });

  for (final icon in PluginIcon.values) {
    test(
      '${icon.name} stays transparent and vivid at every display size',
      () async {
        for (final (size, scale) in [
          (24.0, 1.0),
          (40.0, 1.0),
          (40.0, 3.0),
          (96.0, 3.0),
        ]) {
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
            final rgba = pixels!;
            final width = info.image.width;
            final height = info.image.height;
            final accent = int.parse(icon.accent.substring(1), radix: 16);
            var foundAccent = false;
            var visible = 0;
            var opaque = 0;
            var vivid = 0;
            for (var y = 0; y < height; y++) {
              for (var x = 0; x < width; x++) {
                final offset = (y * width + x) * 4;
                final alpha = rgba.getUint8(offset + 3);
                // Check every edge, not just a rounded tile's empty corners.
                if (x == 0 || y == 0 || x == width - 1 || y == height - 1) {
                  expect(
                    alpha,
                    0,
                    reason: '${icon.name} needs transparent edges',
                  );
                }
                if (alpha > 0) visible++;
                if (alpha != 255) continue;
                opaque++;
                final r = rgba.getUint8(offset);
                final g = rgba.getUint8(offset + 1);
                final b = rgba.getUint8(offset + 2);
                final max = math.max(r, math.max(g, b));
                final min = math.min(r, math.min(g, b));
                if (max >= 150 && (max - min) / max >= 0.65) vivid++;
                if (r == (accent >> 16) &&
                    g == ((accent >> 8) & 255) &&
                    b == (accent & 255)) {
                  foundAccent = true;
                }
              }
            }
            // A sparse silhouette, not a filled icon tile or an empty SVG.
            expect(visible / (width * height), inExclusiveRange(0.08, 0.6));
            expect(opaque, greaterThan(0));
            expect(vivid / opaque, greaterThan(0.9));
            expect(
              foundAccent,
              isTrue,
              reason: '${icon.name} must retain its accent color',
            );
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
