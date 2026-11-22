import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum PluginIcon {
  ruler('#00B878', '''
    <path d="M10 9h15v30h30v15H10z" fill="currentColor" stroke="none"/>
    <path d="M19 16h6m-6 10h6m-6 10h6m0 11v7m10-7v7m10-7v7"
      stroke="#005CFF" stroke-width="3"/>
  '''),
  colorPicker('#FF2D87', '''
    <path d="m34 22 8 8-23 23-10 2 2-10z"/>
    <path d="m32 21 11 11M17 44l12-12"/>
    <path d="m35 12 5-5a6 6 0 0 1 8 0l9 9a6 6 0 0 1 0 8l-5 5z"
      fill="currentColor" stroke="none"/>
    <circle cx="47" cy="47" r="6" fill="#00C8F0" stroke="none"/>
    <circle cx="33" cy="54" r="4" fill="#FFB300" stroke="none"/>
  '''),
  device('#2979FF', '''
    <rect x="17" y="6" width="30" height="52" rx="7" stroke-width="4"/>
    <path d="M27 12h10M27 51h10"/>
    <path d="M24 38v-9m8 9V23m8 15V18" stroke="#00B8D9" stroke-width="4"/>
  '''),
  network('#00B8D9', '''
    <path d="M24 32h9V16h8M33 32v16h8" stroke-width="4"/>
    <rect x="6" y="23" width="18" height="18" rx="5" fill="currentColor" stroke="none"/>
    <rect x="40" y="7" width="18" height="18" rx="5" fill="#2979FF" stroke="none"/>
    <rect x="40" y="39" width="18" height="18" rx="5" fill="#00C67A" stroke="none"/>
  '''),
  performance('#39C600', '''
    <path d="M10 46a25 25 0 1 1 44 0" stroke-width="5"/>
    <path d="M14 37h5m-1-17 4 4m10-13v6m14 3-4 4m8 13h-5"/>
    <path d="m32 39 12-13" stroke="#FF6D00" stroke-width="4"/>
    <circle cx="32" cy="39" r="5" fill="#FF6D00" stroke="none"/>
    <path d="M23 53h18" stroke-width="4"/>
  '''),
  grid('#00BFA5', '''
    <path d="M22 8v48M42 8v48M8 22h48M8 42h48" stroke-width="4"/>
    <rect x="27" y="27" width="10" height="10" rx="2" fill="currentColor" stroke="none"/>
    <circle cx="52" cy="12" r="4" fill="#2979FF" stroke="none"/>
  '''),
  license('#FFAB00', '''
    <path d="M28 55H12V7h32v17"/>
    <path d="M20 17h16M20 26h12M20 35h5"/>
    <path d="m34 45-3 13 10-5 10 5-3-13" stroke="#FF6D00"/>
    <circle cx="41" cy="37" r="11" stroke="#FF6D00" stroke-width="4"/>
    <path d="m36 37 3 3 6-6" stroke="#00B878"/>
  '''),
  logs('#9C36FF', '''
    <path d="M24 11h30M24 25h22M24 39h30M24 53h22" stroke-width="4"/>
    <circle cx="11" cy="11" r="4" fill="currentColor" stroke="none"/>
    <circle cx="11" cy="25" r="4" fill="#00B8D9" stroke="none"/>
    <circle cx="11" cy="39" r="4" fill="#FFAB00" stroke="none"/>
    <circle cx="11" cy="53" r="4" fill="#FF3D57" stroke="none"/>
  '''),
  memory('#FF5733', '''
    <path d="M22 7v10M32 7v10M42 7v10M22 47v10M32 47v10M42 47v10M7 22h10M7 32h10M7 42h10M47 22h10M47 32h10M47 42h10"/>
    <rect x="17" y="17" width="30" height="30" rx="5" stroke-width="4"/>
    <rect x="25" y="25" width="14" height="14" rx="3" fill="currentColor" stroke="none"/>
  '''),
  package('#FF9100', '''
    <path d="m32 6 24 13v26L32 58 8 45V19z"/>
    <path d="m8 19 24 13 24-13M32 32v26"/>
    <path d="m20 13 24 13v11l-8 4V30L12 17z" fill="currentColor" stroke="none"/>
    <path d="m15 40 9 5" stroke="#FF5733"/>
  '''),
  screen('#009DFF', '''
    <rect x="6" y="10" width="52" height="36" rx="5" stroke-width="4"/>
    <path d="M32 46v10m-12 0h24" stroke-width="4"/>
    <path d="M15 26v-7h9m25 11v7h-9m-23-2 29-14" stroke="#00BFA5"/>
  '''),
  preferences('#E800C6', '''
    <path d="M9 14h46M9 32h46M9 50h46" stroke-width="4"/>
    <circle cx="23" cy="14" r="7" fill="currentColor" stroke="none"/>
    <circle cx="42" cy="32" r="7" fill="#9C36FF" stroke="none"/>
    <circle cx="27" cy="50" r="7" fill="currentColor" stroke="none"/>
  '''),
  code('#7047FF', '''
    <path d="m20 17-14 15 14 15m24-30 14 15-14 15" stroke-width="5"/>
    <path d="m38 9-12 46" stroke="#00B8D9" stroke-width="5"/>
  '''),
  touch('#FF3D70', '''
    <path d="M13 26a16 16 0 1 1 30 0"/>
    <path d="M8 12 5 9m23-1V5m20 7 3-3" stroke="#FF9100"/>
    <path d="M24 38V22a4 4 0 0 1 8 0v13l4-4a4 4 0 0 1 6 0l9 9v6c0 7-5 12-12 12h-7c-4 0-7-2-9-5l-9-14a4 4 0 0 1 6-5z"/>
    <path d="M32 50h12" stroke-width="4"/>
  '''),
  visual('#FF7800', '''
    <path d="M5 33c12-21 42-21 54 0-12 21-42 21-54 0z" stroke-width="4"/>
    <circle cx="32" cy="33" r="10"/>
    <circle cx="32" cy="33" r="4" fill="currentColor" stroke="none"/>
    <path d="M49 6v10m-5-5h10" stroke="#FFAB00"/>
  '''),
  inspector('#536DFE', '''
    <path d="M25 17h13M17 25v13"/>
    <rect x="7" y="7" width="18" height="18" rx="4" fill="currentColor" stroke="none"/>
    <path d="M39 8h14v14M8 39v14h14"/>
    <circle cx="39" cy="39" r="12" stroke="#00B8D9" stroke-width="4"/>
    <path d="m48 48 9 9" stroke="#00B8D9" stroke-width="5"/>
    <rect x="35" y="35" width="8" height="8" rx="2" fill="currentColor" stroke="none"/>
  '''),
  demo('#C62BFF', '''
    <path d="m29 8 7 15 15 7-15 7-7 17-7-17-16-7 16-7z"
      fill="currentColor" stroke="none"/>
    <path d="M51 5v12m-6-6h12M49 46v10m-5-5h10" stroke="#FFAB00" stroke-width="4"/>
  ''');

  const PluginIcon(this.accent, this._paths);
  final String accent;
  final String _paths;

  String get svg =>
      '''
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <g fill="none" stroke="$accent" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round">${_paths.replaceAll('currentColor', accent)}</g>
</svg>''';
}

typedef PluginIconKey = ({PluginIcon icon, double size, double scale});

class PluginIconImage extends ImageProvider<PluginIconKey> {
  const PluginIconImage(this.icon);
  final PluginIcon icon;

  @override
  Future<PluginIconKey> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture((
        icon: icon,
        size: configuration.size?.longestSide ?? 64,
        scale: configuration.devicePixelRatio ?? 1,
      ));

  @override
  ImageStreamCompleter loadImage(
    PluginIconKey key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(_load(key));

  Future<ImageInfo> _load(PluginIconKey key) async {
    final source = await vg.loadPicture(SvgStringLoader(key.icon.svg), null);
    try {
      final pixels = (key.size * key.scale).ceil();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(pixels / 64);
      canvas.drawPicture(source.picture);
      final picture = recorder.endRecording();
      try {
        return ImageInfo(
          image: await picture.toImage(pixels, pixels),
          scale: key.scale,
        );
      } finally {
        picture.dispose();
      }
    } finally {
      source.picture.dispose();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PluginIconImage && other.icon == icon;

  @override
  int get hashCode => icon.hashCode;
}
